# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'factbase'
require 'loog'
require 'tmpdir'
require_relative '../lib/judges'
require_relative '../lib/judges/judge'
require_relative 'test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestJudge < Minitest::Test
  def test_basic_run
    Dir.mktmpdir do |d|
      save_it(File.join(d, "#{File.basename(d)}.rb"), '$fb.insert')
      fb = Factbase.new
      Judges::Judge.new(d, nil, Loog::NULL).run(fb, {}, {}, {})
      assert_equal(1, fb.size)
    end
  end

  def test_run_isolated
    Dir.mktmpdir do |d|
      save_it(File.join(d, "#{File.basename(d)}.rb"), '$fb.insert')
      judge = Judges::Judge.new(d, nil, Loog::NULL)
      one = Factbase.new
      judge.run(one, {}, {}, {})
      assert_equal(1, one.size)
      two = Factbase.new
      judge.run(two, {}, {}, {})
      assert_equal(1, two.size)
    end
  end

  def test_passes_local_vars_between_tests
    Dir.mktmpdir do |d|
      save_it(
        File.join(d, "#{File.basename(d)}.rb"),
        '
        $local[:foo] = 42 if $local[:foo].nil?
        $local[:foo] = $local[:foo] + 1
        '
      )
      judge = Judges::Judge.new(d, nil, Loog::NULL)
      local = {}
      judge.run(Factbase.new, {}, local, {})
      judge.run(Factbase.new, {}, local, {})
      judge.run(Factbase.new, {}, local, {})
      assert_equal(45, local[:foo])
    end
  end

  def test_sets_judge_value_correctly
    Dir.mktmpdir do |d|
      j = 'this_is_it'
      dir = File.join(d, j)
      save_it(File.join(dir, "#{j}.rb"), '$loog.info("judge=" + $judge)')
      log = Loog::Buffer.new
      Judges::Judge.new(dir, nil, log).run(Factbase.new, {}, {}, {})
      assert_includes(log.to_s, "judge=#{j}")
    end
  end

  def test_sets_start_value_correctly
    Dir.mktmpdir do |d|
      j = 'this_is_it'
      dir = File.join(d, j)
      save_it(File.join(dir, "#{j}.rb"), "$loog.info(\"epoch=\#{$epoch}\")")
      log = Loog::Buffer.new
      time = Time.now
      Judges::Judge.new(dir, nil, log, epoch: time).run(Factbase.new, {}, {}, {})
      assert_includes(log.to_s, "epoch=#{time}")
    end
  end

  def test_with_broken_ruby_syntax
    assert_raises(StandardError) do
      Dir.mktmpdir do |d|
        dir = File.join(d, 'judges')
        save_it(File.join(dir, "#{File.basename(d)}.rb"), 'this$is$broken$syntax')
        Judges::Judge.new(dir, lib, Loog::NULL).run(Factbase.new, {}, {}, {})
      end
    end
  end

  def test_with_runtime_ruby_error
    assert_raises(StandardError) do
      Dir.mktmpdir do |d|
        dir = File.join(d, 'judges')
        save_it(File.join(dir, "#{File.basename(d)}.rb"), 'a < 1')
        Judges::Judge.new(dir, lib, Loog::NULL).run(Factbase.new, {}, {}, {})
      end
    end
  end

  def test_with_standard_error
    assert_raises(StandardError) do
      Dir.mktmpdir do |d|
        dir = File.join(d, 'judges')
        save_it(File.join(dir, "#{File.basename(d)}.rb"), 'raise "intentional"')
        Judges::Judge.new(dir, lib, Loog::NULL).run(Factbase.new, {}, {}, {})
      end
    end
  end

  def test_finds_tests_in_directory_with_brackets
    Dir.mktmpdir do |d|
      dir = File.join(d, 'judge[special]path')
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, 'judge[special]path.rb'), '$fb.insert.foo = 42')
      File.write(File.join(dir, 'test1.yml'), 'before: []')
      File.write(File.join(dir, 'test2.yml'), 'before: []')
      tests = Judges::Judge.new(dir, nil, Loog::NULL).tests
      assert_equal(2, tests.size)
      assert_includes(tests.map { |t| File.basename(t) }, 'test1.yml')
      assert_includes(tests.map { |t| File.basename(t) }, 'test2.yml')
    end
  end

  def test_finds_script_in_directory_with_brackets
    Dir.mktmpdir do |d|
      name = 'judge[v1]'
      dir = File.join(d, name)
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "#{name}.rb"), '$fb.insert.bar = 1')
      assert_equal("#{name}.rb", Judges::Judge.new(dir, nil, Loog::NULL).script)
    end
  end

  def test_tests_are_sorted_in_directory_with_brackets
    Dir.mktmpdir do |d|
      name = 'judge[0-9]'
      dir = File.join(d, name)
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "#{name}.rb"), '$fb.insert')
      File.write(File.join(dir, 'c.yml'), '')
      File.write(File.join(dir, 'a.yml'), '')
      File.write(File.join(dir, 'b.yml'), '')
      assert_equal(%w[a.yml b.yml c.yml], Judges::Judge.new(dir, nil, Loog::NULL).tests.map { |f| File.basename(f) })
    end
  end

  def test_runs_with_lib_in_bracket_path
    Dir.mktmpdir do |d|
      name = 'judge[custom]'
      dir = File.join(d, name)
      lib = File.join(dir, 'lib')
      FileUtils.mkdir_p(lib)
      File.write(File.join(lib, 'helper.rb'), 'module CustomHelper; VALUE = 99; end')
      File.write(File.join(dir, "#{name}.rb"), '$fb.insert.num = CustomHelper::VALUE')
      fb = Factbase.new
      Judges::Judge.new(dir, lib, Loog::NULL).run(fb, {}, {}, {})
      assert_equal(1, fb.size)
      assert_equal(99, fb.query('(always)').each.first.num)
    end
  end
end
