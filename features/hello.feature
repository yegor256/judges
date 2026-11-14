# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

Feature: Hello
  I want to see diagnostic information when using --hello flag

  Scenario: Hello flag prints diagnostic information
    When I run bin/judges with "--hello version"
    Then Exit code is zero
    And Stdout contains "Judges "
    And Stdout contains "Factbase "
    And Stdout contains "Baza-rb "
    And Stdout contains "Ruby: "
    And Stdout contains "Current directory: "
    And Stdout contains "Time: "
