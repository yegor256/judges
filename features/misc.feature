Feature: Misc
  I want to get some meta info

  Scenario: Help can be printed
    When I run bin/judges with "-h"
    Then Exit code is zero
    And Stdout contains "--help"

  Scenario: Version can be printed
    When I run bin/judges with "--version"
    Then Exit code is zero
