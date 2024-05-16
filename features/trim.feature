Feature: Trim
  I want to trim a factbase

  Scenario: Simple trimming of a factbase
    Given I make a temp directory
    Then I have a "simple/simple_judge.rb" file with content:
    """
      return if $fb.size > 2
      $fb.insert.time = Time.now - 100 * 60 * 60 * 24
    """
    Then I run bin/judges with "--verbose update . simple.fb"
    Given I run bin/judges with "trim --days 5 simple.fb"
    Then Stdout contains "3 fact(s) deleted"
    And Exit code is zero
