require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'new_relic/epm/cli'
require 'new_relic/epm/iostat_reader'
require 'new_relic/epm/disk_sampler'
#require 'new_relic/stats_engine'
describe NewRelic::EPM::CLI, "execute" do
  before(:each) do
    @stdout_io = StringIO.new
  end
  it "should print help" do
    NewRelic::EPM::CLI.execute(@stdout_io, [ "-h"])
    @stdout_io.rewind
    @stdout = @stdout_io.read
    @stdout.should =~ /Usage:/
  end
  it "should not accept a bad aspect" do
    stat = NewRelic::EPM::CLI.execute(@stdout_io, [ "foo"])
    stat.should == 1
  end
  it "should start iostat" do
    NewRelic::EPM::IostatReader.any_instance.expects(:run).once
    stat = NewRelic::EPM::CLI.execute(@stdout_io, [ "iostat"])
    stat.should == nil
    Thread.pass
  end
  it "should start disk" do
    NewRelic::Agent::StatsEngine.any_instance.expects(:add_harvest_sampler)
    stat = NewRelic::EPM::CLI.execute(@stdout_io, [ "disk"])
    stat.should == nil
  end
  it "should override the env" do
    stat = NewRelic::EPM::CLI.execute(@stdout_io, [ "disk", "-e", "production"])
    stat.should == nil
    NewRelic::Control.instance.env.should == "production"
  end
end