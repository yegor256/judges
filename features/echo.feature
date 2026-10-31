# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

Feature: Echo
  I want to see the full command line when using --echo flag

  Scenario: Echo flag prints command line
    When I run bin/judges with "--echo version"
    Then Exit code is zero
    And Stdout contains "bin/judges --echo version"

  Scenario: Echo flag prints command line even when a flag is refused
    When I run bin/judges with "--echo update --lifetime=5m j x.fb"
    Then Exit code is not zero
    And Stdout contains "bin/judges --echo update --lifetime=5m j x.fb"

  Scenario: Echo flag prints command line with the secret hidden
    When I run bin/judges with "--echo pull --token=SUPERSECRET123 --port=zzz foo x.fb"
    Then Exit code is not zero
    And Stdout contains "--token=SUPE******T123"
