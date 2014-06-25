require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "ForumGroup Model" do

  it 'can construct a new instance' do
    @forum_group = ForumGroup.new
    refute_nil @forum_group
  end

  it "validates properly" do
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:forum_group, name: nil) }
    assert_raises(ActiveRecord::RecordInvalid) { Fabricate(:forum_group, name: "foo"); Fabricate(:forum_group, name: "foo") }
    assert Fabricate(:forum)
  end

end
