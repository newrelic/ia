module NewRelic::IA::IostatReader::OSX
  def cmd; "iostat -dCI 15"  ; end
  BYTES_PER_MB = 1048576
  def init
    # get the first header
    header               = @pipe.gets
    @disk_count          = header.split("\s").size - 1
    @pipe.gets # skip the second header
    @pipe.gets # skip the first line, uptime summary
    @running_total        = 0
  end
  
  def read_next
    # The running total of MB transferred
    line = @pipe.gets.chomp while line.nil? || line =~ /cpu|id/ # skip if it's a header line
    values             = line.split("\s")
    current_total      = 0.0
    # Iterate over each disk's stats
    @disk_count.times do | disk_number |
      values.shift
      values.shift
      v = values.shift.to_f
      current_total += v
    end
    data_point = current_total - @running_total
    log.debug "Disk usage: #{data_point} mb (#{@running_total})"
    io_stats.record_data_point(data_point * BYTES_PER_MB)
    @running_total = current_total
    # Get the CPU stats
    user, system, idle = values.map { |v| v.to_f }
    log.debug "CPU #{user}% (user), #{system}% (system)"
    user_cpu.record_data_point(user)
    system_cpu.record_data_point(system)
  end
end
