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
      names = %w[apple banana blueberry mellon orange papaya pear strawberry].sort
      names.each do |n|
        dir = File.join(d, n)
        save_it(File.join(dir, "#{n}.rb"), 'puts 1')
      end
      list = Judges::Judges.new(d, nil, Loog::NULL, shuffle: 'b').each.to_a
      assert_equal('banana', list[1].name)
      assert_equal('blueberry', list[2].name)
      refute_equal(names.join(' '), list.map(&:name).join(' '))
      list = Judges::Judges.new(d, nil, Loog::NULL, shuffle: '').each.to_a
      assert_equal(names.join(' '), list.map(&:name).join(' '))
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
end
