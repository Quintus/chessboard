require File.expand_path(File.dirname(__FILE__) + '/../../test_config.rb')

describe "Chessboard::App::WarningsHelper" do
  before do
    @helpers = Class.new
    @helpers.extend Chessboard::App::WarningsHelper
  end

  def helpers
    @helpers
  end

  it "should return nil" do
    assert_equal nil, helpers.foo
  end
end
