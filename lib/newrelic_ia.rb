# Make sure the code is on the path, and load the version file.

$:.unshift(File.expand_path(File.dirname(__FILE__))) unless
$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# You can select different newrelic.yml sections by setting the
# RUBY_ENV environment variable, similar to RAILS_ENV (which is also checked).
# Default is 'monitor'
# ENV['RUBY_ENV']  = 'production'

require 'new_relic/ia/version.rb'

