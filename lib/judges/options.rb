# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'others'
require_relative '../judges'

# Options for Ruby scripts in the judges.
#
# This class manages configuration options that can be passed to judge scripts.
# Options are key-value pairs that can be provided in various formats and are
# normalized into a hash with symbol keys. Values are automatically converted
# to appropriate types (integers for numeric strings, etc.).
#
# The class also provides dynamic method access to options using the 'others' gem,
# allowing options to be accessed as method calls.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Options
  # Initialize a new Options instance.
  #
  # @param [Array<String>, String, Hash, nil] pairs List of key-value pairs.
  #   Can be provided as:
  #   - Array of strings: ["token=af73cd3", "max_speed=1"]
  #   - Comma-separated string: "token=af73cd3,max_speed=1"
  #   - Hash: { token: "af73cd3", max_speed: 1 }
  #   - nil: Creates empty options
  # @example Initialize with array
  #   options = Judges::Options.new(["token=abc123", "debug=true"])
  # @example Initialize with string
  #   options = Judges::Options.new("token=abc123,debug")
  # @example Initialize with hash
  #   options = Judges::Options.new({ token: "abc123", debug: true })
  def initialize(pairs = nil)
    @pairs = pairs
  end

  # Check if options are empty.
  #
  # @return [Boolean] true if no options are set, false otherwise
  # @example Check if options are empty
  #   options = Judges::Options.new
  #   options.empty? # => true
  #   options = Judges::Options.new(["key=value"])
  #   options.empty? # => false
  def empty?
    to_h.empty?
  end

  # Merge with another Options object.
  #
  # Creates a new Options instance containing values from both this instance
  # and the other. Values from the other Options object override values
  # with the same key in this instance.
  #
  # @param [Judges::Options] other The other options to merge
  # @return [Judges::Options] A new Options object with merged values
  # @example Merge two Options objects
  #   opts1 = Judges::Options.new(["token=abc", "debug=true"])
  #   opts2 = Judges::Options.new(["token=xyz", "verbose=true"])
  #   merged = opts1 + opts2
  #   # merged now has token=xyz, debug=true, verbose=true
  def +(other)
    h = to_h
    other.to_h.each do |k, v|
      h[k] = v
    end
    Judges::Options.new(h)
  end

  # Convert options to a string representation.
  #
  # Creates a human-readable string representation of all options,
  # suitable for logging. Sensitive values (longer than 8 characters)
  # are partially masked with asterisks for security.
  #
  # @return [String] Formatted string with each option on a new line
  # @example Convert to string
  #   options = Judges::Options.new(["token=supersecrettoken", "debug=true"])
  #   puts options.to_s
  #   # Output:
  #   # debug → "true"
  #   # token → "supe****oken"
  def to_s
    to_h.map do |k, v|
      v = "#{v[0..3]}#{'*' * (v.length - 8)}#{v[-4..]}" if v.is_a?(String) && v.length > 8
      v =
        if v.is_a?(String)
          "\"#{v}\""
        else
          "#{v} (#{v.class.name})"
        end
      "#{k} → #{v}"
    end.sort.join("\n")
  end

  # Convert options to hash.
  #
  # Converts the raw pairs into a normalized hash with the following transformations:
  # - Keys are converted to uppercase symbols
  # - Values without equals sign get 'true' as value
  # - Numeric strings are converted to integers
  # - Leading/trailing whitespace is stripped
  # - Empty or nil keys are rejected
  #
  # @return [Hash] The options as a hash with symbol keys
  # @example Convert to hash
  #   options = Judges::Options.new("token=abc123,max_speed=100,debug")
  #   options.to_h # => { TOKEN: "abc123", MAX_SPEED: 100, DEBUG: "true" }
  def to_h
    @to_h ||=
      begin
        pp = @pairs || []
        pp = pp.split(',') if pp.is_a?(String)
        if pp.is_a?(Array)
          pp = pp
            .compact
            .map(&:strip)
            .reject(&:empty?)
            .map { |s| s.split('=', 2) }
            .map { |a| a.size == 1 ? [a[0], nil] : a }
            .reject { |a| a[0].empty? }
            .to_h
        end
        pp
          .reject { |k, _| k.nil? }
          .compact
          .reject { |k, _| k.is_a?(String) && k.empty? }
          .to_h
          .transform_values { |v| v.nil? ? 'true' : v }
          .transform_values { |v| v.is_a?(String) ? v.strip : v }
          .transform_values { |v| v.is_a?(String) && v.match?(/^[0-9]+$/) ? v.to_i : v }
          .transform_keys { |k| k.to_s.strip.upcase.to_sym }
      end
  end

  # Get option by name.
  #
  # This method is implemented using the 'others' gem, which provides
  # dynamic method handling. It allows accessing options as method calls.
  # Method names are automatically converted to uppercase symbols to match
  # the keys in the options hash.
  #
  # @!method method_missing(method_name, *args)
  #   Dynamic method to access option values
  #   @param [Symbol] method_name The name of the option to retrieve
  #   @param [Array] args Additional arguments (unused)
  #   @return [Object, nil] The value of the option, or nil if not found
  # @example Access options as methods
  #   options = Judges::Options.new(["token=abc123", "max_speed=100"])
  #   options.token # => "abc123"
  #   options.max_speed # => 100
  #   options.missing_option # => nil
  others do |*args|
    to_h[args[0].upcase.to_sym]
  end
end
