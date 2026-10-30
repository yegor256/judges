# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/judges/pretty_exception'
require_relative 'test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestPrettyException < Minitest::Test
  def test_long_message
    txt = 'test ' * 50
    assert_equal(txt.ellipsized(100, :right), Judges::PrettyException.new(RuntimeError.new(txt)).message)
  end

  def test_short_message
    txt = 'test ' * 15
    assert_equal(txt, Judges::PrettyException.new(RuntimeError.new(txt)).message)
  end

  def test_hide_class
    exp = Judges::PrettyException.new(RuntimeError.new('test'))
    assert_equal(exp.class, RuntimeError)
    assert_instance_of(RuntimeError, exp)
    assert_kind_of(RuntimeError, exp)
    assert_kind_of(StandardError, exp)
  end

  def test_refuses_a_nil_exception
    assert_includes(assert_raises(ArgumentError) { Judges::PrettyException.new(nil) }.message, 'The exception is nil')
  end

  def test_long_utf_sixteen_little_endian_message
    pretty = Judges::PrettyException.new(RuntimeError.new(('café ' * 40).encode('UTF-16LE')))
    assert_equal(100, pretty.message.length)
    assert_equal(Encoding::UTF_8, pretty.message.encoding)
  end

  def test_long_utf_sixteen_big_endian_message
    pretty = Judges::PrettyException.new(RuntimeError.new(('alpha ' * 40).encode('UTF-16BE')))
    assert_equal(100, pretty.message.length)
    assert_equal(Encoding::UTF_8, pretty.message.encoding)
  end

  def test_long_utf_thirty_two_little_endian_message
    pretty = Judges::PrettyException.new(RuntimeError.new(('gamma ' * 40).encode('UTF-32LE')))
    assert_equal(100, pretty.message.length)
    assert_equal(Encoding::UTF_8, pretty.message.encoding)
  end

  def test_long_utf_thirty_two_big_endian_message
    pretty = Judges::PrettyException.new(RuntimeError.new(('delta ' * 40).encode('UTF-32BE')))
    assert_equal(100, pretty.message.length)
    assert_equal(Encoding::UTF_8, pretty.message.encoding)
  end

  def test_short_utf_sixteen_message
    pretty = Judges::PrettyException.new(RuntimeError.new('short'.encode('UTF-16LE')))
    assert_equal('short', pretty.message)
    assert_equal(Encoding::UTF_8, pretty.message.encoding)
  end

  def test_windows_encoded_message
    pretty = Judges::PrettyException.new(RuntimeError.new('résumé'.encode('Windows-1252')))
    assert_equal('résumé', pretty.message)
    assert_equal(Encoding::UTF_8, pretty.message.encoding)
  end

  def test_iso_encoded_message
    pretty = Judges::PrettyException.new(RuntimeError.new('naïve'.encode('ISO-8859-1')))
    assert_equal('naïve', pretty.message)
    assert_equal(Encoding::UTF_8, pretty.message.encoding)
  end

  def test_binary_encoded_message
    pretty = Judges::PrettyException.new(RuntimeError.new('plain text'.b))
    assert_equal('plain text', pretty.message)
    assert_equal(Encoding::UTF_8, pretty.message.encoding)
  end

  def test_empty_string_message
    pretty = Judges::PrettyException.new(RuntimeError.new(''))
    assert_empty(pretty.message)
    assert_equal(Encoding::UTF_8, pretty.message.encoding)
  end
end
