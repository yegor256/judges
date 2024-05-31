Feature: Gem Package
  As a source code writer I want to be able to
  judgeage the Gem into .gem file

  Scenario: Gem can be judgeaged
    Given I make a temp directory
    Then I have a "execs.rb" file with content:
    """
    #!/usr/bin/env ruby
    require 'rubygems'
    spec = Gem::Specification::load('./spec.rb')
    if spec.executables.empty?
      fail 'no executables: ' + File.read('./spec.rb')
    end
    """
    When I run bash with:
    """
    cd judges
    gem build judges.gemspec
    gem specification --ruby judges-*.gem > ../spec.rb
    cd ..
    ruby execs.rb
    """
    Then Exit code is zero
