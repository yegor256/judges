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
  SECRETS = %w[--token].freeze

  OPTIONS = %w[-o --option].freeze

  SENSITIVE = /\A(?<key>[a-z_0-9]*(?:token|secret|password|key))=(?<value>.+)\z/i

  # Initialize.
  # @param [Array<String>] args The arguments, as they arrived
  def initialize(args)
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
    return mask(arg) if SECRETS.include?(prev)
    return pairs(arg) if OPTIONS.include?(prev)
    opt = SECRETS.find { |s| arg.start_with?("#{s}=") }
    return "#{opt}=#{mask(arg[(opt.length + 1)..])}" if opt
    opt = OPTIONS.find { |s| arg.start_with?("#{s}=") }
    return "#{opt}=#{pairs(arg[(opt.length + 1)..])}" if opt
    pairs(arg)
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
