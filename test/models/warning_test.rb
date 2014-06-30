require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "Warning Model" do
  it 'can construct a new instance' do
    @warning = Warning.new
    refute_nil @warning
  end
end
