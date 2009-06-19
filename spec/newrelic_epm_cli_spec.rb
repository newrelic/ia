require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'new_relic/epm/cli'
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
end