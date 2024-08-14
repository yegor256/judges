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
require_relative '../test__helper'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/test'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestTest < Minitest::Test
  def test_positive
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), '$fb.query("(eq foo 42)").each { |f| f.bar = 4 }')
      save_it(
        File.join(d, 'foo/something.yml'),
        <<-YAML
        input:
          -
            foo: 42
        expected:
          - /fb[count(f)=1]
          - /fb/f[foo='42']
          - /fb/f[bar='4']
        YAML
      )
      Judges::Test.new(Loog::NULL).run({}, [d])
    end
  end

  def test_negative
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), '$fb.query("(eq foo 42)").each { |f| f.bar = 4 }')
      save_it(
        File.join(d, 'foo/something.yml'),
        <<-YAML
        input:
          -
            foo: 42
        expected:
          - /fb[count(f)=1]
          - /fb/f[foo/v='42']
          - /fb/f[bar/v='5']
        YAML
      )
      assert_raises do
        Judges::Test.new(Loog::NULL).run({}, [d])
      end
    end
  end

  def test_with_options
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), '$fb.insert.foo = $options.bar')
      save_it(
        File.join(d, 'foo/something.yml'),
        <<-YAML
        input: []
        options:
          bar: 42
        expected:
          - /fb[count(f)=1]
          - /fb/f[foo='42']
        YAML
      )
      Judges::Test.new(Loog::NULL).run({}, [d])
    end
  end

  def test_with_before
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'first/first.rb'), 'x = $fb.size; $fb.insert.foo = x')
      save_it(File.join(d, 'second/second.rb'), '$fb.insert.bar = 55')
      save_it(
        File.join(d, 'second/something.yml'),
        <<-YAML
        input:
          -
            hi: 42
        before:
          - first
        expected:
          - /fb[count(f)=3]
          - /fb/f[hi=42]
          - /fb/f[foo=1]
          - /fb/f[bar=55]
        YAML
      )
      Judges::Test.new(Loog::NULL).run({}, [d])
    end
  end

  def test_one_judge_negative
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), '')
      save_it(
        File.join(d, 'foo/x.yml'),
        <<-YAML
        input: []
        expected:
          - /fb[count(f)=1]
        YAML
      )
      assert_raises do
        Judges::Test.new(Loog::NULL).run({ 'judge' => [File.basename(dir)] }, [d])
      end
    end
  end

  def test_with_after_assertion
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), '$fb.insert.foo = 42;')
      save_it(File.join(d, 'foo/assert.rb'), 'raise unless $fb.size == 1')
      save_it(
        File.join(d, 'foo/x.yml'),
        <<-YAML
        input: []
        after:
          - assert.rb
        YAML
      )
      Judges::Test.new(Loog::NULL).run({}, [d])
    end
  end

  def test_with_expected_failure
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), 'raise "this is intentional";')
      save_it(
        File.join(d, 'foo/x.yml'),
        <<-YAML
        input: []
        expected_failure:
          - intentional
        YAML
      )
      Judges::Test.new(Loog::NULL).run({}, [d])
    end
  end

  def test_with_expected_failure_no_string
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), 'raise "this is intentional";')
      save_it(
        File.join(d, 'foo/x.yml'),
        <<-YAML
        input: []
        expected_failure: true
        YAML
      )
      Judges::Test.new(Loog::NULL).run({}, [d])
    end
  end
end
