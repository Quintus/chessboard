# -*- coding: utf-8 -*-
# = FluxBB compatibility plugin
#
# Makes FluxBB topic URLs work in Chessboard.
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

      topic = Topic.find(params["id"])
      redirect url(:topics, :show, topic.id), 301
    end
  end

end
