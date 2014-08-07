require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "GlobalConfiguration Model" do
  it 'can construct a new instance' do
    @global_configuration = GlobalConfiguration.new
    refute_nil @global_configuration
  end
end
