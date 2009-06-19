require 'rubygems'
require 'echoe'
%w[rake rake/clean fileutils newgem rubigen].each { |f| require f }
require File.dirname(__FILE__) + '/lib/newrelic_ia'

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
Echoe.new('newrelic_ia', NewRelic::IA::VERSION) do |p|
  p.author ='Bill Kayser'
  p.email = 'bkayser@newrelic.com'
  p.summary = 'Gem for sending system statistics to New Relic RPM'
  p.rubyforge_name       = p.name 
  p.runtime_dependencies = [
     ['newrelic_rpm','>= 2.9.2'],
  ]
  p.development_dependencies = [
    ['newgem', ">= #{::Newgem::VERSION}"]
  ]
  p.test_pattern = "spec/*.rb"
  p.ignore_pattern = "newrelic.yml"
  p.executable_pattern = "bin/newrelic_ia"
  # p.description =
  # p.url =
  p.install_message = File.read('PostInstall.txt')
  p.clean_pattern |= %w[**/.DS_Store tmp *.log]
  path = (p.rubyforge_name == p.name) ? p.rubyforge_name : "\#{p.rubyforge_name}/\#{p.name}"
end

Dir['tasks/**/*.rake'].each { |t| load t }

