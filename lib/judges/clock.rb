# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Monotonic timer for elapsed durations.
module Judges; end unless defined?(Judges)

class Judges::Clock
  attr_reader :epoch

  def initialize
    @epoch = Time.now
    @start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def elapsed
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start
  end

  def duration(start)
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
  end
end
