Feature: Test
  I want to test a few judges

  Scenario: Simple test of a few judges
    Given I run bin/judges with "test ./fixtures"
    Then Stdout contains "👉 Testing"
    Then Stdout contains "judge(s) tested successfully"
    And Exit code is zero

  Scenario: Simple test of just one pack
    Given I run bin/judges with "test --pack guess ./fixtures"
    Then Stdout contains "judge(s) tested successfully"
    And Exit code is zero

  Scenario: Simple test of no packs
    Given I run bin/judges with "test --pack absent_for_sure ./fixtures"
    Then Exit code is not zero

  Scenario: Simple test of a few judges, with a lib
    Given I make a temp directory
    Then I have a "mypacks/mypack/simple_judge.rb" file with content:
    """
      n = $fb.insert
      n.foo = $foo
    """
    Then I have a "mylib/foo.rb" file with content:
    """
      $foo = 42
    """
    Then I run bin/judges with "test --lib mylib mypacks"
    Then Stdout contains "All 1 judge(s) tested successfully"
    And Exit code is zero
