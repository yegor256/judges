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

require 'backtrace'
require 'factbase/looged'
require_relative '../../judges'
require_relative '../../judges/to_rel'
require_relative '../../judges/packs'
require_relative '../../judges/options'
require_relative '../../judges/impex'
require_relative '../../judges/elapsed'

# Update.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Judges::Update
  def initialize(loog)
    @loog = loog
  end

  def run(opts, args)
    raise 'Exactly two arguments required' unless args.size == 2
    dir = args[0]
    raise "The directory is absent: #{dir.to_rel}" unless File.exist?(dir)
    impex = Judges::Impex.new(@loog, args[1])
    fb = impex.import(strict: false)
    fb = Factbase::Looged.new(fb, @loog)
    options = Judges::Options.new(opts['option'])
    @loog.debug("The following options provided:\n\t#{options.to_s.gsub("\n", "\n\t")}")
    packs = Judges::Packs.new(dir, opts['lib'], @loog)
    c = 0
    elapsed(@loog) do
      loop do
        c += 1
        if c > 1
          @loog.info("\n\nStarting cycle ##{c}#{opts['max-cycles'] ? " (out of #{opts['max-cycles']})" : ''}...")
        end
        diff = cycle(opts, packs, fb, options)
        impex.export(fb)
        if diff.zero?
          @loog.info("The update cycle ##{c} has made no changes to the factbase, let's stop")
          break
        end
        if !opts['max-cycles'].nil? && c >= opts['max-cycles']
          @loog.info("Too many cycles already, as set by --max-cycles=#{opts['max-cycles']}, breaking")
          break
        end
        @loog.info(
          "By #{diff} facts the factbase " \
          "#{diff.positive? ? 'increased' : 'decreased'} " \
          "its size at the cycle ##{c}"
        )
      end
      throw :"Update finished: #{c} cycles"
    end
  end

  private

  def cycle(opts, packs, fb, options)
    errors = []
    diff = 0
    global = {}
    elapsed(@loog) do
      done = packs.each_with_index do |p, i|
        local = {}
        @loog.info("👉 Running #{p.name} (##{i}) at #{p.dir.to_rel}...")
        before = fb.size
        begin
          p.run(fb, global, local, options)
        rescue StandardError, SyntaxError => e
          @loog.warn(Backtrace.new(e))
          errors << p.script
        end
        after = fb.size
        @loog.info("👍 The judge #{p.dir.to_rel} added #{after - before} facts") if after > before
        diff += after - before
      end
      throw :"👍 #{done} judge(s) processed" if errors.empty?
      throw :"❌ #{done} judge(s) processed with #{errors.size} errors"
    end
    unless errors.empty?
      raise "Failed to update correctly (#{errors.size} errors)" unless opts['quiet']
      @loog.info('Not failing because of the --quiet flag provided')
    end
    diff
  end
end
