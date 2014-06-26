require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "Settings Model" do
  it 'can construct a new instance' do
    @settings = Settings.new
    refute_nil @settings
  end
end
