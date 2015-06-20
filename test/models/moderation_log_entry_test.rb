require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "Moderation Model" do
  it 'can construct a new instance' do
    @moderation_log_entry = Moderation.new
    refute_nil @moderation_log_entry
  end
end
