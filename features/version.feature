# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

Feature: Version
  I want to know the version of the gem

  Scenario: Print the version
    Given I make a temp directory
    Then I run bin/judges with "version"
    And Exit code is zero
