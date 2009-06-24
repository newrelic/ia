# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{newrelic_ia}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bill Kayser"]
  s.date = %q{2009-06-23}
  s.default_executable = %q{newrelic_ia}
  s.description = %q{Gem for sending system statistics to New Relic RPM}
  s.email = %q{bkayser@newrelic.com}
  s.executables = ["newrelic_ia"]
  s.extra_rdoc_files = ["bin/newrelic_ia", "CHANGELOG", "lib/new_relic/ia/cli.rb", "lib/new_relic/ia/disk_sampler.rb", "lib/new_relic/ia/iostat_reader/linux.rb", "lib/new_relic/ia/iostat_reader/osx.rb", "lib/new_relic/ia/iostat_reader.rb", "lib/new_relic/ia/metric_names.rb", "lib/new_relic/ia/newrelic.yml", "lib/newrelic_ia.rb", "README.rdoc", "tasks/rspec.rake"]
  s.files = ["bin/newrelic_ia", "CHANGELOG", "lib/new_relic/ia/cli.rb", "lib/new_relic/ia/disk_sampler.rb", "lib/new_relic/ia/iostat_reader/linux.rb", "lib/new_relic/ia/iostat_reader/osx.rb", "lib/new_relic/ia/iostat_reader.rb", "lib/new_relic/ia/metric_names.rb", "lib/new_relic/ia/newrelic.yml", "lib/newrelic_ia.rb", "Manifest", "newrelic_ia.gemspec", "Rakefile", "README.rdoc", "spec/cli_spec.rb", "spec/disk_sampler_spec.rb", "spec/iostat-linux.out", "spec/iostat-osx.out", "spec/iostat_reader_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "tasks/rspec.rake"]
  s.has_rdoc = true
  s.homepage = %q{}
  s.post_install_message = %q{
For more information refer to http://support.newrelic.com or
say 'newrelic' at #newrelic on freenode IRC.
}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Newrelic_ia", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{newrelic_ia}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Gem for sending system statistics to New Relic RPM}
  s.test_files = ["spec/cli_spec.rb", "spec/disk_sampler_spec.rb", "spec/iostat_reader_spec.rb", "spec/spec_helper.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<newrelic_rpm>, [">= 2.9.2"])
    else
      s.add_dependency(%q<newrelic_rpm>, [">= 2.9.2"])
    end
  else
    s.add_dependency(%q<newrelic_rpm>, [">= 2.9.2"])
  end
end
