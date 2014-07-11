require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "PersonalMessage Model" do
  it 'can construct a new instance' do
    @personal_message = PersonalMessage.new
    refute_nil @personal_message
  end
end
