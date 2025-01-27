# frozen_string_literal: true

# Copyright (c) 2024-2025 Yegor Bugayenko
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
require 'factbase'
require 'nokogiri'
require 'yaml'
require 'fileutils'
require 'securerandom'
require 'w3c_validators'
require 'webmock/minitest'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/print'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestPrint < Minitest::Test
  def test_simple_print
    Dir.mktmpdir do |d|
      f = File.join(d, 'base.fb')
      fb = Factbase.new
      fb.insert
      File.binwrite(f, fb.export)
      Judges::Print.new(Loog::NULL).run({ 'format' => 'yaml', 'auto' => true }, [f])
      y = File.join(d, 'base.yaml')
      assert_path_exists(y)
      assert_equal(1, YAML.load_file(y).size)
    end
  end

  def test_print_to_html
    fb = Factbase.new
    10.times do
      f = fb.insert
      f._id = 44
      f.what = SecureRandom.hex(10)
      f.when = Time.now
      f.details = 'hey, друг'
      f.ticket = 42
      f.ticket = 55
      f.pi = 3.1416
      f.long_property = 'test_' * 100
    end
    html = File.join(__dir__, '../../temp/base.html')
    FileUtils.rm_f(html)
    Dir.mktmpdir do |d|
      f = File.join(d, 'base.fb')
      File.binwrite(f, fb.export)
      Judges::Print.new(Loog::NULL).run(
        { 'format' => 'html', 'columns' => 'what,when,ticket' },
        [f, html]
      )
    end
    doc = File.read(html)
    xml =
      begin
        Nokogiri::XML.parse(doc) do |c|
          c.norecover
          c.strict
        end
      rescue StandardError => e
        raise "#{doc}\n\n#{e}"
      end
    assert_empty(xml.errors, xml)
    refute_empty(xml.xpath('/html'), xml)
    WebMock.enable_net_connect!
    v = W3CValidators::NuValidator.new.validate_file(html)
    assert_empty(v.errors, "#{doc}\n\n#{v.errors.join('; ')}")
  end

  def test_print_all_formats
    %w[yaml html xml json].each do |fmt|
      Dir.mktmpdir do |d|
        f = File.join(d, 'base.fb')
        fb = Factbase.new
        fb.insert
        File.binwrite(f, fb.export)
        Judges::Print.new(Loog::NULL).run({ 'format' => fmt, 'auto' => true }, [f])
        y = File.join(d, "base.#{fmt}")
        assert_path_exists(y)
      end
    end
  end

  def test_print_twice
    Dir.mktmpdir do |d|
      f = File.join(d, 'base.fb')
      fb = Factbase.new
      fb.insert
      File.binwrite(f, fb.export)
      Judges::Print.new(Loog::NULL).run({ 'format' => 'yaml', 'auto' => true }, [f])
      y = File.join(d, 'base.yaml')
      assert_path_exists(y)
      mtime = File.mtime(y)
      Judges::Print.new(Loog::NULL).run({ 'format' => 'yaml', 'auto' => true }, [f])
      assert_equal(mtime, File.mtime(y))
    end
  end
end
