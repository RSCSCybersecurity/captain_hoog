Feature: Getting the gems version number printed to stdout
  In order to get the version printed out to stdout
  As developer
  I want to type in hoog --version to know about the current version

  Scenario: Getting the version printed to stdout
    Given I type in "hoog --version"
    Then I should see the current version
