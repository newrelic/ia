require 'optparse'
require 'logger'
require 'fileutils'

module NewRelic::IA

  class InitError < StandardError;  end
  
  class CLI
    
    LOGFILE = "newrelic_ia.log"
    
    class << self
      
      def log
        @log ||= Logger.new LOGFILE
      end
      
      def level= l
        log.level = l
      end
      
      # Run the command line args.  Return nil if running
      # or an exit status if not.
      def execute(stdout, arguments=[])
        @aspects = []
        parser = OptionParser.new do |opts|
          opts.banner = <<-BANNER.gsub(/^ */,'')
          New Relic Infrastructure Agent (IA) version #{NewRelic::IA::VERSION}
          Monitor different aspects of your environment with New Relic RPM.  

          Usage: #{File.basename($0)} [ options ] aspect, aspect.. 

          aspect: one or more of 'memcached', 'iostat' or 'disk' (more to come)
        BANNER
          opts.separator ""
          opts.on("-a", "--all",
                  "use all available aspects") { @aspects = %w[iostat disk memcached] }
          opts.on("-v", "--verbose",
                  "debug output") { NewRelic::IA::CLI.log.level = Logger::DEBUG }
          opts.on("-q", "--quiet",
                  "quiet output") { NewRelic::IA::CLI.log.level = Logger::ERROR }
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
        require_newrelic_rpm        
        NewRelic::Agent.manual_start  :env => @env, :monitor_mode => true, :log => self.log
        # connected? due in a future version
        if not (NewRelic::Agent.instance.connected? rescue true)
          raise InitError, "Unable to connect to RPM server.  Agent not started."
        end
        cli = new
        @aspects.each do | aspect |
          cli.send aspect
        end
        return nil
      rescue InitError => e
        stdout.puts e.message
        return 1
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
      require 'new_relic/ia/memcached_sampler'
      s = NewRelic::IA::MemcachedSampler.new
      s.check
      NewRelic::Agent.instance.stats_engine.add_harvest_sampler s
    end

    private
    
    def log
      self.class.log
    end
    
    def self.require_newrelic_rpm
      begin
        require 'newrelic_rpm'
      rescue Exception => e
        begin
          require 'rubygems' unless ENV['NO_RUBYGEMS']
          require 'newrelic_rpm'
        rescue LoadError
          $stderr.puts "Unable to load required gem newrelic_rpm"
          $stderr.puts "Try `gem install newrelic_rpm`"
          Kernel.exit 1
        end
      end
    end
    
    def self.install stdout
      require_newrelic_rpm
      if NewRelic::VersionNumber.new(NewRelic::VERSION::STRING) < '2.12'
        if File.exists? "newrelic.yml"
          stdout.puts "A newrelic.yml file already exists.  Please remove it before installing another."
          return 1 # error
        else      
          FileUtils.copy File.join(File.dirname(__FILE__), "newrelic.yml"), "."
          stdout.puts "A newrelic.yml template was copied to #{File.expand_path('.')}."
          stdout.puts "Please add a license key to the file before starting."
          return 0 # normal
        end
      else
        begin
          require 'new_relic/command'
          cmd = NewRelic::Command::Install.new \
          :src_file => File.join(File.dirname(__FILE__), "newrelic.yml"),
          :generated_for_user => "Generated on #{Time.now.strftime('%b %d, %Y')}, from version #{NewRelic::IA::VERSION}"
          cmd.run 
          0 # normal
        rescue NewRelic::Command::CommandFailure => e
          stdout.puts e.message
          1 # error
        end
      end
    end
  end
end
