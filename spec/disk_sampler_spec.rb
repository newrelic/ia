require File.dirname(__FILE__) + '/spec_helper.rb'
require 'new_relic/ia/disk_sampler'
# http://rspec.info/
describe NewRelic::IA::DiskSampler do
  
  before do
    @sampler = NewRelic::IA::DiskSampler.new
#    @statsengine = stub(:get_stats => @stats)
    @statsengine = NewRelic::Agent::StatsEngine.new
    @sampler.stats_engine = @statsengine
  end
  
  it "should poll on demand" do
    2.times { @sampler.poll }
    @statsengine.metrics.each do |m|
      stats = @statsengine.lookup_stat m
      stats.call_count.should == 2
      m.should match(/System\/Filesystem\/.*percent/)
    end
  end
end
