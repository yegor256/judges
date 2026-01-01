# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../judges'

# ASCII wrapper for Loog logging facility.
#
# This class wraps any Loog logger and converts Unicode symbols to ASCII
# equivalents when the --ascii option is enabled.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Judges::AsciiLoog
  # Unicode to ASCII symbol mapping
  UNICODE_TO_ASCII = {
    '👍' => '+',
    '👎' => '-',
    '❌' => '!',
    '👉' => '>',
    '✓' => '+',
    '✗' => '!',
    '►' => '>',
    '◄' => '<',
    '▼' => 'v',
    '▲' => '^'
  }.freeze

  # Initialize the ASCII wrapper.
  # @param [Loog] loog The original logging facility to wrap
  def initialize(loog)
    @loog = loog
  end

  # Convert Unicode symbols to ASCII equivalents.
  # @param [String] message The message to convert
  # @return [String] The converted message with ASCII symbols
  def to_ascii(message)
    result = message.to_s
    if result.encoding != Encoding::UTF_8
      begin
        result = result.encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
      rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
        result = result.force_encoding(Encoding::UTF_8).encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
      end
    end
    UNICODE_TO_ASCII.each do |unicode, ascii|
      result = result.gsub(unicode, ascii)
    end
    result
  end

  # Log an info message, converting Unicode to ASCII.
  # @param [String] message The message to log
  def info(message)
    @loog.info(to_ascii(message))
  end

  # Log a warning message, converting Unicode to ASCII.
  # @param [String] message The message to log
  def warn(message)
    @loog.warn(to_ascii(message))
  end

  # Log an error message, converting Unicode to ASCII.
  # @param [String] message The message to log
  def error(message)
    @loog.error(to_ascii(message))
  end

  # Log a debug message, converting Unicode to ASCII.
  # @param [String] message The message to log
  def debug(message)
    @loog.debug(to_ascii(message))
  end

  # Delegate all other methods to the original logger.
  def method_missing(method, *, &)
    @loog.send(method, *, &)
  end

  # Check if the original logger responds to a method.
  def respond_to_missing?(method, include_private = false)
    @loog.respond_to?(method, include_private) || super
  end
end
