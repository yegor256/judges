#!/usr/bin/env ruby
# frozen_string_literal: true

# Copyright (c) 2014-2024 Yegor Bugayenko
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

require 'factbase'
require 'nokogiri'
require_relative '../judges'
require_relative '../judges/packs'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Judges::Test
  def initialize(loog)
    @loog = loog
  end

  def run(_opts, args)
    raise 'Exactly one argument required' unless args.size == 1
    dir = args[0]
    done = Judges::Packs.new(dir).each_with_index do |p, i|
      p.tests.each do |t|
        test_one(p, t)
      end
      @loog.info("Pack ##{i} found in #{p.dir}")
    end
    @loog.info("#{done} judges tested")
  end

  private

  def test_one(pack, yaml)
    fb = Factbase.new
    yaml['input'].each do |i|
      f = fb.insert
      i.each do |k, vv|
        if vv.is_a?(Array)
          vv.each do |v|
            send(f, "#{k}=", v)
          end
        else
          f.send('foo=', 42)
        end
      end
    end
    pack.run(fb, {})
    xml = Nokogiri::XML.parse(fb.to_xml)
    yaml['expected'].each do |xp|
      raise "#{pack.script} with '#{xp}' doesn't match:\n#{xml}" if xml.xpath(xp).empty?
    end
  end
end
