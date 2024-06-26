Feature: Push
  I want to push a factbase

  Scenario: Push a small factbase
    Given We are online
    Given I make a temp directory
    Then I run bin/judges with "--verbose eval simple.fb '(0..1000).each { $fb.insert.foo = 42 }'"
    And Exit code is zero
    Then I run bin/judges with "push --token 00000000-0000-0000-0000-000000000000 simple simple.fb"
    Then Stdout contains "Pushed"
    And Exit code is zero

