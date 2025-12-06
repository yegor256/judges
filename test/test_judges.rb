# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require 'tmpdir'
require_relative '../lib/judges'
require_relative '../lib/judges/judges'
require_relative 'test__helper'

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

  def test_shuffles_them
    Dir.mktmpdir do |d|
      names = %w[apple banana blueberry mellon orange papaya pear strawberry grapes pineapple grapefruit].sort
      names.each do |n|
        dir = File.join(d, n)
        save_it(File.join(dir, "#{n}.rb"), 'puts 1')
      end
      list = Judges::Judges.new(d, nil, Loog::NULL, shuffle: 'b').each.to_a
      assert_equal('banana', list[1].name)
      assert_equal('blueberry', list[2].name)
      refute_equal(names.join(' '), list.map(&:name).join(' '))
      list = Judges::Judges.new(d, nil, Loog::NULL, shuffle: '').each.to_a
      refute_equal(names.join(' '), list.map(&:name).join(' '))
    end
  end

  def test_shuffles_and_boosts
    Dir.mktmpdir do |d|
      names = %w[red blue green black orange pink yellow].sort
      names.each do |n|
        dir = File.join(d, n)
        save_it(File.join(dir, "#{n}.rb"), 'puts 1')
      end
      list = Judges::Judges.new(d, nil, Loog::NULL, shuffle: '', boost: ['yellow']).each.to_a
      assert_equal('yellow', list[0].name)
      refute_equal((names - ['yellow']).join(' '), list[1..].map(&:name).join(' '))
    end
  end

  def test_keeps_them_all
    colors = %w[blue orange yellow black white pink magenta]
    ['', 'b', 'ye'].each do |pfx|
      Dir.mktmpdir do |d|
        names = colors.sort
        names.each do |n|
          dir = File.join(d, n)
          save_it(File.join(dir, "#{n}.rb"), 'puts 1')
        end
        after = Judges::Judges.new(d, nil, Loog::NULL, shuffle: pfx).each.to_a.map(&:name)
        assert_equal(names.size, after.size)
        names.each { |n| assert_includes(after, n, "#{n.inspect} is missing, with #{pfx.inspect}") }
        after.each { |n| assert_includes(names, n, "#{n.inspect} is extra, with #{pfx.inspect}") }
      end
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

  def test_demotes_judges
    Dir.mktmpdir do |d|
      names = %w[alpha beta gamma delta epsilon].sort
      names.each do |n|
        dir = File.join(d, n)
        save_it(File.join(dir, "#{n}.rb"), 'puts 1')
      end
      list = Judges::Judges.new(d, nil, Loog::NULL, demote: %w[beta delta]).each.to_a
      result = list.map(&:name)
      demoted = result[-2..]
      assert_includes(demoted, 'beta')
      assert_includes(demoted, 'delta')
    end
  end

  def test_same_seed_produces_same_order
    Dir.mktmpdir do |d|
      names = %w[alpha beta gamma delta epsilon zeta eta theta].sort
      names.each do |n|
        dir = File.join(d, n)
        save_it(File.join(dir, "#{n}.rb"), 'puts 1')
      end
      first = Judges::Judges.new(d, nil, Loog::NULL, seed: 42).each.to_a
      second = Judges::Judges.new(d, nil, Loog::NULL, seed: 42).each.to_a
      assert_equal(first.map(&:name), second.map(&:name), 'Same seed should produce same order')
    end
  end

  def test_different_seed_produces_different_order
    Dir.mktmpdir do |d|
      names = %w[alpha beta gamma delta epsilon zeta eta theta].sort
      names.each do |n|
        dir = File.join(d, n)
        save_it(File.join(dir, "#{n}.rb"), 'puts 1')
      end
      first = Judges::Judges.new(d, nil, Loog::NULL, seed: 42).each.to_a
      second = Judges::Judges.new(d, nil, Loog::NULL, seed: 99).each.to_a
      refute_equal(first.map(&:name), second.map(&:name), 'Different seeds should produce different orders')
    end
  end

  def test_default_seed
    Dir.mktmpdir do |d|
      names = %w[alpha beta gamma delta epsilon zeta eta theta].sort
      names.each do |n|
        dir = File.join(d, n)
        save_it(File.join(dir, "#{n}.rb"), 'puts 1')
      end
      first = Judges::Judges.new(d, nil, Loog::NULL, seed: 0).each.to_a
      second = Judges::Judges.new(d, nil, Loog::NULL).each.to_a
      assert_equal(first.map(&:name), second.map(&:name), 'Default seed should be 0')
    end
  end

  def test_boost_and_demote_together
    Dir.mktmpdir do |d|
      names = %w[one two three four five six].sort
      names.each do |n|
        dir = File.join(d, n)
        save_it(File.join(dir, "#{n}.rb"), 'puts 1')
      end
      list = Judges::Judges.new(d, nil, Loog::NULL, boost: %w[six two], demote: %w[one four], shuffle: 'xyz').each.to_a
      result = list.map(&:name)
      boosted = result[0..1]
      assert_includes(boosted, 'six')
      assert_includes(boosted, 'two')
      demoted = result[-2..]
      assert_includes(demoted, 'one')
      assert_includes(demoted, 'four')
    end
  end

  def test_boost_with_wildcard_patterns
    Dir.mktmpdir do |d|
      names = %w[test_alpha test_beta production_gamma production_delta other].sort
      names.each do |n|
        dir = File.join(d, n)
        save_it(File.join(dir, "#{n}.rb"), 'puts 1')
      end
      list = Judges::Judges.new(d, nil, Loog::NULL, boost: ['test_*']).each.to_a
      result = list.map(&:name)
      boosted = result[0..1]
      assert_includes(boosted, 'test_alpha')
      assert_includes(boosted, 'test_beta')
    end
  end

  def test_demote_with_wildcard_patterns
    Dir.mktmpdir do |d|
      names = %w[alpha beta zzz_gamma zzz_delta epsilon].sort
      names.each do |n|
        dir = File.join(d, n)
        save_it(File.join(dir, "#{n}.rb"), 'puts 1')
      end
      list = Judges::Judges.new(d, nil, Loog::NULL, demote: ['zzz*']).each.to_a
      result = list.map(&:name)
      demoted = result[-2..]
      assert_includes(demoted, 'zzz_gamma')
      assert_includes(demoted, 'zzz_delta')
    end
  end

  def test_boost_and_demote_with_wildcards_together
    Dir.mktmpdir do |d|
      names = %w[priority_one priority_two normal_alpha normal_beta slow_gamma slow_delta].sort
      names.each do |n|
        dir = File.join(d, n)
        save_it(File.join(dir, "#{n}.rb"), 'puts 1')
      end
      list = Judges::Judges.new(d, nil, Loog::NULL, boost: ['priority*'], demote: ['slow*']).each.to_a
      result = list.map(&:name)
      boosted = result[0..1]
      assert_includes(boosted, 'priority_one')
      assert_includes(boosted, 'priority_two')
      demoted = result[-2..]
      assert_includes(demoted, 'slow_gamma')
      assert_includes(demoted, 'slow_delta')
    end
  end
end
