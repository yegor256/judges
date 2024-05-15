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

require 'nokogiri'
require 'factbase'
require 'backtrace'
require 'factbase/looged'
require_relative '../../judges'
require_relative '../../judges/to_rel'
require_relative '../../judges/packs'
require_relative '../../judges/options'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Judges::Test
  def initialize(loog)
    @loog = loog
  end

  def run(opts, args)
    raise 'Exactly one argument required' unless args.size == 1
    dir = args[0]
    @loog.info("Testing judges in #{dir.to_rel}...")
    errors = []
    done = 0
    Judges::Packs.new(dir, @loog).each_with_index do |p, i|
      next unless include?(opts, p.name)
      @loog.info("\n👉 Testing #{p.script} (##{i}) in #{p.dir.to_rel}...")
      p.tests.each do |f|
        yaml = YAML.load_file(f, permitted_classes: [Time])
        @loog.info("Testing #{f.to_rel}:")
        begin
          test_one(p, yaml)
        rescue StandardError => e
          @loog.warn(Backtrace.new(e))
          errors << f
        end
      end
      done += 1
    end
    raise 'No judges tested :(' if done.zero? && !opts['quiet']
    if errors.empty?
      @loog.info("\nAll #{done} judges tested successfully")
    else
      @loog.info("\n#{done} judges tested, #{errors.size} of them failed")
      raise "#{errors.size} tests failed" unless errors.empty?
    end
  end

  private

  def include?(opts, name)
    packs = opts['pack'] || []
    return true if packs.empty?
    packs.include?(name)
  end

  def test_one(pack, yaml)
    fb = Factbase.new
    yaml['input'].each do |i|
      f = fb.insert
      i.each do |k, vv|
        if vv.is_a?(Array)
          vv.each do |v|
            f.send("#{k}=", v)
          end
        else
          f.send("#{k}=", vv)
        end
      end
    end
    pack.run(Factbase::Looged.new(fb, @loog), Judges::Options.new(yaml['options']))
    xml = Nokogiri::XML.parse(fb.to_xml)
    yaml['expected'].each do |xp|
      raise "#{pack.script} doesn't match '#{xp}':\n#{xml}" if xml.xpath(xp).empty?
    end
  end
end
