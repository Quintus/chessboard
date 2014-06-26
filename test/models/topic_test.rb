require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "Topic Model" do

  it 'can construct a new instance' do
    @topic = Topic.new
    refute_nil @topic
  end

  it "should properly validate" do
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:topic, title: nil) }
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:topic, author: nil) }

    assert Fabricate(:topic)
  end

end
