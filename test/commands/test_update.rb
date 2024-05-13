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
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/update'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestUpdate < Minitest::Test
  def test_simple_update
    Dir.mktmpdir do |d|
      File.write(File.join(d, 'foo.rb'), '$fb.insert.zzz = $options.foo_bar + 1')
      file = File.join(d, 'base.fb')
      Judges::Update.new(Loog::VERBOSE).run({ 'options' => ['foo_bar=42'] }, [d, file])
      fb = Factbase.new
      fb.import(File.read(file))
      xml = Nokogiri::XML.parse(fb.to_xml)
      assert(!xml.xpath('/fb/f[zzz="43"]').empty?)
    end
  end
end
