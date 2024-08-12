Feature: Test
  I want to test a few judges

  Scenario: Simple test of a few judges
    Given I run bin/judges with "test ./fixtures"
    Then Stdout contains "👉 Testing"
    Then Stdout contains "All 2 judge(s) and 2 tests passed"
    And Exit code is zero

  Scenario: Simple test of just one judge
    Given I run bin/judges with "test --judge guess ./fixtures"
    Then Stdout contains "All 1 judge(s) and 1 tests passed"
    And Exit code is zero

  Scenario: Simple test of no judges
    Given I run bin/judges with "test --judge absent_for_sure ./fixtures"
    Then Exit code is zero

  Scenario: Simple test of no judges at all
    Given I make a temp directory
    Given I run bin/judges with "test ."
    Then Exit code is not zero

  Scenario: Simple test of no judges at all
    Given I make a temp directory
    Given I run bin/judges with "test --judge some ."
    Then Exit code is not zero

  Scenario: Simple test of a few judges, with a lib
    Given I make a temp directory
    Then I have a "myjudges/good/good.rb" file with content:
    """
      $valve.enter('boom', 'some reason') do
        n = $fb.insert
        n.foo = $foo
      end
    """
    Then I have a "myjudges/good/good.yml" file with content:
    """
    ---
    category: good
    input: []
    """
    Then I have a "mylib/foo.rb" file with content:
    """
      $foo = 42
    """
    Then I run bin/judges with "test --lib mylib myjudges"
    Then Stdout contains "All 1 judge(s) and 1 tests passed"
    And Exit code is zero

  Scenario: Simple test with many runs
    Given I make a temp directory
    Then I have a "foo/foo.rb" file with content:
    """
      n = $fb.insert
      n.foo = $fb.size
    """
    Then I have a "foo/good.yml" file with content:
    """
    ---
    runs: 5
    input: []
    expected:
      - /fb[count(f)=5]
    """
    Then I run bin/judges with "test ."
    Then Stdout contains "All 1 judge(s) and 1 tests passed"
    And Exit code is zero

  Scenario: Simple test with many runs and many asserts
    Given I make a temp directory
    Then I have a "foo/foo.rb" file with content:
    """
      n = $fb.insert
      n.foo = $fb.size
    """
    Then I have a "foo/good.yml" file with content:
    """
    ---
    runs: 5
    input: []
    assert_once: false
    expected:
      - /fb/f[foo = 1]
    """
    Then I run bin/judges with "test ."
    Then Stdout contains "All 1 judge(s) and 1 tests passed"
    And Exit code is zero

  Scenario: Enable only one category
    Given I make a temp directory
    Then I have a "mine/good/good.rb" file with content:
    """
    n = $fb.insert
    """
    Then I have a "mine/good/good.yml" file with content:
    """
    ---
    category: good
    input: []
    """
    Then I have a "mine/bad/bad.rb" file with content:
    """
    broken$ruby$syntax
    """
    Then I have a "mine/bad/bad.yml" file with content:
    """
    ---
    category: bad
    """
    Then I run bin/judges with "test --enable good mine"
    Then Stdout contains "All 2 judge(s) and 1 tests passed"
    And Exit code is zero
    Then I run bin/judges with "test --disable bad mine"
    Then Stdout contains "All 2 judge(s) and 1 tests passed"
    And Exit code is zero
    Then I run bin/judges with "test --enable bad mine"
    Then Stdout contains "Testing mine/bad/bad.yml"
    And Exit code is not zero

  Scenario: Test with a pre-condition
    Given I make a temp directory
    Then I have a "mine/first/first.rb" file with content:
    """
    n = $fb.insert
    n.foo = 42
    """
    Then I have a "mine/second/second.rb" file with content:
    """
    n = $fb.insert
    n.foo = 55
    """
    Then I have a "mine/second/second.yml" file with content:
    """
    ---
    before:
      - first
    expected:
      - /fb[count(f)=2]
    """
    Then I run bin/judges with "test mine"
    And Exit code is zero

  Scenario: Test with a post-assert
    Given I make a temp directory
    Then I have a "mine/foo/foo.rb" file with content:
    """
    n = $fb.insert
    n.foo = 42
    """
    Then I have a "mine/foo/assert.rb" file with content:
    """
    raise unless $fb.size == 1
    """
    Then I have a "mine/foo/simple.yml" file with content:
    """
    ---
    expected:
      - /fb[count(f)=1]
    after:
      - assert.rb
    """
    Then I run bin/judges with "test mine"
    And Exit code is zero

  Scenario: Test with exception
    Given I make a temp directory
    Then I have a "mine/foo/foo.rb" file with content:
    """
    raise 'this is a joke'
    """
    Then I have a "mine/foo/simple.yml" file with content:
    """
    ---
    expected_failure:
      - a joke
    """
    Then I run bin/judges with "test mine"
    And Exit code is zero
