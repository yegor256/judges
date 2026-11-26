# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../judges'

# Positive integer parser for test pack settings.
#
# Validates and converts numeric YAML settings (such as +runs+, +timeout+, and
# +repeat+) into positive integers while preserving clear diagnostics when
# malformed strings, fractional numbers, or non-positive values are provided.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Judges::PackInt
  # Initialize.
  # @param [Object, nil] value The raw YAML or option value
  # @param [String] key The setting name (e.g., 'runs', 'timeout', 'repeat')
  # @param [String] path The relative path of the test pack YAML file
  def initialize(value, key, path)
    @value = value
    @key = key
    @path = path
  end

  # Parse the setting into a positive integer, or return +default+ if +nil+.
  # @param [Integer, nil] default Fallback value when raw value is +nil+
  # @return [Integer, nil] The validated positive integer, or +default+
  # @raise [ArgumentError] If the value is not a positive integer
  def parse(default = nil)
    return default if @value.nil?
    if @value.is_a?(Integer) || (@value.is_a?(String) && @value.strip.match?(/\A[+-]?\d+\z/))
      num = @value.to_i
      return num if num.positive?
    end
    raise(
      ArgumentError,
      "The '#{@key}' in #{@path} must be a positive integer, while #{@value.inspect} (#{@value.class}) found"
    )
  end
end
