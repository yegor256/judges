Feature: Simple Run
  I want to run a few judges over a factbase

  Scenario: Help can be printed
    When I run bin/judges with "-h"
    Then Exit code is zero
    And Stdout contains "--help"

  Scenario: Version can be printed
    When I run bin/judges with "--version"
    Then Exit code is zero

  Scenario: Simple run of a few judges
    When I run bin/judges with "./fixtures/simple ./target/simple.fb"
    Then Stdout contains "1 judge processed"
    And Exit code is zero
