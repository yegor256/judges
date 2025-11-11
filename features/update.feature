# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

Feature: Update
  I want to run a few judges over a factbase

  Scenario: Simple run of a few judges
    Given I make a temp directory
    Then I have a "simple/simple.rb" file with content:
    """
      n = $fb.insert
      n.kind = 'yes!'
    """
    Then I run bin/judges with "--verbose --hello update --quiet -o foo=1 -o bar=2 --max-cycles 3 . simple.fb"
    Then Stdout contains "FOO → "
    Then Stdout contains "BAR → "
    Then Stdout contains "1 judge(s) processed"
    Then Stdout contains "Update completed in 3 cycle(s), did 3i/0d/3a"
    And Exit code is zero

  Scenario: Generate a summary fact, with errors
    Given I make a temp directory
    Then I have a "buggy/buggy.rb" file with content: "this is an intentional bug"
    Then I run bin/judges with "update --quiet --summary=append --max-cycles 1 . simple.fb"
    Then Exit code is zero
    Then I run bin/judges with "inspect simple.fb"
    Then Stdout contains "Facts: 1"
    And Exit code is zero

  Scenario: Append to existing summary fact, with errors
    Given I make a temp directory
    Then I have a "buggy/buggy.rb" file with content: "this is an intentional bug"
    Then I run bin/judges with "update --quiet --summary=append --max-cycles 1 . simple.fb"
    Then Exit code is zero
    Then Stdout contains "Summary fact not found"
    Then I run bin/judges with "update --quiet --summary=append --max-cycles 1 . simple.fb"
    Then I run bin/judges with "inspect simple.fb"
    Then Stdout contains "Summary fact found"
    Then Stdout contains "errors:"
    And Exit code is zero

  Scenario: Delete a previous summary fact and create new one
    Given I make a temp directory
    Then I have a "buggy/buggy.rb" file with content: "this is an intentional bug"
    Then I run bin/judges with "update --quiet --summary=add --max-cycles 1 . simple.fb"
    Then Exit code is zero
    Then Stdout contains "Summary fact added"
    Then I run bin/judges with "update --quiet --summary=add --max-cycles 1 . simple.fb"
    Then Exit code is zero
    And Stdout contains "Summary fact deleted"

  Scenario: Skips the judge on lifetime running out
    Given I make a temp directory
    Then I have a "first/first.rb" file with content:
    """
      n = $fb.insert
      n.type = 'first'
      sleep 1.5
    """
    Then I have a "second/second.rb" file with content:
    """
      n = $fb.insert
      n.type = 'second'
    """
    Then I run bin/judges with "--verbose update --quiet --lifetime 3 --timeout 2 --max-cycles 5 . simple.fb"
    Then Stdout contains "Update completed in 2 cycle(s), did 3i/0d/3a"
    And Exit code is zero

  Scenario: Use options from a file
    Given I make a temp directory
    Then I have a "simple/simple.rb" file with content:
    """
      n.kind.foo = $options.a1
    """
    Then I have a "opts.txt" file with content:
    """
      a1 = test
      a2 = another test
    """
    Then I run bin/judges with "--verbose update --quiet --options-file opts.txt . simple.fb"
    Then Stdout contains "A1 → "
    Then Stdout contains "A2 → "
    Then Stdout contains "1 judge(s) processed"
    Then Stdout contains "Update completed"
    And Exit code is zero

  Scenario: Simple run with a timeout for a judge
    Given I make a temp directory
    Then I have a "slow/slow.rb" file with content:
    """
      sleep(10)
      $fb.insert.foo = 1
    """
    Then I run bin/judges with "--verbose update --timeout 1 --quiet . foo.fb"
    Then Stdout contains "execution expired"
    Then Stdout contains "1 judge(s) processed"
    Then Stdout contains "Update completed in 1 cycle(s), did nothing"
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
    Then Stdout contains "Update completed in 1 cycle(s)"
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

  Scenario: Simple demote of a single judge
    Given I make a temp directory
    Then I have a "alpha/alpha.rb" file with content:
    """
      $fb.insert.name = 'alpha'
    """
    Then I have a "beta/beta.rb" file with content:
    """
      $fb.insert.name = 'beta'
    """
    Then I have a "gamma/gamma.rb" file with content:
    """
      $fb.insert.name = 'gamma'
    """
    Then I run bin/judges with "--verbose update --quiet --max-cycles 1 --demote beta . demote.fb"
    Then Stdout contains "Running alpha"
    Then Stdout contains "Running gamma"
    Then Stdout contains "Running beta"
    Then Stdout contains "3 judge(s) processed"
    And Exit code is zero

  Scenario: Demote multiple judges
    Given I make a temp directory
    Then I have a "first/first.rb" file with content:
    """
      $fb.insert.order = 'first'
    """
    Then I have a "second/second.rb" file with content:
    """
      $fb.insert.order = 'second'
    """
    Then I have a "third/third.rb" file with content:
    """
      $fb.insert.order = 'third'
    """
    Then I have a "fourth/fourth.rb" file with content:
    """
      $fb.insert.order = 'fourth'
    """
    Then I run bin/judges with "--verbose update --quiet --max-cycles 1 --demote second --demote fourth . multi.fb"
    Then Stdout contains "Running first"
    Then Stdout contains "Running third"
    Then Stdout contains "Running second"
    Then Stdout contains "Running fourth"
    Then Stdout contains "4 judge(s) processed"
    And Exit code is zero

  Scenario: Combine boost and demote
    Given I make a temp directory
    Then I have a "priority/priority.rb" file with content:
    """
      $fb.insert.type = 'priority'
    """
    Then I have a "normal/normal.rb" file with content:
    """
      $fb.insert.type = 'normal'
    """
    Then I have a "delayed/delayed.rb" file with content:
    """
      $fb.insert.type = 'delayed'
    """
    Then I run bin/judges with "--verbose update --quiet --max-cycles 1 --boost priority --demote delayed . combined.fb"
    Then Stdout contains "Running priority"
    Then Stdout contains "Running normal"
    Then Stdout contains "Running delayed"
    Then Stdout contains "3 judge(s) processed"
    And Exit code is zero
