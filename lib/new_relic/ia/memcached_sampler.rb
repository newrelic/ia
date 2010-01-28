require 'new_relic/agent'
require 'new_relic/ia/metric_names'
require 'socket'
require 'active_support'

# This is some demo code which shows how you might install your
# own sampler.  This one theoretically monitors cpu.

class NewRelic::IA::MemcachedSampler < NewRelic::Agent::Sampler
  include NewRelic::IA::MetricNames
  case RUBY_PLATFORM 
  when /darwin/
    # Do some special stuff...
  when /linux/
    # Do some special stuff...
  else
    NewRelic::IA::CLI.log.warn "unsupported platform #{RUBY_PLATFORM}"
  end

  def initialize
    @memcached_nodes = []
    stats_engine = NewRelic::Agent.instance.stats_engine
    # file with a list of mecached nodes. each line have hostname:port
     
    File.open("memcached-nodes.txt","r").each do |line|
      NewRelic::Agent.instance.log.info "memcached host #{line}"
      @memcached_nodes.push line.chomp
    end
  end

  # This gets called every 10 seconds, or once a minute depending
  # on how you add the sampler to the stats engine.
  # It pings each host in the array 'memcached_nodes'
  def poll
    @memcached_nodes.each do | hostname_port |
      issue_stats hostname_port
    end
  end
  
  #TODO send stats for down nodes
  def issue_stats(hostname_port)
    NewRelic::Agent.instance.log.debug  "hostname #{hostname_port}"
    begin
      split = hostname_port.split(':', 2)
      hostname = split.first
      port = split.last
      
      socket = TCPSocket.open(hostname, port)
      socket.send("stats\r\n", 0)
      
      # TODO UDP or use memcached gem to use udp first and fallback to tcp
      # socket = UDPSocket.open
      # socket.connect(@host, @port)
      # socket.send("stats\r\n", 0, 'localhost', '11211')
      

      statistics = []
      loop do
        data = socket.recv(4096)
        if !data || data.length == 0
          break
        end
        statistics << data
        if statistics.join.split(/\n/)[-1] =~ /END/
          break
        end
      end
    rescue IOError, SystemCallError => e
      NewRelic::Agent.instance.log.info "Unable to connect to memcached node at #{hostname_port}"
      unless e.instance_of? IgnoreSilentlyException
        NewRelic::Agent.instance.log.error e.message
        NewRelic::Agent.instance.log.debug e.backtrace.join("\n")
      end
      return
    ensure
      socket.close if socket
    end
      
      
    #if statistics.join.split(/\n/)[-1] =~ /END/
    sss = statistics.join.chomp("\r\nEND\r\n").split(/\s+/)
    if sss.size % 3 != 0
      NewRelic::Agent.instance.log.error "Unexcpected stats output from #{hostname_port}: #{statistics}"
      break
    end
    triplets = sss.in_groups_of(3)
    stats = Hash.new
    triplets.each do |triplet| 
      NewRelic::Agent.instance.log.debug "#{triplet[1].to_sym} = #{triplet[2]}"
      stats[triplet[1].to_sym] = triplet[2]
    end
    
    # pid = 21355
    # uptime = 2089
    # time = 1264673782
    # version = 1.2.8
    # pointer_size = 64
    # rusage_user = 0.020996
    # rusage_system = 0.020996
    # curr_items = 277
    # total_items = 356
    # bytes = 544955
    # curr_connections = 14
    # total_connections = 15
    # connection_structures = 15
    # cmd_flush = 0
    # cmd_get = 549
    # cmd_set = 356
    # get_hits = 185
    # get_misses = 364
    # evictions = 0
    # bytes_read = 703195
    # bytes_written = 344345
    # limit_maxbytes = 1048576000
    # threads = 5
    # accepting_conns = 1
    # listen_disabled_num = 0
    
    int_values = [:pid, :uptime, :time, :curr_items, :total_items, :bytes, :curr_connections, :total_connections, :connection_structures,
      :cmd_flush, :cmd_get, :cmd_set, :get_hits, :get_misses, :evictions, :bytes_read, :bytes_written, :limit_maxbytes, :threads, :accepting_conns, :listen_disabled_num]
    #string_values = [:version]
    float_values = [:rusage_user, :rusage_system]
    
    int_values.each do |stat| 
      NewRelic::Agent.instance.log.debug "recording /System/Memcached/#{hostname_port}/#{stat.to_s.titleize} = #{stats[stat].to_i}"
      begin
        stats_engine.get_stats("/System/Memcached/#{hostname_port}/#{stat.to_s.titleize}", false).record_data_point(stats[stat].to_i)
      rescue
        NewRelic::Agent.instance.log.debug "Could not record stat: #{stat}\n #{e.backtrace.join("\n")}"
      end
    end
    float_values.each do |stat| 
      NewRelic::Agent.instance.log.debug "recording /System/Memcached/#{hostname_port}/#{stat.to_s.titleize} = #{stats[stat].to_f}"
      begin
        stats_engine.get_stats("/System/Memcached/#{hostname_port}/#{stat.to_s.titleize}", false).record_data_point(stats[stat].to_f)
      rescue
        NewRelic::Agent.instance.log.debug "Could not record stat: #{stat}\n #{e.backtrace.join("\n")}"
      end
    end
    NewRelic::Agent.instance.log.debug "Done with record data"
  end
end
