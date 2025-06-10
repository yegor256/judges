# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/test'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
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
      assert_path_exists(d)
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
      assert_raises(StandardError) do
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
      assert_path_exists(d)
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
      assert_path_exists(d)
    end
  end

  def test_one_judge_negative
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), '# empty judge')
      save_it(
        File.join(d, 'foo/x.yml'),
        <<-YAML
        input: []
        expected:
          - /fb[count(f)=1]
        YAML
      )
      assert_raises(StandardError) do
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
      assert_path_exists(d)
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
      assert_path_exists(d)
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
      assert_path_exists(d)
    end
  end

  def test_validates_directory_layout_correct
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'judge-one/judge-one.rb'), '$fb.insert.foo = 42')
      save_it(File.join(d, 'judge-two/judge-two.rb'), '$fb.insert.bar = 24')
      save_it(File.join(d, 'judge-one/test.yml'), "input: []\nexpected:\n  - /fb[count(f)=1]")

      # This should not raise an error
      Judges::Test.new(Loog::NULL).run({}, [d])
      assert_path_exists(d)
    end
  end

  def test_validates_directory_layout_file_in_root
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'judge-one/judge-one.rb'), '$fb.insert.foo = 42')
      save_it(File.join(d, 'wrong-file.rb'), 'some content')
      save_it(File.join(d, 'judge-one/test.yml'), "input: []\nexpected:\n  - /fb[count(f)=1]")

      error =
        assert_raises(StandardError) do
          Judges::Test.new(Loog::NULL).run({}, [d])
        end
      assert_includes(error.message, "File 'wrong-file.rb' should be inside a judge directory")
    end
  end

  def test_validates_directory_layout_missing_script
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'judge-one/wrong-name.rb'), '$fb.insert.foo = 42')
      save_it(File.join(d, 'judge-one/test.yml'), "input: []\nexpected:\n  - /fb[count(f)=1]")

      error =
        assert_raises(StandardError) do
          Judges::Test.new(Loog::NULL).run({}, [d])
        end
      assert_includes(error.message, "Judge directory 'judge-one' must contain a file named 'judge-one.rb'")
    end
  end

  def test_validates_directory_layout_nested_directories
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'parent/parent.rb'), '$fb.insert.foo = 42')
      save_it(File.join(d, 'parent/nested/nested.rb'), '$fb.insert.bar = 24')
      save_it(File.join(d, 'parent/test.yml'), "input: []\nexpected:\n  - /fb[count(f)=1]")

      error =
        assert_raises(StandardError) do
          Judges::Test.new(Loog::NULL).run({}, [d])
        end
      assert_includes(error.message, "Nested judge directory 'parent/nested' is not allowed")
    end
  end

  def test_validates_directory_layout_allows_config_files
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'judge-one/judge-one.rb'), '$fb.insert.foo = 42')
      save_it(File.join(d, '.gitignore'), '*.tmp')
      save_it(File.join(d, 'README.md'), '# Judges')
      save_it(File.join(d, 'judge-one/test.yml'), "input: []\nexpected:\n  - /fb[count(f)=1]")

      # This should not raise an error
      Judges::Test.new(Loog::NULL).run({}, [d])
      assert_path_exists(d)
    end
  end
end
