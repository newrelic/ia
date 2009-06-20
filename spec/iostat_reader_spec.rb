require File.dirname(__FILE__) + '/spec_helper.rb'
require 'new_relic/ia/iostat_reader'
require 'new_relic/ia/iostat_reader/linux'
require 'new_relic/ia/iostat_reader/osx'

describe NewRelic::IA::IostatReader do
  
  before do
    @statsengine = NewRelic::Agent::StatsEngine.new
    NewRelic::Agent.instance.stubs(:stats_engine).returns(@statsengine)
    @reader = NewRelic::IA::IostatReader.new
  end
  
  it "should read repeatedly" do
    
    @reader.read_next
    @reader.read_next
    @statsengine.metrics.sort.should == ["System/CPU/System/percent", "System/CPU/User/percent", "System/Resource/DiskIO/kb"].sort
    @statsengine.metrics.each do |m|
      stats = @statsengine.lookup_stat m
      stats.call_count.should == 2
    end
  end
  
  it "should process linux stats" do
    # NewRelic::IA::CLI.log.level=Logger::DEBUG
    @reader.extend NewRelic::IA::IostatReader::Linux
    @reader.instance_eval do
      @pipe = File.open(File.dirname(__FILE__) + "/iostat-linux.out")
    end
    @reader.read_next
    @reader.read_next
    @reader.read_next
    metrics = %w[System/CPU/System/percent System/CPU/User/percent System/Resource/DiskIO/kb]
    @statsengine.metrics.sort.should == metrics
    stats = metrics.map { | m | @statsengine.lookup_stat m } 
    stats[0..1].each { |s| s.call_count.should == 3 }
    stats[2].call_count.should == 6
  end
  
  it "should process osx stats" do
    # NewRelic::IA::CLI.log.level=Logger::DEBUG
    @reader.extend NewRelic::IA::IostatReader::OSX
    @reader.instance_eval do
      @pipe = File.open(File.dirname(__FILE__) + "/iostat-osx.out")
    end
    @reader.read_next
    @reader.read_next
    @reader.read_next
    metrics = %w[System/CPU/System/percent System/CPU/User/percent System/Resource/DiskIO/kb]
    @statsengine.metrics.sort.should == metrics
    stats = metrics.map { | m | @statsengine.lookup_stat m } 
    stats.each { |s| s.call_count.should == 3 }
  end
end
