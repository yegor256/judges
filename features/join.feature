# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

Feature: Join
  I want to join two factbases

  Scenario: Simple join of two small factbases
    Given I make a temp directory
    Then I run bin/judges with "--verbose eval first.fb '$fb.insert.foo = 42'"
    Then I run bin/judges with "--verbose eval second.fb '$fb.insert.foo = 42'"
    Then I run bin/judges with "update . first.fb"
    Then I run bin/judges with "update . second.fb"
    Then I run bin/judges with "join first.fb second.fb"
    Then Exit code is zero
    And Stdout contains "joined"
