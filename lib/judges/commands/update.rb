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
require_relative '../../judges/judges'
require_relative '../../judges/churn'
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
    fb = Factbase::Looged.new(fb, @loog) if opts['log']
    options = Judges::Options.new(opts['option'])
    @loog.debug("The following options provided:\n\t#{options.to_s.gsub("\n", "\n\t")}")
    judges = Judges::Judges.new(dir, opts['lib'], @loog)
    c = 0
    churn = Judges::Churn.new(0, 0)
    elapsed(@loog) do
      loop do
        c += 1
        if c > 1
          @loog.info("\n\nStarting cycle ##{c}#{opts['max-cycles'] ? " (out of #{opts['max-cycles']})" : ''}...")
        end
        delta = cycle(opts, judges, fb, options)
        churn += delta
        impex.export(fb)
        if delta.zero?
          @loog.info("The update cycle ##{c} has made no changes to the factbase, let's stop")
          break
        end
        if !opts['max-cycles'].nil? && c >= opts['max-cycles']
          @loog.info("Too many cycles already, as set by --max-cycles=#{opts['max-cycles']}, breaking")
          break
        end
        @loog.info("The cycle #{c} modified #{delta} fact(s)")
      end
      throw :"Update finished in #{c} cycle(s), modified #{churn} fact(s)"
    end
  end

  private

  # Run all judges in a full cycle, one by one.
  # @return [Churn] How many modifications have been made
  def cycle(opts, judges, fb, options)
    errors = []
    churn = Judges::Churn.new(0, 0)
    global = {}
    elapsed(@loog) do
      done = judges.each_with_index do |p, i|
        @loog.info("\n👉 Running #{p.name} (##{i}) at #{p.dir.to_rel}...")
        elapsed(@loog) do
          c = one_judge(fb, p, global, options)
          churn += c
          throw :"👍 The judge #{p.name} modified #{c.zero? ? 'no' : c} facts"
        end
      rescue StandardError, SyntaxError => e
        @loog.warn(Backtrace.new(e))
        errors << p.script
      end
      throw :"👍 #{done} judge(s) processed" if errors.empty?
      throw :"❌ #{done} judge(s) processed with #{errors.size} errors"
    end
    unless errors.empty?
      raise "Failed to update correctly (#{errors.size} errors)" unless opts['quiet']
      @loog.info('Not failing because of the --quiet flag provided')
    end
    churn
  end

  # Run a single judge.
  # @return [Churn] How many modifications have been made
  def one_judge(fb, judge, global, options)
    local = {}
    before = fb.size
    judge.run(fb, global, local, options)
    after = fb.size
    diff = after - before
    if diff.positive?
      Judges::Churn.new(diff, 0)
    else
      Judges::Churn.new(0, -diff)
    end
  end
end
