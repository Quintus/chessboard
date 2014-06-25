require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "Forum Model" do

  it 'can construct a new instance' do
    @forum = Forum.new
    refute_nil @forum
  end

  it "validates properly" do
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:forum, name: nil) }
    assert_raises(ActiveRecord::RecordInvalid) { Fabricate(:forum, description: nil) }
    assert_raises(ActiveRecord::RecordInvalid) { Fabricate(:forum, name: "foo"); Fabricate(:forum, name: "foo") }
    assert Fabricate(:forum)
  end

end
