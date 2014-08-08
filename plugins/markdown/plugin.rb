# = Markdown plugin
#
# This plugin provides Markdown post markup via
# the kramdown RubyGem.
#
# == Configuration
# None.
module MarkdownPlugin
  include Chessboard::Plugin

  add_markup "Markdown", :process => :markup_markdown

  def markup_markdown(text)
    kdoc = Kramdown::Document.new(text, :auto_ids => false, :remove_block_html_tags => true, :remove_span_html_tags => true)
    kdoc.to_remove_html_tags
    kdoc.to_html
  end

end
