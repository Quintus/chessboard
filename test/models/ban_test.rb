require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "Ban Model" do
  it 'can construct a new instance' do
    @ban = Ban.new
    refute_nil @ban
  end
end
