require File.dirname(__FILE__) + '/spec_helper.rb'
require 'new_relic/ia/memcached_sampler'
# http://rspec.info/
describe NewRelic::IA::MemcachedSampler do
  
  before do
    #NewRelic::Agent.instance.log.level = Logger::DEBUG
    @sampler = NewRelic::IA::MemcachedSampler.new
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
    @sampler.stubs(:logger).returns(logger)
    
#    @statsengine = stub(:get_stats => @stats)
    @statsengine = NewRelic::Agent::StatsEngine.new
    @sampler.stats_engine = @statsengine
    @sampler.stubs(:memcached_nodes).returns(["localhost:11211"])
  end
  
  it "should parse stats" do
    file = File.open(File.join(File.dirname(__FILE__),"memcached-1.out"), "r")
    stats_text = file.read
    @sampler.stubs(:issue_stats).returns(stats_text)
    
    @sampler.poll
    @statsengine.metrics.each do |m|
      stats = @statsengine.lookup_stat m
      stats.call_count.should == 1
      m.should match(/System\/Memcached.*/)
    end
  end
  it "should parse nil stats" do
    @sampler.stubs(:issue_stats).returns(nil)
    @sampler.poll
    @statsengine.metrics.each do |m|
      stats = @statsengine.lookup_stat m
      stats.call_count.should == 0
    end

    @sampler.stubs(:issue_stats).returns("")
    @sampler.poll
    @statsengine.metrics.each do |m|
      stats = @statsengine.lookup_stat m
      stats.call_count.should == 0
    end
  end
  # it "should poll on demand" do
  #   2.times { @sampler.poll }
  #   @statsengine.metrics.each do |m|
  #     stats = @statsengine.lookup_stat m
  #     stats.call_count.should == 2
  #     m.should match(/System\/Filesystem\/.*percent/)
  #   end
  # end
end
