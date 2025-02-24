# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

Feature: Trim
  I want to trim a factbase

  Scenario: Simple trimming of a factbase, with a query
    Given I make a temp directory
    Then I run bin/judges with "--verbose eval simple.fb '$fb.insert.foo = 42'"
    Given I run bin/judges with "trim --query '(eq foo 42)' simple.fb"
    Then Stdout contains "1 fact(s) deleted"
    And Exit code is zero

  Scenario: Delete nothing by default
    Given I make a temp directory
    Then I run bin/judges with "--verbose eval simple.fb '$fb.insert.foo = 42'"
    Given I run bin/judges with "trim simple.fb"
    Then Stdout contains "No facts deleted"
    And Exit code is zero
