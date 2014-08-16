# -*- coding: utf-8 -*-
# = FluxBB compatibility plugin
#
# Makes FluxBB post URLs work in Chessboard.
#
# Like this: viewtopic.php?id=31
#
# == Configuration
# None.
module FluxbbCompatPlugin
  include Chessboard::Plugin

  Chessboard::App.controllers :fluxbb_compat do
    get :post_compat, :map => "/viewtopic.php" do
      halt 400 unless params["id"]

      post = Post.find(params["id"])
      redirect post_url(post), 301
    end
  end

end
