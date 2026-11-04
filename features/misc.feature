# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

Feature: Misc
  I want to get some meta info

  Scenario: Help can be printed
    When I run bin/judges with "--help --hello"
    Then Exit code is zero
    And Stdout contains "--help"

  Scenario: Version can be printed
    When I run bin/judges with "--version"
    Then Exit code is zero

  Scenario: Unicode symbols are replaced with ASCII
    When I run bin/judges with "--ascii test ./fixtures"
    Then Exit code is zero
    And Stdout contains "> Testing"
    And Stdout contains "+ All 3 judge(s) and 3 tests passed"
