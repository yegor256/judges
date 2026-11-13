# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'factbase'
require 'loog'
require 'tmpdir'
require_relative '../lib/judges'
require_relative '../lib/judges/judge'
require_relative '../lib/judges/options'
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

  def test_restores_env_after_run
    Dir.mktmpdir do |d|
      save_it(File.join(d, "#{File.basename(d)}.rb"), "raise 'no option' if ENV['ZRCY_LEAK'].nil?")
      Judges::Judge.new(d, nil, Loog::NULL).run(Factbase.new, {}, {}, Judges::Options.new(['zrcy_leak=s3cr3t']))
      assert_nil(ENV.fetch('ZRCY_LEAK', nil))
    end
  end

  def test_keeps_reserved_names_out_of_env
    Dir.mktmpdir do |d|
      save_it(File.join(d, "#{File.basename(d)}.rb"), '$fb.insert')
      Judges::Judge.new(d, nil, Loog::NULL).run(Factbase.new, {}, {}, Judges::Options.new(['path=/nowhere']))
      refute_equal('/nowhere', ENV.fetch('PATH', nil))
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

  def test_returns_absolute_test_paths
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'pack', 'alpha', 'alpha.rb'), '')
      save_it(File.join(d, 'pack', 'alpha', 'check.yml'), "---\nfoo: 42")
      save_it(File.join(d, 'pack', 'alpha', 'beta.yml'), "---\nfoo: 42")
      save_it(File.join(d, 'pack', 'empty', 'empty.rb'), '')
      Dir.chdir(d) do
        files = Judges::Judge.new('pack/alpha', nil, Loog::NULL).tests
        files.each { |f| assert_equal(File.absolute_path(f), f, "#{f} is not absolute") }
        assert_equal(%w[beta.yml check.yml], files.map { |f| File.basename(f) })
        Dir.chdir(File.join(d, 'pack', 'empty')) do
          files.each { |f| assert(File.file?(f), "#{f} is not usable after chdir") }
        end
        assert_empty(Judges::Judge.new('pack/empty', nil, Loog::NULL).tests)
        absolute = Judges::Judge.new(File.join(d, 'pack', 'alpha'), nil, Loog::NULL).tests
        absolute.each { |f| assert_equal(File.absolute_path(f), f, "#{f} is not absolute") }
        assert_equal(files.map { |f| File.basename(f) }, absolute.map { |f| File.basename(f) })
      end
    end
  end

  def test_normalizes_the_dots_in_a_test_path
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'pack', 'alpha', 'alpha.rb'), '')
      save_it(File.join(d, 'pack', 'alpha', 'check.yml'), "---\nfoo: 42")
      Dir.chdir(d) do
        files = Judges::Judge.new(File.join('pack', '..', 'pack', 'alpha'), nil, Loog::NULL).tests
        assert_equal(['check.yml'], files.map { |f| File.basename(f) })
        refute_includes(files.first, '..')
        assert(File.file?(files.first))
      end
    end
  end

  def test_finds_yaml_and_yml_packs
    Dir.mktmpdir do |d|
      save_it(File.join(d, "#{File.basename(d)}.rb"), '$fb.insert')
      save_it(File.join(d, 'b.yaml'), "expected: []\n")
      save_it(File.join(d, 'a.yml'), "expected: []\n")
      save_it(File.join(d, 'c.txt'), 'not a pack')
      assert_equal(%w[a.yml b.yaml], Judges::Judge.new(d, nil, Loog::NULL).tests.map { |t| File.basename(t) })
    end
  end
end
