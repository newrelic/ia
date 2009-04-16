
module IostatReader::Linux
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
  def run
    while line = @pipe.gets
      next if line.chomp =~ /^$|avg-cpu/ # skip if it's a header line
      # Get the CPU stats
      values             = line.split("\s")
      user, nice, system = values.map { |v| v.to_f }
      log.info "CPU #{user}% (user), #{system}% (system)"
      user_cpu.record_data_point(user / 100.0)
      system_cpu.record_data_point(system / 100.0)
      # skip two lines
      @pipe.gets
      @pipe.gets
      # Iterate over each disk's stats
      @disk_count.times do | disk_number |
        values = @pipe.gets.split("\s")
        usage = values[5].to_f + values[6].to_f
        log.info "Disk #{values[0]}: #{usage}kb"
        io_stats.record_data_point usage
      end
    end
  end
end

