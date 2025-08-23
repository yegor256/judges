# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/judges'
require_relative '../lib/judges/options'
require_relative 'test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestOptions < Minitest::Test
  def test_basic
    opts = Judges::Options.new(['token=a77', 'max=42'])
    assert_equal('a77', opts.token)
    assert_equal(42, opts.max)
  end

  def test_stips_spaces
    opts = Judges::Options.new(['  token=a77   ', 'max  =  42'])
    assert_equal('a77', opts.token)
    assert_equal(42, opts.max)
  end

  def test_case_insensitive
    opts = Judges::Options.new(['aBcDeF=1', 'aBCDEf=2'])
    assert_equal(2, opts.abcdef)
  end

  def test_with_nil
    opts = Judges::Options.new(nil)
    assert_nil(opts.foo)
    assert_empty(opts)
  end

  def test_with_empty_string
    opts = Judges::Options.new('   ')
    assert_nil(opts.foo)
    assert_empty(opts, opts)
  end

  def test_with_empty_strings
    opts = Judges::Options.new(['', nil])
    assert_nil(opts.foo)
    assert_empty(opts)
  end

  def test_with_string
    opts = Judges::Options.new('a=1,b=42')
    assert_equal(1, opts.a)
    assert_equal(42, opts.b)
  end

  def test_with_hash
    opts = Judges::Options.new('foo' => 42, 'bar' => 'hello')
    assert_equal(42, opts.foo)
    assert_equal('hello', opts.Bar)
    assert_nil(opts.xxx)
  end

  def test_with_nil_values
    opts = Judges::Options.new('foo' => nil)
    assert_nil(opts.foo)
  end

  def test_converts_to_string
    opts = Judges::Options.new('foo' => 44, 'bar' => 'long-string-maybe-secret')
    s = opts.to_s
    assert_includes(s, 'FOO → 44 (Integer)', s)
    assert_includes(s, '"long****************cret"', s)
  end

  def test_merge
    left = Judges::Options.new(['a = 1', 'b = 4'])
    right = Judges::Options.new(['a = 44', 'c = 3'])
    opts = left + right
    assert_equal(44, opts.a)
    assert_equal(3, opts.c)
  end

  def test_merge_by_symbols
    opts = Judges::Options.new(a: 42) + Judges::Options.new(b: 7)
    assert_equal(42, opts.a, opts)
    assert_equal(7, opts.b, opts)
  end
end
