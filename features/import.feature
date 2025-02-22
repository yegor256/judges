# (The MIT License)
#
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT
Feature: Import
  I want to import YAML into a factbase

  Scenario: Simple import of a small YAML
    Given I make a temp directory
    Then I have a "simple.yaml" file with content:
    """
    -
      foo: 42
      bar: 2024-03-04T22:22:22Z
      t: Hello, world!
    -
      z: 3.14
    """
    Then I run bin/judges with "--verbose import simple.yaml simple.fb"
    Then Stdout contains "Import of 2 facts finished"
    And Exit code is zero
