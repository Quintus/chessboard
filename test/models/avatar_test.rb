require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "Avatar Model" do
  it 'can construct a new instance' do
    @avatar = Avatar.new
    refute_nil @avatar
  end
end
