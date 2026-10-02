# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Monotonic timer for elapsed durations.
module Judges; end unless defined?(Judges)

class Judges::Clock
  attr_reader :started_at

  def initialize
    @started_at = Time.now
    @start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def elapsed
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start
  end

  def elapsed_since(start)
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
  end
end
