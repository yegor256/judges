Feature: Update
  I want to run a few judges over a factbase

  Scenario: Simple run of a few judges
    Given I make a temp directory
    Then I have a "simple/simple_judge.rb" file with content:
    """
      n = $fb.insert
      n.kind = 'yes!'
    """
    Then I run bin/judges with "--verbose update --quiet -o foo=1 -o bar=2 --max-cycles 3 . simple.fb"
    Then Stdout contains "foo → "
    Then Stdout contains "bar → "
    Then Stdout contains "1 judge(s) processed"
    Then Stdout contains "Update finished: 3 cycles"
    And Exit code is zero

  Scenario: Simple run of a few judges, with a lib
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
    Then I run bin/judges with "update --lib mylib --max-cycles 1 mypacks simple.fb"
    Then Stdout contains "1 judge(s) processed"
    Then Stdout contains "Update finished: 1 cycles"
    And Exit code is zero
