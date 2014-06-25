require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "User Model" do

  it 'can construct a new instance' do
    @user = User.new
    refute_nil @user
  end

  it "should validate properly" do
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:user, nickname: nil) }
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:user, email: nil) }
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:user, rank: nil) }
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:user, nickname: "foo") ; Fabricate(:user, nickname: "foo") }
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:user, email: "sfsf sgfd g h") }
    assert Fabricate(:user)
  end

end
