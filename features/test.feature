Feature: Test
  I want to test a few judges

  Scenario: Simple test of a few judges
    Given I run bin/judges with "test ./fixtures"
    Then Stdout contains "👉 Testing"
    Then Stdout contains "All 2 judge(s) and 2 tests passed"
    And Exit code is zero

  Scenario: Simple test of just one pack
    Given I run bin/judges with "test --pack guess ./fixtures"
    Then Stdout contains "All 1 judge(s) and 1 tests passed"
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
    Then Stdout contains "All 1 judge(s) and 0 tests passed"
    And Exit code is zero

  Scenario: Enable only one category
    Given I make a temp directory
    Then I have a "mypacks/good/good.rb" file with content:
    """
    n = $fb.insert
    """
    Then I have a "mypacks/good/good.yml" file with content:
    """
    ---
    category: good
    input: []
    """
    Then I have a "mypacks/bad/bad.rb" file with content:
    """
    broken$ruby$syntax
    """
    Then I have a "mypacks/bad/bad.yml" file with content:
    """
    ---
    category: bad
    """
    Then I run bin/judges with "test --enable good mypacks"
    Then Stdout contains "All 2 judge(s) and 1 tests passed"
    And Exit code is zero
    Then I run bin/judges with "test --disable bad mypacks"
    Then Stdout contains "All 2 judge(s) and 1 tests passed"
    And Exit code is zero
    Then I run bin/judges with "test --enable bad mypacks"
    Then Stdout contains "Testing mypacks/bad/bad.yml"
    And Exit code is not zero
