require 'optparse'
require 'logger'

class NewRelic::IA::CLI
  
  LOGFILE = "newrelic_ia.log"
  @log = Logger.new(STDOUT)
  
  class << self
    attr_accessor :log
    def level= l
      @log.level = l      
    end
    
    # Run the command line args.  Return nil if running
    # or an exit status if not.
    def execute(stdout, arguments=[])
      @aspects = []
      @log = Logger.new LOGFILE
      @log_level = Logger::INFO
      parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^ */,'')

          Monitor different aspects of your environment with New Relic RPM.  

          Usage: #{File.basename($0)} [ options ] aspect, aspect.. 

          aspect: one or more of 'iostat' or 'disk' (more to come)
        BANNER
        opts.separator ""
        opts.on("-a", "--all",
                "use all available aspects") { @aspects = %w[iostat disk memcached] }
        opts.on("-v", "--verbose",
                "debug output") { @log_level = Logger::DEBUG }
        opts.on("-q", "--quiet",
                "quiet output") { @log_level = Logger::ERROR }
        opts.on("-e", "--environment=ENV",
                "use ENV section in newrelic.yml") { |e| @env = e }
        opts.on("--install",
                "create a default newrelic.yml") { |e| return self.install(stdout) }
        
        opts.on("-h", "--help",
                "Show this help message.") { stdout.puts "#{opts}\n"; return 0 }
        begin
          args = opts.parse! arguments
          unless args.empty?
            @aspects = args
          end
        rescue => e
          stdout.puts e
          stdout.puts opts
          return 1
        end
      end
      @aspects.delete_if do |aspect|
        unless self.instance_methods(false).include? aspect
          stdout.puts "Unknown aspect: #{aspect}"
          true
        end
      end
      if @aspects.empty?
        stdout.puts "No aspects specified."
        stdout.puts parser
        return 1
      end
      
      @log.level = @log_level 
      gem 'newrelic_rpm'
      require 'newrelic_rpm'
      NewRelic::Agent.manual_start :log => @log, :env => @env, :enabled => true
      cli = new
      @aspects.each do | aspect |
        cli.send aspect
      end
      return nil
    end
  end
  # Aspect definitions
  def iostat # :nodoc:
    self.class.log.info "Starting iostat monitor..."
    require 'new_relic/ia/iostat_reader'
    reader = NewRelic::IA::IostatReader.new
    Thread.new { reader.run }
  end
  
  def disk
    self.class.log.info "Starting disk sampler..."
    require 'new_relic/ia/disk_sampler'
    NewRelic::Agent.instance.stats_engine.add_harvest_sampler NewRelic::IA::DiskSampler.new    
  end
  
  def memcached
    self.class.log.info "Starting memcached sampler..."
    require 'new_relic/ia/memcached_sampler'
    NewRelic::Agent.instance.stats_engine.add_harvest_sampler NewRelic::IA::MemcachedSampler.new
  end

  private 
  def self.install(stdio)
    if File.exists? "newrelic.yml"
      stdio.puts "A newrelic.yml file already exists.  Please remove it before installing another."
      1 # error
    else      
      FileUtils.copy File.join(File.dirname(__FILE__), "newrelic.yml"), "."
      stdio.puts "A newrelic.yml template was copied to #{File.expand_path('.')}."
      stdio.puts "Please add a license key to the file before starting."
      0 # normal
    end
    if File.exists? "memcached-nodes.txt"
      stdio.puts "A memcached-nodes.txt file already exists.  Please remove it before installing another."
      1 # error
    else      
      FileUtils.copy File.join(File.dirname(__FILE__), "memcached-nodes.txt"), "."
      stdio.puts "A memcached-nodes.txt template was copied to #{File.expand_path('.')}."
      stdio.puts "Please add memcached nodes to monitor."
      0 # normal
    end
  end
end