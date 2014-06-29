require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "Report Model" do
  it 'can construct a new instance' do
    @report = Report.new
    refute_nil @report
  end
end
