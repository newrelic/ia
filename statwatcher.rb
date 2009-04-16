#!/usr/bin/ruby
require 'rubygems'
require 'newrelic_rpm'

# You can select different newrelic.yml sections by setting the
# RUBY_ENV environment variable, similar to RAILS_ENV (which is also checked).
# Default is 'monitor'
# ENV['RUBY_ENV'] = 'production'

class StatWatcher

  attr_reader :io_stats, :system_cpu, :user_cpu

  def initialize
    stats_engine         = NewRelic::Agent.instance.stats_engine
    @io_stats            = stats_engine.get_stats("System/Resource/DiskIO/mb", false)  # Usage in MB
    @system_cpu          = stats_engine.get_stats("System/User CPU/percent", false)  # percentage utilization
    @user_cpu            = stats_engine.get_stats("System/System CPU/percent", false)  # percentage utilization

    # Open the iostat reporting every 15 seconds cumulative
    # values for disk transfers and cpu utilization
    @pipe                = IO.popen(cmd)
    init
  end
  
  module OSX
    def cmd; "iostat -dCI 2"  ; end
    def init
      # get the first header
      header               = @pipe.gets
      @disk_count          = header.split("\s").size - 1
      @pipe.gets # skip the second header
      @pipe.gets # skip the first line, uptime summary
    end
    def run
      # The running total of MB transferred
      running_total        = 0
      while line = @pipe.gets
        next if line =~ /cpu|id/ # skip if it's a header line
        values             = line.split("\s")
        current_total      = 0.0
        # Iterate over each disk's stats
        @disk_count.times do | disk_number |
          values.shift
          values.shift
          current_total += values.shift.to_f
        end
        io_stats.record_data_point current_total - running_total
        running_total      = current_total
        # Get the CPU stats
        user, system, idle = values.map { |v| v.to_f }
        user_cpu.record_data_point(user / 100.0)
        system_cpu.record_data_point(system / 100.0)
      end
    end
  end
  module Linux
    def cmd; "iostat -dcm 15"  ; end
    def init
      # read to "Device:"
      begin 
        line = @pipe.gets
      end until line =~ /^Device:/
      
      # do it again to skip the summary part:
      begin 
        line = @pipe.gets
      end until line =~ /^Device:/

      # read to first blank line
      @disk_count = 0
      line = @pipe.gets
      until line =~ /^\s*$/
        @disk_count += 1
        line = @pipe.gets
      end
    end
    def run
      # The running total of MB transferred
      running_total        = 0
      while line = @pipe.gets
        next if line.chomp =~ /^$|avg-cpu/ # skip if it's a header line
        # Get the CPU stats
        values             = line.split("\s")
        user, nice, system = values.map { |v| v.to_f }
        user_cpu.record_data_point(user / 100.0)
        system_cpu.record_data_point(system / 100.0)
        # skip two lines
        @pipe.gets
        @pipe.gets

        current_total      = 0.0
        # Iterate over each disk's stats
        @disk_count.times do | disk_number |
          values = @pipe.gets.split("\s")
          current_total += values[5].to_f + values[6].to_f
        end
        io_stats.record_data_point current_total - running_total
        running_total      = current_total
      end
    end
  end

  case RUBY_PLATFORM
  when /darwin/
    include OSX 
  when /linux/
    include Linux
  else
    raise "unrecognized platform: #{RUBY_PLATFORM}"
  end
end

NewRelic::Agent.manual_start 

StatWatcher.new.run
