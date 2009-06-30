require 'rubygems'
require 'echoe'
%w[rake rake/clean fileutils rubigen].each { |f| require f }
require File.dirname(__FILE__) + '/lib/newrelic_ia'

GEM_NAME = "newrelic_ia"
GEM_VERSION = NewRelic::IA::VERSION
AUTHOR = "Bill Kayser"
EMAIL = "bkayser@newrelic.com"
HOMEPAGE = "http://www.newrelic.com"
SUMMARY = "New Relic Gem for gathering system metrics"
DESCRIPTION = <<EOF
The New Relic Infrastructure Agent (IA) collects system metrics and transmits
them to the RPM server where they can be viewed with custom dashboards.
EOF

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
Echoe.new('newrelic_ia', NewRelic::IA::VERSION) do |p|
  p.author = AUTHOR
  p.email = EMAIL
  p.summary = SUMMARY
  p.description = DESCRIPTION
  p.url = HOMEPAGE
  p.project = 'newrelic'
  p.need_tar_gz = false
  p.need_gem = true
  p.runtime_dependencies = [
     ['newrelic_rpm','>= 2.9.2'],
  ]
  p.development_dependencies = [
    #['newgem', ">= #{::Newgem::VERSION}"]
  ]
  p.bin_files = 'bin/newrelic_ia'
  p.test_pattern = "spec/*.rb"
  p.install_message = File.read('PostInstall.txt')
  p.ignore_pattern = %w[PostInstall.txt newrelic.yml]
  p.clean_pattern |= %w[**/.DS_Store tmp *.log]
#  path = (p.rubyforge_name == p.name) ? p.rubyforge_name : "\#{p.rubyforge_name}/\#{p.name}"
end

Dir['tasks/**/*.rake'].each { |t| load t }

