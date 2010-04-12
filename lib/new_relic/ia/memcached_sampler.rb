require 'new_relic/ia/metric_names'
require 'socket'
#require 'active_support'

# Memcached stats sampler
# An IGN Hackday project

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
    super 'memcached'
    @int_values = [ :uptime, :curr_items, :total_items, :bytes, :curr_connections, :total_connections, :connection_structures,
      :cmd_flush, :cmd_get, :cmd_set, :get_hits, :get_misses, :evictions, :bytes_read, :bytes_written, :limit_maxbytes, :threads]
    @derived_values = [ :free_bytes]
    @derivatives = [:hit_ratio, :miss_ratio, :rpm, :gpm, :hpm, :mpm, :spm, :fpm, :epm]
    
    @last_stats = Hash.new
    @memcached_nodes = parse_config
  end
  
  def parse_config
    # file with a list of mecached nodes. each line have hostname:port
    memcached_nodes = NewRelic::Control.instance['memcached_nodes']
    if !memcached_nodes.is_a? Array || memcached_nodes.empty?
      raise NewRelic::IA::InitError, "No memcache_nodes array found in newrelic.yml."
    end
    memcached_nodes
  end

  def memcached_nodes
    @memcached_nodes
  end
  
  # Sanity check, make sure the servers are there.
  def check
    down_servers = []
    memcached_nodes.each do | hostname_port |
      stats_text = issue_stats hostname_port       
      down_servers << hostname_port unless stats_text
    end
    raise NewRelic::Agent::Sampler::Unsupported, "Servers not available: #{down_servers.join(", ")}" unless down_servers.empty?
  end
  
  # This gets called once a minute in the agent worker thread.  It
  # pings each host in the array 'memcached_nodes'
  def poll
    unless memcached_nodes.empty?
      memcached_nodes.each do | hostname_port |
        stats_text = issue_stats hostname_port
        if stats_text
          @last_stats[hostname_port] = parse_and_report_stats hostname_port, stats_text
        else
          @last_stats[hostname_port] = nil #{}
        end        
      end

      aggregate_stats
      debug "done with aggs"    
    end
  end
  
  def logger 
    NewRelic::IA::CLI.log
  end
  
  def aggregate_stats
    begin
      
      aggs_stats = Hash.new   
      @int_values.each {|metric| aggs_stats[metric] = 0}
      @derived_values.each {|metric| aggs_stats[metric] = 0}

      @derivatives[0,2].each {|metric| aggs_stats[metric] = 0.0}
      @derivatives[2,@derivatives.length - 2].each {|metric| aggs_stats[metric] = 0}

      aggs_count = 0
      @last_stats.each_value do |v|
        @int_values.each do |metric|
          aggs_stats[metric] +=  (v[metric] || 0)
        end
        @derived_values.each do |metric|
          aggs_stats[metric] +=  (v[metric] || 0)
        end
        if v[:hit_ratio] && v[:miss_ratio]
          @derivatives[0,2].each do |metric|
            aggs_stats[metric] +=  v[metric]
          end
          aggs_count += 1 

          @derivatives[2,@derivatives.length - 2].each do |metric| 
            aggs_stats[metric] +=  v[metric]
          end
        end
      end
      if aggs_count > 0
        aggs_stats[:hit_ratio] = aggs_stats[:hit_ratio] /aggs_count
        aggs_stats[:miss_ratio] = aggs_stats[:miss_ratio] /aggs_count
      end
      
      if aggs_stats[:uptime] > 0 
        @int_values.each do |stat| 
          debug "recording #{MEMCACHED}/all/#{stat.to_s} = #{aggs_stats[stat]}"
           begin
             stats("#{MEMCACHED}/all/#{stat.to_s}").record_data_point(aggs_stats[stat])
           rescue => e
             debug "Could not record stat: #{stat}\n #{e.backtrace.join("\n")}"
           end
         end

         @derived_values.each do |stat| 
           debug "recording #{MEMCACHED}/all/#{stat.to_s} = #{aggs_stats[stat]}"
           begin
             stats("#{MEMCACHED}/all/#{stat.to_s}").record_data_point(aggs_stats[stat])
           rescue => e
             debug "Could not record stat: #{stat}\n #{e.backtrace.join("\n")}"
           end
         end
         if aggs_count > 0
           @derivatives.each do |stat|
             debug "recording #{MEMCACHED}/all/#{stat.to_s} = #{aggs_stats[stat].to_i}"
             begin
               stats("#{MEMCACHED}/all/#{stat.to_s}").record_data_point(aggs_stats[stat].to_i)
             rescue => e
               debug "Could not record stat: #{stat}\n #{e.backtrace.join("\n")}"
             end
           end
         end
      else 
        debug "skipping aggregates since aggregate uptime is zero"        
      end
    rescue => e
      debug "Could not record stat: stats\n #{e.backtrace.join("\n")}"
    end
  end
  
  
  #TODO send stats for down nodes
  def issue_stats(hostname_port)
    debug  "get stats from hostname #{hostname_port}"
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

      statistics = ""
      loop do
        data = socket.recv(4096)
        if !data || data.length == 0
          break
        end
        statistics << data
        end_index = statistics =~ /\s+END\s+$/
        if end_index
          return statistics[0, end_index]
        end
      end
    rescue IOError, SystemCallError => e
      NewRelic::IA::CLI.log.warn "memcached: unable to connect to memcached node at #{hostname_port}: #{e.message}"
      logger.info "memcached: unable to connect to memcached node at #{hostname_port}"
      logger.error "memcached: #{e.message}"
      debug e.backtrace.join("\n")
    ensure
      socket.close if socket rescue nil
    end
    nil
  end
  
  def parse_stats(hostname_port, stats_text) 
    end_index = stats_text =~ /\s+END\s+$/
    stats_text = stats_text[0, end_index] if end_index
    sss = stats_text.split(/\s+/)
    if sss.size % 3 != 0
      logger.error "memcached: unexcpected stats output from #{hostname_port}: #{stats_text}"
      break
    end
    triplets = []
    while sss.any? do
      triplets << [ sss.shift, sss.shift, sss.shift]
    end
    stats = Hash.new
    triplets.each do |triplet| 
      debug "#{triplet[1].to_sym} = #{triplet[2]}"
      stats[triplet[1].to_sym] = triplet[2]
    end
    return stats
  end

  def parse_and_report_stats(hostname_port, stats_text)  
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
    
    
    # average_value
    #     * Active Connections - free
    #     * Current items
    #     * evictions
    #     * Total Size (memcache stat: limit_maxbytes)
    #     * Used size (memcache stat: bytes)
    # 
    #     need to compute during collection
    #     * Hit Ratio (%)
    #     * Requests per interval 
    #     * Hits per interval
    #     * Misses per interval
    #     * Sets per interval
    #     * Free size (memcache stat: limit_maxbytes - bytes)
    # 
    #     Also send all stats.
    #     
    #     
    stats = parse_stats(hostname_port, stats_text) 

    #we store ints in the hash
    @int_values.each do |stat| 
      stats[stat] = stats[stat].to_i 
    end
    #time is not shipped to collector but we add it for derivative calculations
    stats[:time] = Time.at stats[:time].to_i 

    stats[:free_bytes] = stats[:limit_maxbytes] - stats[:bytes]
    
    previous_stats = @last_stats[hostname_port]
    if previous_stats
      tn = stats[:time]
      tm = previous_stats[:time] 
      previous_r = previous_stats[:cmd_get] + previous_stats[:cmd_set]+ previous_stats[:cmd_flush]
      current_r = stats[:cmd_get] + stats[:cmd_set]+ stats[:cmd_flush]
       
      #unit per minute 
      stats[:rpm] = (current_r - previous_r) / (tn - tm) * 60 
      stats[:gpm] = (stats[:cmd_get] - previous_stats[:cmd_get]) / (tn - tm) * 60
      stats[:spm] = (stats[:cmd_set] - previous_stats[:cmd_set]) / (tn - tm) * 60
      stats[:fpm] = (stats[:cmd_flush] - previous_stats[:cmd_flush]) / (tn - tm) * 60
      stats[:hpm] = (stats[:get_hits] - previous_stats[:get_hits]) / (tn - tm) * 60
      stats[:mpm] = (stats[:get_misses] - previous_stats[:get_misses]) / (tn - tm) * 60
      stats[:epm] = (stats[:evictions] - previous_stats[:evictions]) / (tn - tm) * 60
      if stats[:hpm] + stats[:mpm] > 0
        stats[:hit_ratio] = stats[:hpm] / (stats[:hpm]+stats[:mpm])*100
        stats[:miss_ratio] = stats[:mpm] / (stats[:hpm]+stats[:mpm])*100
      else
        stats[:hit_ratio] = 100
        stats[:miss_ratio] = 0
      end
    end
    
    #string_values = [:version]
    #float_values = [:rusage_user, :rusage_system]
    
    @int_values.each do |stat| 
      debug "recording #{MEMCACHED}/#{hostname_port}/#{stat.to_s} = #{stats[stat]}"
      begin
        stats("#{MEMCACHED}/#{hostname_port}/#{stat.to_s}").record_data_point(stats[stat])
      rescue => e
        debug "Could not record stat: #{stat}\n #{e.backtrace.join("\n")}"
      end
    end
    @derived_values.each do |stat| 
      debug "recording #{MEMCACHED}/#{hostname_port}/#{stat.to_s} = #{stats[stat]}"
      begin
        stats("#{MEMCACHED}/#{hostname_port}/#{stat.to_s}").record_data_point(stats[stat])
      rescue => e
        debug "Could not record stat: #{stat}\n #{e.backtrace.join("\n")}"
      end
    end
    if previous_stats
      @derivatives.each do |stat|
        begin
          value = stats[stat].to_i
          debug "recording #{MEMCACHED}/#{hostname_port}/#{stat.to_s} = #{value}"
          stats("#{MEMCACHED}/#{hostname_port}/#{stat.to_s}").record_data_point(value)
        rescue => e
          puts "Error converting #{stat} value <#{stats[stat]}> to i: #{e.message}"
          puts "stats: #{stats.inspect}"
          debug "Could not record stat: #{stat}\n #{e.backtrace.join("\n")}"
        end
      end
    end

    # float_values.each do |stat| 
    #   debug "recording #{MEMCACHED}/#{hostname_port}/#{stat.to_s} = #{stats[stat].to_f}"
    #   begin
    #     stats("#{MEMCACHED}/#{hostname_port}/#{stat.to_s}").record_data_point(stats[stat].to_f)
    #   rescue => e
    #     debug "Could not record stat: #{stat}\n #{e.backtrace.join("\n")}"
    #   end
    # end
    debug "Done with record data"
    return stats
  end
  
  def stats(s)
    NewRelic::Agent.get_stats_no_scope(s)
  end
  
  def debug(msg)
    logger.debug "memcached: #{msg}"
  end
end

