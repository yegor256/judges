# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/judges'
require_relative '../lib/judges/statistics'
require_relative 'test__helper'
require 'factbase'
require 'factbase/churn'
require 'loog'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestStatistics < Minitest::Test
  def test_empty_statistics
    assert_empty(Judges::Statistics.new)
  end

  def test_not_empty_after_recording
    stats = Judges::Statistics.new
    stats.record('test-judge', 1.5, 'OK')
    refute_empty(stats)
  end

  def test_record_basic_statistics
    stats = Judges::Statistics.new
    stats.record('test-judge', 1.5, 'OK')
    stats.report(Loog::NULL)
  end

  def test_record_multiple_cycles_same_judge
    stats = Judges::Statistics.new
    stats.record('test-judge', 1.0, 'OK')
    stats.record('test-judge', 2.0, 'ERROR')
    stats.record('test-judge', 0.5, 'OK')
    buffer = Loog::Buffer.new
    stats.report(buffer)
    output = buffer.to_s
    assert_includes(output, '3.500')
    assert_includes(output, '3')
    assert_includes(output, '2xOK, 1xERROR')
  end

  def test_record_multiple_judges
    stats = Judges::Statistics.new
    stats.record('judge-a', 2.0, 'OK')
    stats.record('judge-b', 1.0, 'ERROR')
    stats.record('judge-a', 1.0, 'OK')
    buffer = Loog::Buffer.new
    stats.report(buffer)
    output = buffer.to_s
    assert_includes(output, 'judge-a')
    assert_includes(output, 'judge-b')
    assert_includes(output, '3.000')
    assert_includes(output, '1.000')
  end

  def test_record_with_churn
    stats = Judges::Statistics.new
    churn = Factbase::Churn.new(1, 0, 1)
    stats.record('test-judge', 1.0, 'OK', churn)
    stats.record('test-judge', 1.0, 'OK', churn)
    buffer = Loog::Buffer.new
    stats.report(buffer)
    output = buffer.to_s
    assert_includes(output, '2i/0d/2a')
    assert_includes(output, 'test-judge')
  end

  def test_record_without_churn
    stats = Judges::Statistics.new
    stats.record('test-judge', 1.0, 'OK')
    buffer = Loog::Buffer.new
    stats.report(buffer)
    assert_includes(buffer.to_s, 'N/A')
  end

  def test_skipped_results
    stats = Judges::Statistics.new
    stats.record('timeout-judge', 0, 'SKIPPED (timeout)')
    stats.record('fail-fast-judge', 0, 'SKIPPED (fail-fast)')
    buffer = Loog::Buffer.new
    stats.report(buffer)
    output = buffer.to_s
    assert_includes(output, 'timeout-judge')
    assert_includes(output, 'fail-fast-judge')
    assert_includes(output, 'SKIPPED (timeout)')
    assert_includes(output, 'SKIPPED (fail-fast)')
  end

  def test_result_summarization_single_result
    stats = Judges::Statistics.new
    stats.record('consistent-judge', 1.0, 'OK')
    stats.record('consistent-judge', 1.0, 'OK')
    stats.record('consistent-judge', 1.0, 'OK')
    buffer = Loog::Buffer.new
    stats.report(buffer)
    output = buffer.to_s
    assert_includes(output, 'OK')
    refute_includes(output, '3xOK')
  end

  def test_result_summarization_mixed_results
    stats = Judges::Statistics.new
    stats.record('mixed-judge', 1.0, 'OK')
    stats.record('mixed-judge', 1.0, 'ERROR')
    stats.record('mixed-judge', 1.0, 'OK')
    stats.record('mixed-judge', 1.0, 'SKIPPED (timeout)')
    buffer = Loog::Buffer.new
    stats.report(buffer)
    assert_includes(buffer.to_s, '2xOK, 1xERROR, 1xSKIPPED (timeout)')
  end

  def test_judges_sorted_by_total_time
    stats = Judges::Statistics.new
    stats.record('fast-judge', 1.0, 'OK')
    stats.record('slow-judge', 5.0, 'OK')
    stats.record('medium-judge', 2.0, 'OK')
    buffer = Loog::Buffer.new
    stats.report(buffer)
    output = buffer.to_s
    lines = output.split("\n").select { |line| line.include?('-judge') }
    assert_match(/slow-judge.*5\.000/, lines[0])
    assert_match(/medium-judge.*2\.000/, lines[1])
    assert_match(/fast-judge.*1\.000/, lines[2])
  end

  def test_report_format_headers
    stats = Judges::Statistics.new
    stats.record('test-judge', 1.0, 'OK')
    buffer = Loog::Buffer.new
    stats.report(buffer)
    output = buffer.to_s
    assert_includes(output, 'Judge execution summary:')
    assert_includes(output, 'Judge')
    assert_includes(output, 'Seconds')
    assert_includes(output, 'Cycles')
    assert_includes(output, 'Changes')
    assert_includes(output, 'Results')
  end

  def test_empty_report
    buffer = Loog::Buffer.new
    Judges::Statistics.new.report(buffer)
    assert_equal('', buffer.to_s)
  end

  def test_fractional_seconds_formatting
    stats = Judges::Statistics.new
    stats.record('precise-judge', 1.23456789, 'OK')
    buffer = Loog::Buffer.new
    stats.report(buffer)
    assert_includes(buffer.to_s, '1.235')
  end

  def test_very_long_judge_names
    stats = Judges::Statistics.new
    lengthy = 'very-long-judge-name-that-exceeds-normal-length-limits'
    stats.record(lengthy, 1.0, 'OK')
    buffer = Loog::Buffer.new
    stats.report(buffer)
    assert_includes(buffer.to_s, lengthy)
  end
end
