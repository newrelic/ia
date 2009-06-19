require File.dirname(__FILE__) + '/spec_helper.rb'
require 'new_relic/epm/disk_sampler'
# http://rspec.info/
describe NewRelic::EPM::DiskSampler do
  
  before do
    @sampler = NewRelic::EPM::DiskSampler.new
#    @statsengine = stub(:get_stats => @stats)
    @statsengine = NewRelic::Agent::StatsEngine.new
    @sampler.stats_engine = @statsengine
  end
  
  it "should poll on demand" do
    3.times { @sampler.poll }
    @statsengine.metrics.each do |m|
      stats = @statsengine.lookup_stat m
      stats.call_count.should == 3
      m.should match(/Custom\/Filesystem\/.*percent/)
    end
  end
end
