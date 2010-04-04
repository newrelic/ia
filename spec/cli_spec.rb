require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'new_relic/ia/cli'
require 'new_relic/ia/iostat_reader'
require 'new_relic/ia/disk_sampler'
require 'new_relic/ia/memcached_sampler'
describe NewRelic::IA::CLI, "execute" do
  before(:each) do
    @stdout_io = StringIO.new
  end
  it "should print help" do
    NewRelic::IA::CLI.execute(@stdout_io, [ "-h"])
    @stdout_io.rewind
    @stdout = @stdout_io.read
    @stdout.should =~ /Usage:/
  end
  it "should not accept a bad aspect" do
    stat = NewRelic::IA::CLI.execute(@stdout_io, [ "foo"])
    stat.should == 1
  end
  it "should start iostat" do
    NewRelic::IA::IostatReader.any_instance.expects(:run).once
    stat = NewRelic::IA::CLI.execute(@stdout_io, [ "iostat"])
    stat.should == nil
    Thread.pass
  end
  it "should start disk" do
    NewRelic::Agent::StatsEngine.any_instance.expects(:add_harvest_sampler)
    stat = NewRelic::IA::CLI.execute(@stdout_io, [ "disk"])
    stat.should == nil
  end
  it "should start memcached" do
    NewRelic::Agent::StatsEngine.any_instance.expects(:add_harvest_sampler)
    stat = NewRelic::IA::CLI.execute(@stdout_io, [ "memcached"])
    stat.should == nil
  end
  it "should override the env" do
    stat = NewRelic::IA::CLI.execute(@stdout_io, [ "disk", "-e", "production"])
    stat.should == nil
    NewRelic::Control.instance.env.should == "production"
  end
end