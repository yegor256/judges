# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

Feature: Echo
  I want to see the full command line when using --echo flag

  Scenario: Echo flag prints command line
    When I run bin/judges with "--echo version"
    Then Exit code is zero
    And Stdout contains "bin/judges --echo version"
