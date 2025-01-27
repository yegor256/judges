Feature: Inspect
  I want to inspect a factbase

  Scenario: Simple inspect of a small factbase
    Given I make a temp directory
    Then I run bin/judges with "--verbose eval simple.fb '$fb.insert.foo = 42'"
    Then I run bin/judges with "update . simple.fb"
    Then I run bin/judges with "inspect simple.fb"
    Then Stdout contains "Facts: 1"
    And Exit code is zero
