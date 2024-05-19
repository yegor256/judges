Feature: Print
  I want to print a factbase

  Scenario: Simple print of a small factbase, to YAML
    Given I make a temp directory
    Then I run bin/judges with "--verbose eval simple.fb '$fb.insert.foo = 42'"
    Then I run bin/judges with "update . simple.fb"
    Then I run bin/judges with "print --format=yaml simple.fb simple.yml"
    Then Stdout contains "printed"
    And Exit code is zero

  Scenario: Simple print of a small factbase, to JSON
    Given I make a temp directory
    Then I run bin/judges with "--verbose eval simple.fb '$fb.insert.foo = 42'"
    Then I run bin/judges with "update . simple.fb"
    Then I run bin/judges with "print --format=json simple.fb simple.json"
    Then Stdout contains "printed"
    And Exit code is zero

  Scenario: Simple print of a small factbase, to XML
    Given I make a temp directory
    Then I run bin/judges with "--verbose eval simple.fb '$fb.insert.foo = 42'"
    Then I run bin/judges with "update . simple.fb"
    Then I run bin/judges with "print --format=xml --auto simple.fb"
    Then Stdout contains "printed"
    And Exit code is zero

  Scenario: Simple print of a small factbase, to XML, with a query
    Given I make a temp directory
    Then I run bin/judges with "--verbose eval simple.fb '$fb.insert.foo = 42'"
    Then I run bin/judges with "--verbose eval simple.fb '$fb.insert.foo = 43'"
    Then I run bin/judges with "update . simple.fb"
    Then I run bin/judges with "print '--query=(eq foo 43)' --auto simple.fb"
    Then Stdout contains "printed"
    And Exit code is zero
