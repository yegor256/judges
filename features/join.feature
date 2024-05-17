Feature: Join
  I want to join two factbases

  Scenario: Simple join of two small factbases
    Given I make a temp directory
    Then I have a "simple/simple_judge.rb" file with content:
    """
      return if $fb.size > 2
      n = $fb.insert
      n.kind = 'yes!'
    """
    Then I run bin/judges with "update . first.fb"
    Then I run bin/judges with "update . second.fb"
    Then I run bin/judges with "join first.fb second.fb"
    Then Stdout contains "joined"
    And Exit code is zero
