require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "Post Model" do

  it 'can construct a new instance' do
    @post = Post.new
    refute_nil @post
  end

  it "validates properly" do
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:post, content: nil) }
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:post, language: nil) }
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:post, language: "invalid") }

    assert Fabricate(:post)
  end

end
