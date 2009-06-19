$:.unshift(File.dirname(__FILE__)) unless
$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
gem 'newrelic_rpm'
# You can select different newrelic.yml sections by setting the
# RUBY_ENV environment variable, similar to RAILS_ENV (which is also checked).
# Default is 'monitor'
# ENV['RUBY_ENV']  = 'production'

module NewRelic
  module EPM
    VERSION = '0.1.0'
  end
end