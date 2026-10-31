# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../judges'

# Command line arguments, with the secrets in them hidden.
#
# The +--echo+ switch prints the entire command line into the log, and in a CI
# job that log is public. Some of the arguments carry a token, so they must not
# be printed as they are.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Judges::MaskedArgs
  LONG = /\A--(?<name>[a-z-]+)(?:=(?<value>.*))?\z/m

  SENSITIVE = /\A\s*(?<key>[a-z_0-9]*(?:token|secret|password|key))\s*=\s*(?<value>.+)\z/i

  # Initialize.
  # @param [Array<String>] args The arguments, as they arrived
  def initialize(args)
    raise(ArgumentError, 'The args are nil') if args.nil?
    @args = args
  end

  # Render them as one line, with every secret hidden.
  # @return [String] The line, safe to print
  def to_s
    @args.each_with_index.map { |arg, i| hidden(arg, i.positive? ? @args[i - 1] : nil) }.join(' ')
  end

  private

  # Hide whatever is secret in one argument.
  # @param [String] arg The argument
  # @param [String, nil] prev The argument before it, if any
  # @return [String] The argument, safe to print
  def hidden(arg, prev)
    before = LONG.match(prev.to_s)
    return mask(arg) if before && before[:value].nil? && named?(before[:name], 'token', 3)
    return pairs(arg) if prev == '-o' || (before && before[:value].nil? && named?(before[:name], 'option', 1))
    return "-o#{pairs(arg[2..])}" if arg.start_with?('-o') && !arg.start_with?('--')
    m = LONG.match(arg)
    return pairs(arg) if m.nil? || m[:value].nil?
    return "--#{m[:name]}=#{mask(m[:value])}" if named?(m[:name], 'token', 3)
    return "--#{m[:name]}=#{pairs(m[:value])}" if named?(m[:name], 'option', 1)
    pairs(arg)
  end

  # Is it a long option name, the way +OptionParser+ accepts it, which is
  # the full name or any of its prefixes?
  # @param [String] name The name, without the leading dashes
  # @param [String] full The full name of the option
  # @param [Integer] min How many characters are enough to recognize it
  # @return [Boolean] True if the name stands for the option
  def named?(name, full, min)
    name.length >= min && full.start_with?(name)
  end

  # Hide the value of a "key=value" pair whose key names a secret.
  # @param [String] arg The pair, or anything else
  # @return [String] The pair with the value hidden, or the argument as it was
  def pairs(arg)
    m = SENSITIVE.match(arg)
    return arg if m.nil?
    "#{m[:key]}=#{mask(m[:value])}"
  end

  # Hide the middle of a secret, the way +Judges::Options#to_s+ hides it.
  # @param [String] txt The secret
  # @return [String] The same length, mostly asterisks
  def mask(txt)
    return '*' * txt.length if txt.length <= 8
    "#{txt[0..3]}#{'*' * (txt.length - 8)}#{txt[-4..]}"
  end
end
