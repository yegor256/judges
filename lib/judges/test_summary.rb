# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'ellipsized'
require_relative '../judges'

# Summary printer for judge test runs.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Judges::TestSummary
  # Initialize summary printer.
  # @param [Loog] loog Logging facility
  def initialize(loog)
    @loog = loog
  end

  # Print test execution summary table and throw final status symbol.
  # @param [Hash{String => Float}] times Execution duration per test badge
  # @param [Array<String>] errors Test badges that failed
  # @param [Array<String>] skips Test badges that were skipped
  # @param [Integer] tested Number of judges tested
  # @param [Integer] tests Number of test packs executed
  def print(times, errors, skips, tested, tests)
    unless times.empty?
      fmt = "%-60s\t%9s\t%-9s"
      @loog.info(
        [
          'Test summary:',
          format(fmt, 'Script', 'Seconds', 'Result'),
          format(fmt, '---', '---', '---'),
          times.sort_by { |_, v| v }.reverse.map do |script, sec|
            format(fmt, script.ellipsized(50), format('%.3f', sec), label(script, errors, skips))
          end.join("\n  ")
        ].join("\n  ")
      )
    end
    throw(:'👍 No judges tested') if tested.zero?
    throw(:"👍 All #{tested} judge(s) but no tests passed") if tests.zero?
    throw(:"👍 All #{tested} judge(s) and #{tests} tests passed") if errors.empty?
    throw(:"❌ #{tested} judge(s) tested, #{errors.size} of them failed")
  end

  private

  def label(script, errors, skips)
    return 'ERROR' if errors.include?(script)
    return 'SKIPPED' if skips.include?(script)
    'OK'
  end
end
