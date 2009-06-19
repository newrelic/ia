require File.dirname(__FILE__) + '/spec_helper.rb'
require 'new_relic/ia/iostat_reader'

describe NewRelic::IA::IostatReader do
  
  before do
    @statsengine = NewRelic::Agent::StatsEngine.new
    NewRelic::Agent.instance.stubs(:stats_engine).returns(@statsengine)
    @reader = NewRelic::IA::IostatReader.new
  end
  
  it "should read repeatedly" do
    
    @reader.read_next
    @reader.read_next
    @reader.read_next
    @statsengine.metrics.sort.should == ["System/System CPU/percent", "System/Resource/DiskIO/kb", "System/User CPU/percent"].sort
    @statsengine.metrics.each do |m|
      stats = @statsengine.lookup_stat m
      stats.call_count.should == 3
    end
  end
end
