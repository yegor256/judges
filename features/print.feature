Feature: Print
  I want to print a factbase

  Scenario: Simple print of a small factbase, to YAML
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

  Scenario: Simple print of a small factbase, to JSON
    Given I make a temp directory
    Then I have a "simple/simple_judge.rb" file with content:
    """
      return if $fb.size > 2
      n = $fb.insert
      n.kind = 'yes!'
    """
    Then I run bin/judges with "update . simple.fb"
    Then I run bin/judges with "print --format=json simple.fb simple.json"
    Then Stdout contains "printed"
    And Exit code is zero

  Scenario: Simple print of a small factbase, to XML
    Given I make a temp directory
    Then I have a "simple/simple_judge.rb" file with content:
    """
      return if $fb.size > 2
      n = $fb.insert
      n.kind = 'yes!'
    """
    Then I run bin/judges with "update . simple.fb"
    Then I run bin/judges with "print --format=xml --auto simple.fb"
    Then Stdout contains "printed"
    And Exit code is zero
