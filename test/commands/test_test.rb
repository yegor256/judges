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
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/test'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestTest < Minitest::Test
  def test_positive
    Dir.mktmpdir do |d|
      File.write(File.join(d, 'foo.rb'), '$fb.query("(eq foo 42)").each { |f| f.bar = 4 }')
      File.write(
        File.join(d, 'something.yml'),
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
      File.write(File.join(d, 'foo.rb'), '$fb.query("(eq foo 42)").each { |f| f.bar = 4 }')
      File.write(
        File.join(d, 'something.yml'),
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
      File.write(File.join(d, 'foo.rb'), '$fb.insert.foo = $options.bar')
      File.write(
        File.join(d, 'something.yml'),
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
      home = File.join(d, 'judges')
      FileUtils.mkdir_p(File.join(home, 'first'))
      File.write(File.join(d, 'judges/first/the-first.rb'), '$fb.insert.foo = 42')
      FileUtils.mkdir_p(File.join(home, 'second'))
      File.write(File.join(d, 'judges/second/the-second.rb'), '$fb.insert.foo = 55')
      File.write(
        File.join(d, 'judges/first/something.yml'),
        <<-YAML
        input: []
        expected:
          - /fb[count(f)=1]
        YAML
      )
      File.write(
        File.join(d, 'judges/second/something.yml'),
        <<-YAML
        input: []
        before:
          - first
        expected:
          - /fb[count(f)=2]
        YAML
      )
      Judges::Test.new(Loog::NULL).run({}, [home])
    end
  end

  def test_one_judge_negative
    Dir.mktmpdir do |d|
      File.write(File.join(d, 'foo.rb'), '')
      File.write(
        File.join(d, 'x.yml'),
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
end
