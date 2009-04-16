module IostatReader::OSX
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
        v = values.shift.to_f
        current_total += v
      end
      log.info "Disk usage: #{current_total - running_total}"
      io_stats.record_data_point current_total - running_total
      running_total      = current_total
      # Get the CPU stats
      user, system, idle = values.map { |v| v.to_f }
      log.info "CPU #{user}% (user), #{system}% (system)"
      user_cpu.record_data_point(user / 100.0)
      system_cpu.record_data_point(system / 100.0)
    end
  end
end