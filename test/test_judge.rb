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
end
