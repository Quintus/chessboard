require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "RegistrationToken Model" do
  it 'can construct a new instance' do
    @registration_token = RegistrationToken.new
    refute_nil @registration_token
  end
end
