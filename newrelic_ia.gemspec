# -*- encoding: utf-8 -*-
require File.expand_path('../lib/new_relic/ia/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Bill Kayser"]
  gem.email         = ["bkayser@newrelic.com"]
  gem.description   = %q{The New Relic Infrastructure Agent (IA) collects system metrics and transmits
them to the RPM server where they can be viewed with custom dashboards.}
  gem.summary       = %q{New Relic Gem for gathering system metrics}
  gem.homepage      = "http://www.newrelic.com"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "newrelic_ia"
  gem.require_paths = ["lib"]
  gem.version       = NewRelic::IA::VERSION
  gem.extra_rdoc_files = %w[CHANGELOG LICENSE README.rdoc bin/newrelic_ia]
  gem.post_install_message = %q{For more information refer to http://support.newrelic.com or
say 'newrelic' at #newrelic on freenode IRC.}

  gem.add_dependency 'newrelic_rpm', '>=3.1.0'
  gem.add_development_dependency 'rspec', '>= 2.0.0'
  gem.add_development_dependency 'mocha', '>= 0'
end

