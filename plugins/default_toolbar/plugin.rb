# -*- coding: utf-8 -*-

# This plugin provides Chessboard’s default toolbar used
# when creating new posts or replying.
module DefaultToolbarPlugin
  include Chessboard::Plugin

  def hook_reply_pre_content(options)
    super
    content_tag "p", link_to("foofoo", url(:forums, :show, 2))
  end

end
