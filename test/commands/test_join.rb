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

require 'minitest/autorun'
require 'loog'
require 'nokogiri'
require 'factbase/to_xml'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/join'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestJoin < Minitest::Test
  def test_simple_join
    Dir.mktmpdir do |d|
      master = File.join(d, 'master.fb')
      fb1 = Factbase.new
      fb1.insert.zz = 5
      File.binwrite(master, fb1.export)
      slave = File.join(d, 'slave.fb')
      fb2 = Factbase.new
      fb2.insert.foo_bar = 42
      File.binwrite(slave, fb2.export)
      Judges::Join.new(Loog::NULL).run({}, [master, slave])
      fb = Factbase.new
      fb.import(File.binread(master))
      xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
      assert(!xml.xpath('/fb/f[zz="5"]').empty?, xml)
      assert(!xml.xpath('/fb/f[foo_bar="42"]').empty?, xml)
    end
  end
end
