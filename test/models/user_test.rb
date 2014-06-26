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
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:user, preferred_markup_language: "sfsf sgfd g h") }
    assert_raises(ActiveRecord::RecordInvalid){ Fabricate(:user, preferred_markup_language: nil) }
    assert Fabricate(:user)
  end

  it "should enforce long passwords" do
    user = User.new(nickname: "username", email: "e@ma.il", rank: "none")
    refute user.save # No password

    assert_raises(ArgumentError){ Fabricate.build(:user, password: "foo") } # Password too short

    u = Fabricate.build(:user)
    u.encrypted_password = nil
    refute user.save # No password

    assert Fabricate(:user, password: "foofoofoo")
  end

  it "should authenticate properly" do
    user = Fabricate(:user, password: "foofoofoo")

    refute user.authenticate ""
    refute user.authenticate "wrongpassword"
    assert user.authenticate "foofoofoo"
  end

end
