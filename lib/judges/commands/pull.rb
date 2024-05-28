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
require_relative '../../judges/http_body'

# Pull.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Judges::Pull
  def initialize(loog)
    @loog = loog
  end

  def run(opts, args)
    raise 'Exactly two arguments required' unless args.size == 2
    home = Iri.new('')
        .host(opts['host'])
        .port(opts['port'].to_i)
        .scheme(opts['ssl'] ? 'https' : 'http')
    name = args[0]
    fb = Factbase.new
    Tempfile.open do |file|
      File.open(file, 'wb') do |f|
        request = Typhoeus::Request.new(
          home.append('pull').append("#{recent(home, name)}.fb").to_s,
          connecttimeout: (opts['timeout'] || 5).to_i,
          timeout: (opts['timeout'] || 5).to_i
        )
        request.on_body do |chunk|
          f.write(chunk)
        end
        request.run
        Judges::HttpBody.new(request.response).body
      end
      fb.import(File.binread(file))
    end
    Judges::Impex.new(@loog, args[1]).export(fb)
    @loog.info("Pulled #{fb.size} facts")
  end

  private

  def recent(home, name)
    ret = Typhoeus::Request.get(
      home.append('recent').append("#{name}.txt").to_s,
    )
    job = Judges::HttpBody.new(ret).body.to_i
    @loog.info("The latest job \"#{name}\" ID is ##{job}")
    job
  end
end
