#!/usr/bin/ruby

# The iostat reader simply opens a pipe on the iostat command, listening every 15
# seconds and taking a sample for RPM.  It runs on the thread of the caller
# of the #run method.  
#
# There are implementations of the command reader for different platforms.  The
# implementations are in modules which are included into the Monitor class.
#
class NewRelic::EPM::IostatReader
  
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
  
  def self.log
    NewRelic::EPM::CLI.log
  end
  
  def log
    self.class.log
  end
  
  case RUBY_PLATFORM
    when /darwin/
    require 'new_relic/epm/iostat_reader/osx'
    include OSX 
    when /linux/
    require 'new_relic/epm/iostat_reader/linux'
    include Linux
  else
    raise "unrecognized platform: #{RUBY_PLATFORM}"
  end
  
  def run
    read_next while true
  end
end
