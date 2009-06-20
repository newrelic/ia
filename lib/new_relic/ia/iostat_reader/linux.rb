
module NewRelic::IA::IostatReader::Linux
  def cmd; "iostat -dck 15"  ; end
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
  def read_next
    # read up to the next header
    begin 
      line = @pipe.gets.chomp
    end until line =~ /avg-cpu/
    line = @pipe.gets
    # Get the CPU stats
    values             = line.strip.split /\s+/
    user, nice, system = values.map { |v| v.to_f }
    log.debug "CPU #{user}% (user), #{system}% (system)"
    user_cpu.record_data_point user
    system_cpu.record_data_point system
    # skip two lines
    @pipe.gets
    @pipe.gets
    # Iterate over each disk's stats
    @disk_count.times do | disk_number |
      line = @pipe.gets.chomp.strip
      values = line.split /\s+/
      usage = values[5].to_f + values[6].to_f
      log.debug "Disk #{values[0]}: #{usage}kb (processed '#{values.inspect}'"
      io_stats.record_data_point usage
    end
  end
end
