Feature: Pull
  I want to pull a factbase

  Scenario: Pull a small factbase, which is absent on the server
    Given We are online
    Given I make a temp directory
    Then I run bin/judges with "--verbose pull --token 00000000-0000-0000-0000-000000000000 --wait=15 {FAKE-NAME} simple.fb"
    Then Stdout contains "doesn't exist at api.zerocracy.com"
    And Exit code is zero
