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
require 'factbase/to_xml'
require_relative '../../judges'
require_relative '../../judges/to_rel'
require_relative '../../judges/judges'
require_relative '../../judges/options'
require_relative '../../judges/categories'
require_relative '../../judges/elapsed'

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
    judges = 0
    tests = 0
    visible = []
    elapsed(@loog) do
      Judges::Judges.new(dir, opts['lib'], @loog).each_with_index do |p, i|
        visible << p.name
        next unless include?(opts, p.name)
        @loog.info("\n👉 Testing #{p.script} (##{i}) in #{p.dir.to_rel}...")
        p.tests.each do |f|
          tname = File.basename(f).gsub(/\.yml$/, '')
          visible << "  #{p.name}/#{tname}"
          next unless include?(opts, p.name, tname)
          yaml = YAML.load_file(f, permitted_classes: [Time])
          if yaml['skip']
            @loog.info("Skippped #{f.to_rel}")
            next
          end
          unless Judges::Categories.new(opts['enable'], opts['disable']).ok?(yaml['category'])
            @loog.info("Skippped #{f.to_rel} because of its category")
            next
          end
          @loog.info("🛠️ Testing #{f.to_rel}:")
          begin
            test_one(opts, p, tname, yaml)
            tests += 1
          rescue StandardError => e
            @loog.warn(Backtrace.new(e))
            errors << f
          end
        end
        judges += 1
      end
      throw :'👍 No judges tested' if judges.zero?
      throw :"👍 All #{judges} judge(s) but no tests passed" if tests.zero?
      throw :"👍 All #{judges} judge(s) and #{tests} tests passed" if errors.empty?
      throw :"❌ #{judges} judge(s) tested, #{errors.size} of them failed"
    end
    unless errors.empty?
      raise "#{errors.size} tests failed" unless opts['quiet']
      @loog.debug('Not failing the build with tests failures, due to the --quiet option')
    end
    return unless judges.zero? || tests.zero?
    if opts['judge'].nil?
      raise 'There are seems to be no judges' unless opts['quiet']
      @loog.debug('Not failing the build with no judges tested, due to the --quiet option')
    else
      raise 'There are seems to be no judges' if visible.empty?
      @loog.info("The following judges are available to use with the --judge option:\n  #{visible.join("\n  ")}")
    end
  end

  private

  def include?(opts, name, tname = nil)
    judges = opts['judge'] || []
    return true if judges.empty?
    tre = tname.nil? ? '.+' : tname
    judges.any? { |n| n.match?(%r{^#{name}(/#{tre})?$}) }
  end

  def test_one(opts, judge, tname, yaml)
    fb = Factbase.new
    inputs = yaml['input']
    inputs&.each do |i|
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
    options = Judges::Options.new(opts['option']) + Judges::Options.new(yaml['options'])
    (1..(opts['runs'] || yaml['runs'] || 1)).each do
      judge.run(Factbase::Looged.new(fb, @loog), {}, {}, options)
    end
    xpaths = yaml['expected']
    return if xpaths.nil?
    xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
    xpaths.each do |xp|
      raise "#{judge.name}/#{tname} doesn't match '#{xp}':\n#{xml}" if xml.xpath(xp).empty?
    end
  end
end
