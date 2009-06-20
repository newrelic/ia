require File.dirname(__FILE__) + '/spec_helper.rb'
require 'new_relic/ia/iostat_reader'
require 'new_relic/ia/iostat_reader/linux'
require 'new_relic/ia/iostat_reader/osx'
require 'new_relic/ia/metric_names'

# Change the refresh time to 2 to speed up tests.
NewRelic::IA::IostatReader::OSX.class_eval do
   def cmd; "iostat -dCI 2"  ; end
end

describe NewRelic::IA::IostatReader do
  
  include NewRelic::IA::MetricNames
  METRICS = [NewRelic::IA::MetricNames::SYSTEM_CPU, NewRelic::IA::MetricNames::USER_CPU, NewRelic::IA::MetricNames::DISK_IO].sort  
  before do
    @statsengine = NewRelic::Agent::StatsEngine.new
    NewRelic::Agent.instance.stubs(:stats_engine).returns(@statsengine)
    @reader = NewRelic::IA::IostatReader.new
  end
  
  def canned_data_loader(filename)
    @reader.instance_eval do
      @pipe = File.open(File.join(File.dirname(__FILE__),filename))
    end
    @reader.init 
    @reader.read_next
    @reader.read_next
    @reader.read_next
    metrics = [NewRelic::IA::MetricNames::SYSTEM_CPU, NewRelic::IA::MetricNames::USER_CPU, NewRelic::IA::MetricNames::DISK_IO].sort
    @statsengine.metrics.sort.should == metrics
    stats = metrics.map { | m | [m, @statsengine.lookup_stat(m) ] }
    Hash[*stats.flatten]
  end
  
  it "should read repeatedly" do
    @reader.init
    @reader.read_next
    @reader.read_next
    @statsengine.metrics.sort.should == METRICS
    @statsengine.metrics.each do |m|
      stats = @statsengine.lookup_stat m
      stats.call_count.should == 2
    end
  end
  
  it "should process linux stats" do
    # NewRelic::IA::CLI.log.level=Logger::DEBUG
    @reader.extend NewRelic::IA::IostatReader::Linux
    stats = canned_data_loader("iostat-linux.out")
    
    stats[NewRelic::IA::MetricNames::DISK_IO].total_call_time.should == 8261632.0
    stats[NewRelic::IA::MetricNames::DISK_IO].call_count.should == 9
    stats[NewRelic::IA::MetricNames::SYSTEM_CPU].call_count.should == 3 
    stats[NewRelic::IA::MetricNames::SYSTEM_CPU].total_call_time.should == 1.51 
    stats[NewRelic::IA::MetricNames::USER_CPU].call_count.should == 3 
    stats[NewRelic::IA::MetricNames::USER_CPU].total_call_time.should == 33.0
   end
  
  it "should process osx stats" do
    # NewRelic::IA::CLI.log.level=Logger::DEBUG
    @reader.extend NewRelic::IA::IostatReader::OSX
    stats = canned_data_loader("iostat-osx.out")
    stats.values.each { |s| s.call_count.should == 3 }
    stats[NewRelic::IA::MetricNames::SYSTEM_CPU].total_call_time.should == 6.0
    stats[NewRelic::IA::MetricNames::USER_CPU].total_call_time.should == 15.0
    stats[NewRelic::IA::MetricNames::DISK_IO].total_call_time.round.should == 1468006.0
  end
  
end
