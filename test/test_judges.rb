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
require 'tmpdir'
require 'loog'
require_relative '../lib/judges'
require_relative '../lib/judges/judges'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestJudges < Minitest::Test
  def test_basic
    Dir.mktmpdir do |d|
      dir = File.join(d, 'foo')
      save_it(File.join(dir, 'foo.rb'), 'hey')
      save_it(File.join(dir, 'something.yml'), "---\nfoo: 42")
      found = 0
      Judges::Judges.new(d, nil, Loog::NULL).each do |p|
        assert_equal('foo.rb', p.script)
        found += 1
        assert_equal('something.yml', File.basename(p.tests.first))
      end
      assert_equal(1, found)
    end
  end

  def test_get_one
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'boo/boo.rb'), 'hey')
      j = Judges::Judges.new(d, nil, Loog::NULL).get('boo')
      assert_equal('boo.rb', j.script)
    end
  end

  def test_list_only_direct_subdirs
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'first/first.rb'), '')
      save_it(File.join(d, 'second/second.rb'), '')
      save_it(File.join(d, 'second/just-file.rb'), '')
      save_it(File.join(d, 'wrong.rb'), '')
      save_it(File.join(d, 'another/wrong/wrong.rb'), '')
      save_it(File.join(d, 'bad/hello.rb'), '')
      list = Judges::Judges.new(d, nil, Loog::NULL).each.to_a
      assert_equal(2, list.size)
    end
  end

  def test_list_with_empty_dir
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'wrong.rb'), '')
      save_it(File.join(d, 'another/wrong/wrong.rb'), '')
      save_it(File.join(d, 'bad/hello.rb'), '')
      list = Judges::Judges.new(d, nil, Loog::NULL).each.to_a
      assert_empty(list)
    end
  end
end
