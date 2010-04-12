begin
  require 'spec'
  require 'newrelic_ia'
  require 'newrelic_rpm'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rspec'
  require 'spec'
  require 'newrelic_ia'
  require 'newrelic_rpm'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'new_relic/ia/cli'
module NewRelic; TEST = true; end unless defined? NewRelic::TEST
NewRelic::IA::CLI.level = Logger::ERROR

Spec::Runner.configure do |config|
  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  #config.fixture_path = RAILS_ROOT + '/test/fixtures/'

  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  config.mock_with :mocha

  # == Notes
  # 
  # For more information take a look at Spec::Example::Configuration and Spec::Runner
end
