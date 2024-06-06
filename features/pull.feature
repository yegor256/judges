Feature: Pull
  I want to pull a factbase

  Scenario: Pull a small factbase
    Given We are online
    Given I make a temp directory
    Then I run bin/judges with "--verbose pull --token 00000000-0000-0000-0000-000000000000 --wait=15 simple simple.fb"
    Then Stdout contains "Pulled"
    And Exit code is zero
    Then I run bin/judges with "inspect simple.fb"
    And Exit code is zero

