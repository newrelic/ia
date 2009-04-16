#!/usr/bin/ruby
require 'rubygems'
require 'newrelic_rpm'
require 'logger'

# You can select different newrelic.yml sections by setting the
# RUBY_ENV environment variable, similar to RAILS_ENV (which is also checked).
# Default is 'monitor'
# ENV['RUBY_ENV']  = 'production'

module IostatReader
require 'iostat_reader/osx'
require 'iostat_reader/linux'

  @log = Logger.new(STDOUT)
  @log.level = Logger::INFO
  
  def self.log
    @log
  end

  class Monitor
  attr_reader :io_stats, :system_cpu, :user_cpu
    def initialize
      stats_engine = NewRelic::Agent.instance.stats_engine
      @io_stats    = stats_engine.get_stats("System/Resource/DiskIO/kb", false)  # Usage in MB
      @system_cpu  = stats_engine.get_stats("System/User CPU/percent", false)  # percentage utilization
      @user_cpu    = stats_engine.get_stats("System/System CPU/percent", false)  # percentage utilization

      # Open the iostat reporting every 15 seconds cumulative
      # values for disk transfers and cpu utilization
      @pipe        = IO.popen(cmd)
      init
    end
    def log
      IostatReader.log
    end
    case RUBY_PLATFORM
    when /darwin/
      include IostatReader::OSX 
    when /linux/
      include IostatReader::Linux
    else
      raise "unrecognized platform: #{RUBY_PLATFORM}"
    end
  end
end

NewRelic::Agent.manual_start 

IostatReader.log.info "Starting monitor."
IostatReader::Monitor.new.run


