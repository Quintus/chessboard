require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "PersonalPost Model" do
  it 'can construct a new instance' do
    @personal_post = PersonalPost.new
    refute_nil @personal_post
  end
end
