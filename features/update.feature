Feature: Update
  I want to run a few judges over a factbase

  Scenario: Simple run of a few judges
    Given I make a temp directory
    Then I have a "simple/simple.rb" file with content:
    """
      n = $fb.insert
      n.kind = 'yes!'
    """
    Then I run bin/judges with "--verbose update --quiet -o foo=1 -o bar=2 --max-cycles 3 . simple.fb"
    Then Stdout contains "FOO → "
    Then Stdout contains "BAR → "
    Then Stdout contains "1 judge(s) processed"
    Then Stdout contains "Update finished in 3 cycle(s), modified 3/0 fact(s)"
    And Exit code is zero

  Scenario: Simple run with a timeout for a judge
    Given I make a temp directory
    Then I have a "slow/slow.rb" file with content:
    """
      sleep(10)
      $fb.insert.foo = 1
    """
    Then I run bin/judges with "--verbose update --timeout 1 --quiet . foo.fb"
    Then Stdout contains "timed out"
    Then Stdout contains "1 judge(s) processed"
    Then Stdout contains "Update finished in 1 cycle(s), modified 0/0 fact(s)"
    And Exit code is zero

  Scenario: Simple run of a few judges, with a lib
    Given I make a temp directory
    Then I have a "mine/judge1/judge1.rb" file with content:
    """
      n = $fb.insert
      n.foo = $foo
    """
    Then I have a "mylib/foo.rb" file with content:
    """
      $foo = 42
    """
    Then I run bin/judges with "update --lib mylib --max-cycles 1 mine simple.fb"
    Then Stdout contains "1 judge(s) processed"
    Then Stdout contains "Update finished in 1 cycle(s)"
    And Exit code is zero

  Scenario: The update fails when a bug in a judge
    Given I make a temp directory
    Then I have a "mine/broken/broken.rb" file with content:
    """
    a < 1
    """
    Then I run bin/judges with "update mine simple.fb"
    Then Stdout contains "Failed to update correctly"
    And Exit code is not zero

  Scenario: The update fails when a broken Ruby syntax in a judge
    Given I make a temp directory
    Then I have a "mine/broken/broken.rb" file with content:
    """
    invalid$ruby$syntax$here
    """
    Then I run bin/judges with "update mine simple.fb"
    Then Stdout contains "Failed to update correctly"
    And Exit code is not zero

  Scenario: Avoid duplicate insert on error in the middle
    Given I make a temp directory
    Then I have a "mine/foo/foo.rb" file with content:
    """
    return unless $fb.query('(eq foo 42)').each.to_a.empty?
    f = $fb.insert
    f.foo = 42
    raise 'intentional'
    """
    Then I run bin/judges with "update --quiet --max-cycles=3 mine simple.fb"
    And Exit code is zero
    Then I run bin/judges with "inspect simple.fb"
    Then Stdout contains "Facts: 1"
