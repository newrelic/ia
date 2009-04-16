#!/usr/bin/ruby
require 'rubygems'
require 'newrelic_rpm'

class SystemSampler < NewRelic::Agent::Sampler
  case RUBY_PLATFORM 
  when /darwin/
    require 'osx'
    include OSX
  when /linux/
    require 'linux'
    include 'linux'
  else
    STDERR.puts "warning: unsupported platform #{RUBY_PLATFORM}"
    exit -1
  end

  def initialize
    super 'system_stats'
  end

  def page_stats
    @page_stats ||= stats_engine.get_stats("System/Pages/Free/Count", false)
  end
  
  def cpu_stats
    @cpu_stats ||= stats_engine.get_stats("System/CPU/Utilization", false)
  end
  
  def poll
    page_stats.record_data_point 
    cpu_stats.record_data_point cpu
  end
end

NewRelic::Agent.manual_start

NewRelic::Agent.instance.stats_engine.add_sampler SystemSampler.new

sleep


