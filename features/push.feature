# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT
Feature: Push
  I want to push a factbase

  Scenario: Push a small factbase
    Given We are online
    Given I make a temp directory
    Then I run bin/judges with "--verbose eval simple.fb '(0..1000).each { $fb.insert.foo = 42 }'"
    And Exit code is zero
    Then I run bin/judges with "push --token 00000000-0000-0000-0000-000000000000 --meta a:b --meta foo:bar --meta=pages_url:https://zerocracy.github.io/zerocracy.html --meta=duration:1055 {FAKE-NAME} simple.fb"
    Then Stdout contains "Pushed"
    And Exit code is zero
