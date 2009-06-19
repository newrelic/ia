require 'optparse'
require 'logger'

class NewRelic::EPM::CLI
  
  @log = Logger.new(STDOUT)

  class << self
    attr_accessor :log
    def level= l
      @log.level = l      
    end
    
    # Run the command line args.  Return nil if running
    # or an exit status if not.
    def execute(stdout, arguments=[])
      @log = Logger.new(stdout)
      @log_level = Logger::INFO
      parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^ */,'')

          Monitor different aspects of your environment with New Relic RPM.  

          Usage: #{File.basename($0)} [ options ] aspect, aspect.. 

          aspect: one or more of 'iostat' or 'disk' (more to come)
        BANNER
        opts.separator ""
        opts.on("-a", "--all",
                "use all available aspects") { @aspects = %w[iostat disk] }
        opts.on("-v", "--verbose",
                "debug output") { @log_level = Logger::DEBUG }
        opts.on("-q", "--quiet",
                "quiet output") { @log_level = Logger::ERROR }
        opts.on("-e", "--environment=ENV",
                "use ENV section in newrelic.yml") { |e| NewRelic::Control.instance.env = e }
        
        opts.on("-h", "--help",
                "Show this help message.") { stdout.puts "#{opts}\n"; return 0 }
        begin
          args = opts.parse! arguments
          unless args.empty?
            @aspects = args
          end
        rescue => e
          puts e
          puts opts
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

      self.level = @log_level 
      gem 'newrelic_rpm'
      require 'newrelic_rpm'
      NewRelic::Agent.manual_start :log => @log
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
    require 'new_relic/epm/iostat_reader'
    reader = NewRelic::EPM::IostatReader.new
    Thread.new { reader.run }
  end
  def disk
    self.class.log.info "Starting disk sampler..."
    require 'new_relic/epm/disk_sampler'
    NewRelic::Agent.instance.stats_engine.add_harvest_sampler NewRelic::EPM::DiskSampler.new    
  end
end