require 'new_relic/ia/metric_names'

# The iostat reader simply opens a pipe on the iostat command, listening every 15
# seconds and taking a sample for RPM.  It runs on the thread of the caller
# of the #run method.  
#
# There are implementations of the command reader for different platforms.  The
# implementations are in modules which are included into the Monitor class.
#
class NewRelic::IA::IostatReader
  include NewRelic::IA::MetricNames
  attr_reader :io_stats, :system_cpu, :user_cpu
  def initialize
    stats_engine = NewRelic::Agent.instance.stats_engine
    @io_stats    = stats_engine.get_stats(DISK_IO, false)  # Usage in MB
    @system_cpu  = stats_engine.get_stats(SYSTEM_CPU, false)  # percentage utilization
    @user_cpu    = stats_engine.get_stats(USER_CPU, false)  # percentage utilization
    
    # Open the iostat reporting every 15 seconds cumulative
    # values for disk transfers and cpu utilization
    @pipe        = IO.popen(cmd)
  end
  
  def self.log
    NewRelic::IA::CLI.log
  end
  
  def log
    self.class.log
  end
  
  case RUBY_PLATFORM
    when /darwin/
    require 'new_relic/ia/iostat_reader/osx'
    include OSX 
    when /linux/
    require 'new_relic/ia/iostat_reader/linux'
    include Linux
  else
    raise "unrecognized platform: #{RUBY_PLATFORM}"
  end
  
  def run
    init
    read_next while true
  end
end
