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
require_relative '../../judges'
require_relative '../../judges/to_rel'
require_relative '../../judges/packs'
require_relative '../../judges/options'
require_relative '../../judges/impex'

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
    options = Judges::Options.new(opts['option'])
    @loog.debug("The following options provided:\n\t#{options.to_s.gsub("\n", "\n\t")}")
    packs = Judges::Packs.new(dir, @loog)
    c = 0
    loop do
      c += 1
      diff = cycle(packs, fb, impex, options)
      break if diff.zero?
      if !opts['max-cycles'].nil? && c >= opts['max-cycles']
        @loog.info('Too many cycles already, as set by --max-cycles, breaking')
        break
      end
      @loog.info("#{diff} modifications at the cycle ##{c}")
    end
    @loog.info("Update finished in #{c} cycles")
  end

  private

  def cycle(packs, fb, impex, options)
    errors = []
    diff = 0
    done = packs.each_with_index do |p, i|
      @loog.info("👍 Running #{p.name} (##{i}) at #{p.dir.to_rel}...")
      before = fb.size
      begin
        p.run(fb, options)
      rescue StandardError => e
        @loog.warn(Backtrace.new(e))
        errors << p.script
      end
      after = fb.size
      @loog.info("Pack #{p.dir.to_rel} added #{after - before} facts") if after > before
      diff += after - before
    end
    @loog.info("#{done} judges processed (#{errors.size} errors)")
    raise "Failed to update correctly (#{errors.size} errors)" unless errors.empty?
    impex.export(fb)
    diff
  end
end
