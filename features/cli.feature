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
      return if $fb.size > 2
      $fb.query("(eq kind 'foo')").each do |f|
        n = $fb.insert
        n.kind = 'yes!'
      end
    """
    Then I run bin/judges with "--verbose update -o foo=1 -o bar=2 . simple.fb"
    Then Stdout contains "foo → "
    Then Stdout contains "bar → "
    Then Stdout contains "1 judges processed"
    And Exit code is zero

  Scenario: Simple test of a few judges
    Given I run bin/judges with "test ./fixtures"
    Then Stdout contains "👉 Testing"
    Then Stdout contains "judges tested successfully"
    And Exit code is zero

  Scenario: Simple test of just one pack
    Given I run bin/judges with "test --pack reward_for_good_bug ./fixtures"
    Then Stdout contains "judges tested successfully"
    And Exit code is zero

  Scenario: Simple test of no packs
    Given I run bin/judges with "test --pack absent_for_sure ./fixtures"
    Then Exit code is not zero

  Scenario: Simple trimming of a factbase
    Given I make a temp directory
    Then I have a "simple/simple_judge.rb" file with content:
    """
      return if $fb.size > 2
      $fb.insert.time = Time.now - 100 * 60 * 60 * 24
    """
    Then I run bin/judges with "--verbose update . simple.fb"
    Given I run bin/judges with "trim --days 5 simple.fb"
    Then Stdout contains "3 facts deleted"
    And Exit code is zero

  Scenario: Simple print of a small factbase
    Given I make a temp directory
    Then I have a "simple/simple_judge.rb" file with content:
    """
      return if $fb.size > 2
      n = $fb.insert
      n.kind = 'yes!'
    """
    Then I run bin/judges with "update . simple.fb"
    Then I run bin/judges with "print --format=yaml simple.fb simple.yml"
    Then Stdout contains "printed"
    And Exit code is zero

