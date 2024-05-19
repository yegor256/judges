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
require_relative '../../lib/judges/commands/update'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestUpdate < Minitest::Test
  def test_build_factbase_from_scratch
    Dir.mktmpdir do |d|
      File.write(File.join(d, 'foo.rb'), 'return if $fb.size > 2; $fb.insert.zzz = $options.foo_bar + 1')
      file = File.join(d, 'base.fb')
      Judges::Update.new(Loog::NULL).run({ 'option' => ['foo_bar=42'] }, [d, file])
      fb = Factbase.new
      fb.import(File.binread(file))
      xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
      assert(!xml.xpath('/fb/f[zzz="43"]').empty?, xml)
    end
  end

  def test_extend_existing_factbase
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      fb = Factbase.new
      fb.insert.foo_bar = 42
      File.binwrite(file, fb.export)
      File.write(File.join(d, 'foo.rb'), '$fb.insert.tt = 4')
      Judges::Update.new(Loog::NULL).run({ 'max-cycles' => 1 }, [d, file])
      fb = Factbase.new
      fb.import(File.binread(file))
      xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
      assert(!xml.xpath('/fb/f[tt="4"]').empty?, xml)
      assert(!xml.xpath('/fb/f[foo_bar="42"]').empty?, xml)
    end
  end

  def test_update_with_error
    Dir.mktmpdir do |d|
      File.write(File.join(d, 'foo.rb'), 'this is a broken Ruby script')
      file = File.join(d, 'base.fb')
      Judges::Update.new(Loog::NULL).run({ 'quiet' => true }, [d, file])
    end
  end
end
