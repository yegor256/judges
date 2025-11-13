# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../judges'

# Statistics collector for judge executions.
#
# This class collects and aggregates statistics about judge executions
# across multiple cycles, providing insights into performance and results.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Statistics
  # Initialize empty statistics.
  def initialize
    @data = {}
  end

  # Check if statistics are empty.
  # @return [Boolean] True if no statistics have been collected
  def empty?
    @data.empty?
  end

  # Record statistics for a judge execution.
  # @param [String] name The judge name
  # @param [Float] time The execution time for this run
  # @param [String] result The result for this run
  # @param [Churn] churn The churn for this run (can be nil)
  def record(name, time, result, churn = nil)
    unless @data[name]
      @data[name] = {
        total_time: 0.0,
        cycles: 0,
        results: [],
        total_churn: nil
      }
    end
    stats = @data[name]
    stats[:total_time] += time
    stats[:cycles] += 1
    stats[:results] << result
    return unless churn
    if stats[:total_churn]
      stats[:total_churn] += churn
    else
      stats[:total_churn] = churn
    end
  end

  # Generate a formatted statistics report.
  # @param [Loog] loog Logging facility for output
  def report(loog)
    return if empty?
    fmt = "%-30s\t%9s\t%7s\t%15s\t%-15s"
    loog.info(
      [
        'Judge execution summary:',
        format(fmt, 'Judge', 'Seconds', 'Cycles', 'Changes', 'Results'),
        format(fmt, '---', '---', '---', '---', '---'),
        @data.sort_by { |_, stats| stats[:total_time] }.reverse.map do |name, stats|
          format(fmt, name, format('%.3f', stats[:total_time]), stats[:cycles],
                 stats[:total_churn] ? stats[:total_churn].to_s : 'N/A', summarize(stats[:results]))
        end.join("\n  ")
      ].join("\n  ")
    )
  end

  private

  # Summarize results across multiple cycles into a compact string.
  # @param [Array<String>] results Array of result strings from different cycles
  # @return [String] Compact summary of results
  def summarize(results)
    return 'N/A' if results.empty?
    counts = results.each_with_object(Hash.new(0)) { |result, hash| hash[result] += 1 }
    return results.first if counts.size == 1
    counts.sort_by { |_, count| -count }.map { |result, count| "#{count}x#{result}" }.join(', ')
  end
end
