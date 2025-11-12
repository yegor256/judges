# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require_relative '../lib/judges/ascii_loog'
require_relative 'test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestAsciiLoog < Minitest::Test
  def test_converts_unicode_symbols
    buf = Loog::Buffer.new
    loog = Judges::AsciiLoog.new(buf)
    loog.info('👍 Success message')
    loog.warn('❌ Warning message')
    loog.error('👎 Error message')
    loog.info('👉 Running test')
    output = buf.to_s
    refute_includes(output, '👍')
    refute_includes(output, '❌')
    refute_includes(output, '👎')
    refute_includes(output, '👉')
  end

  def test_converts_all_defined_symbols
    buf = Loog::Buffer.new
    loog = Judges::AsciiLoog.new(buf)
    Judges::AsciiLoog::UNICODE_TO_ASCII.each_key do |unicode|
      loog.info("Test #{unicode} symbol")
      output = buf.to_s
      refute_includes(output, unicode)
    end
  end

  def test_leaves_non_unicode_text_unchanged
    buf = Loog::Buffer.new
    loog = Judges::AsciiLoog.new(buf)
    message = 'Regular ASCII message with + and - symbols'
    loog.info(message)
    assert_includes(buf.to_s, message)
  end

  def test_handles_empty_and_nil_messages
    buf = Loog::Buffer.new
    loog = Judges::AsciiLoog.new(buf)
    loog.info('')
    loog.info(nil)
    refute_nil(buf.to_s)
  end

  def test_delegates_unknown_methods
    mock_loog = Minitest::Mock.new
    loog = Judges::AsciiLoog.new(mock_loog)
    mock_loog.expect(:some_custom_method, 'result', ['arg'])
    result = loog.some_custom_method('arg')
    assert_equal('result', result)
    mock_loog.verify
  end

  def test_responds_to_original_logger_methods
    buf = Loog::Buffer.new
    loog = Judges::AsciiLoog.new(buf)
    assert_respond_to(loog, :info)
    assert_respond_to(loog, :warn)
    assert_respond_to(loog, :error)
    assert_respond_to(loog, :debug)
  end

  def test_mixed_unicode_and_ascii
    buf = Loog::Buffer.new
    loog = Judges::AsciiLoog.new(buf)
    loog.info('Mixed: 👍 success and ❌ failure')
    output = buf.to_s
    refute_includes(output, '👍')
    refute_includes(output, '❌')
  end

  def test_multiple_same_symbols
    buf = Loog::Buffer.new
    loog = Judges::AsciiLoog.new(buf)
    loog.info('👍👍👍 Triple success')
    output = buf.to_s
    refute_includes(output, '👍')
  end
end
