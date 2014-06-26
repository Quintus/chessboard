require File.expand_path(File.dirname(__FILE__) + '/../../test_config.rb')

describe "Chessboard::App::PostsHelper" do
  before do
    @helpers = Class.new
    @helpers.extend Chessboard::App::PostsHelper
  end

  def helpers
    @helpers
  end

  it "should only allow valid markup languages" do
    assert_raises(ArgumentError){ helpers.process_markup("", "invalid") }
    assert_raises(ArgumentError){ helpers.process_markup("", "") }

    assert helpers.process_markup("", "Markdown")
    assert helpers.process_markup("", "BBCode")
  end

  it "should remove/escape html tags" do
    str = "foo <span>foo</span> *foo*"
    assert_equal "<p>foo foo <strong>foo</strong></p>", helpers.process_markdown(str)
    assert_equal "<p>foo &lt;span&gt;foo&lt;/span&gt; <strong>foo</strong></p>", helper.process_bbcode(str)
  end

end
