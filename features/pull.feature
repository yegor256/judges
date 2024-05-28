Feature: Pull
  I want to pull a factbase

  Scenario: Pull a small factbase
    Given I make a temp directory
    Then I run bin/judges with "pull --token 0000-0000-0000-0000 simple simple.fb"
    Then Stdout contains "Pulled"
    And Exit code is zero
    Then I run bin/judges with "inspect simple.fb"
    And Exit code is zero

