# frozen_string_literal: true

# Copyright (c) 2024 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'typhoeus'
require 'iri'
require_relative '../../judges'
require_relative '../../judges/impex'
require_relative '../../judges/baza'

# The +pull+ command.
#
# This class is instantiated by the +bin/judge+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Judges::Pull
  def initialize(loog)
    @loog = loog
  end

  def run(opts, args)
    raise 'Exactly two arguments required' unless args.size == 2
    fb = Factbase.new
    baza = Judges::Baza.new(
      opts['host'], opts['port'].to_i, opts['token'],
      ssl: opts['ssl'],
      timeout: (opts['timeout'] || 30).to_i,
      loog: @loog,
      retries: (opts['retries'] || 3).to_i
    )
    name = args[0]
    elapsed(@loog) do
      baza.lock(name, opts['owner'])
      if baza.name_exists?(name)
        jid = baza.recent(name)
        unless baza.exit_code(jid).zero?
          @loog.warn("STDOUT of the job ##{jid} (from the server):\n#{baza.stdout(jid)}")
          raise "The job ##{jid} ('#{name}') is broken, maybe you should expire it"
        end
        fb.import(baza.pull(wait(name, baza, jid, opts['wait'])))
        Judges::Impex.new(@loog, args[1]).export(fb)
        throw :"Pulled #{fb.size} facts by the name '#{name}'"
      else
        throw :"There is nothing to pull, the name '#{name}' is absent on the server"
      end
    end
  end

  private

  def wait(name, baza, id, limit)
    raise 'Waiting time is nil' if limit.nil?
    start = Time.now
    loop do
      break if baza.finished?(id)
      sleep 1
      raise "Time is over, the job ##{id} ('#{name}') is still not finished" if Time.now - start > limit
      lapsed = Time.now - start
      @loog.debug("Still waiting for the job ##{id} ('#{name}') to finish... (#{format('%.2f', lapsed)}s already)")
    end
    id
  end
end
