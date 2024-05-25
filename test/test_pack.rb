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
require 'tmpdir'
require 'loog'
require 'factbase'
require_relative '../lib/judges'
require_relative '../lib/judges/pack'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestPack < Minitest::Test
  def test_basic_run
    Dir.mktmpdir do |d|
      File.write(File.join(d, 'foo.rb'), '$fb.insert')
      pack = Judges::Pack.new(d, nil, Loog::NULL)
      fb = Factbase.new
      pack.run(fb, {}, {}, {})
      assert_equal(1, fb.size)
    end
  end

  def test_run_isolated
    Dir.mktmpdir do |d|
      File.write(File.join(d, 'bar.rb'), '$fb.insert')
      pack = Judges::Pack.new(d, nil, Loog::NULL)
      fb1 = Factbase.new
      pack.run(fb1, {}, {}, {})
      assert_equal(1, fb1.size)
      fb2 = Factbase.new
      pack.run(fb2, {}, {}, {})
      assert_equal(1, fb2.size)
    end
  end

  def test_with_supplemenary_functions
    Dir.mktmpdir do |d|
      File.write(File.join(d, 'x.rb'), 'once($fb).insert')
      pack = Judges::Pack.new(d, nil, Loog::NULL)
      pack.run(Factbase.new, {}, {}, {})
    end
  end

  def test_passes_local_vars_between_tests
    Dir.mktmpdir do |d|
      File.write(
        File.join(d, 'x.rb'),
        '
        $local[:foo] = 42 if $local[:foo].nil?
        $local[:foo] = $local[:foo] + 1
        '
      )
      pack = Judges::Pack.new(d, nil, Loog::NULL)
      local = {}
      pack.run(Factbase.new, {}, local, {})
      pack.run(Factbase.new, {}, local, {})
      pack.run(Factbase.new, {}, local, {})
      assert_equal(45, local[:foo])
    end
  end

  def test_sets_judge_value_correctly
    Dir.mktmpdir do |d|
      j = 'this_is_it'
      dir = File.join(d, j)
      FileUtils.mkdir(dir)
      File.write(File.join(dir, 'foo.rb'), '$loog.info("judge=" + $judge)')
      log = Loog::Buffer.new
      Judges::Pack.new(dir, nil, log).run(Factbase.new, {}, {}, {})
      assert(log.to_s.include?("judge=#{j}"))
    end
  end

  def test_with_library
    Dir.mktmpdir do |d|
      dir = File.join(d, 'packs')
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, 'x.rb'), 'once($fb).insert.bar = $foo')
      lib = File.join(d, 'lib')
      FileUtils.mkdir_p(lib)
      File.write(File.join(lib, 'y.rb'), '$foo = 42')
      pack = Judges::Pack.new(dir, lib, Loog::NULL)
      fb = Factbase.new
      pack.run(fb, {}, {}, {})
      assert_equal(42, fb.query('(always)').each.to_a.first.bar)
    end
  end

  def test_with_broken_ruby_syntax
    assert_raises do
      Dir.mktmpdir do |d|
        dir = File.join(d, 'packs')
        FileUtils.mkdir_p(dir)
        File.write(File.join(dir, 'x.rb'), 'this$is$broken$syntax')
        pack = Judges::Pack.new(dir, lib, Loog::NULL)
        pack.run(Factbase.new, {}, {}, {})
      end
    end
  end

  def test_with_runtime_ruby_error
    assert_raises do
      Dir.mktmpdir do |d|
        dir = File.join(d, 'packs')
        FileUtils.mkdir_p(dir)
        File.write(File.join(dir, 'x.rb'), 'a < 1')
        pack = Judges::Pack.new(dir, lib, Loog::NULL)
        pack.run(Factbase.new, {}, {}, {})
      end
    end
  end
end
