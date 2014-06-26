require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "Post Model" do

  it 'can construct a new instance' do
    @post = Post.new
    refute_nil @post
  end

  it "validates properly" do
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:post, content: nil) }
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:post, markup_language: nil) }
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:post, markup_language: "invalid") }
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:post, author: nil) }

    assert Fabricate(:post)
  end

end
