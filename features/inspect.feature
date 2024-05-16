Feature: Inspect
  I want to inspect a factbase

  Scenario: Simple inspect of a small factbase
    Given I make a temp directory
    Then I have a "simple/simple_judge.rb" file with content:
    """
      return if $fb.size > 2
      n = $fb.insert
      n.kind = 'yes!'
    """
    Then I run bin/judges with "update . simple.fb"
    Then I run bin/judges with "inspect simple.fb"
    Then Stdout contains "Facts: 3"
    And Exit code is zero

