# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

$loog.info("Trying to guess a number (judge=#{$judge})...")
$fb.txn do |fbt|
  n = fbt.insert
  n.number = Random.rand(100)
  n.time = Time.now
end
