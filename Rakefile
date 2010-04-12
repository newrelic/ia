require 'rubygems'
require 'rake'
require File.dirname(__FILE__) + '/lib/new_relic/ia/version.rb'
require 'rake/testtask'

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

# See http://www.rubygems.org/read/chapter/20 
begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = GEM_NAME
    gem.summary = SUMMARY
    gem.description = DESCRIPTION
    gem.email = EMAIL
    gem.homepage = HOMEPAGE
    gem.author = AUTHOR
    gem.version = GEM_VERSION
    gem.files = FileList['Rakefile', 'README*', 'CHANGELOG', 'spec/**/*','tasks/*', 'lib/**/*'].to_a
    gem.test_files = FileList['spec/**/*.rb']
    gem.rdoc_options <<
      "--line-numbers" <<
      "--inline-source" <<
      "--title" << SUMMARY <<
      "-m" << "README.rdoc"
    
    gem.files.reject! { |fn| fn =~ /PostInstall.txt|pkg\/|rdoc\// }
    gem.extra_rdoc_files = %w[CHANGELOG LICENSE README.rdoc bin/newrelic_ia]
    gem.add_dependency 'newrelic_rpm', '>=2.10.6'
    gem.post_install_message = File.read 'PostInstall.txt'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

load "#{File.dirname(__FILE__)}/tasks/rspec.rake"

task :manifest do
  puts "Manifest task is no longer used since switching to jeweler."
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'spec/**/*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.title = SUMMARY
  rdoc.main = "README.rdoc"
  rdoc.rdoc_files << 'LICENSE' << 'README*' << 'CHANGELOG' << 'lib/**/*.rb' << 'bin/**/*'
  rdoc.inline_source = true
end

begin
  require 'sdoc_helpers'
rescue LoadError
  puts "sdoc support not enabled. Please gem install sdoc-helpers."
end
