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
  # The options whose values are secrets.
  SECRETS = %w[--token].freeze

  # Initialize.
  # @param [Array<String>] args The arguments, as they arrived
  def initialize(args)
    @args = args
  end

  # Render them as one line, with every secret hidden.
  # @return [String] The line, safe to print
  def to_s
    @args.each_with_index.map do |arg, i|
      if i.positive? && SECRETS.include?(@args[i - 1])
        mask(arg)
      elsif (opt = SECRETS.find { |s| arg.start_with?("#{s}=") })
        "#{opt}=#{mask(arg[(opt.length + 1)..])}"
      else
        arg
      end
    end.join(' ')
  end

  private

  # Hide the middle of a secret, the way +Judges::Options#to_s+ hides it.
  # @param [String] txt The secret
  # @return [String] The same length, mostly asterisks
  def mask(txt)
    return '*' * txt.length if txt.length <= 8
    "#{txt[0..3]}#{'*' * (txt.length - 8)}#{txt[-4..]}"
  end
end
