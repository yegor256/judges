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
    Given I make a temp directory
    Then I have a "simple/simple_judge.rb" file with content:
    """
      $fb.query("(eq kind 'foo')").each do |f|
        n = $fb.insert
        n.kind = 'yes!'
      end
    """
    Then I run bin/judges with "update . simple.fb"
    Then Stdout contains "1 judges processed"
    And Exit code is zero

  Scenario: Simple test of a few judges
    Given I run bin/judges with "test ./fixtures"
    Then Stdout contains "judges tested"
    And Exit code is zero

  Scenario: Simple print of a small factbase
    Given I make a temp directory
    Then I have a "simple/simple_judge.rb" file with content:
    """
      n = $fb.insert
      n.kind = 'yes!'
    """
    Then I run bin/judges with "update . simple.fb"
    Then I run bin/judges with "print --format=yaml simple.fb simple.yml"
    Then Stdout contains "printed"
    And Exit code is zero

