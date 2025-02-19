# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

$fb.query("(and (exists number) (lt time #{Time.now.utc.iso8601}))").each do |f|
  n = $fb.insert
  n.guess = f.number
end
