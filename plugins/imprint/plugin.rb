# -*- coding: utf-8 -*-
# = Imprint plugin
#
# Provides a link to an Imprint as required per the German
# law (§5 TMG and §55 RStV). Be sure to fill out the imprint
# page with the required information!
#
# == Configuration
# Add the following to your settings.rb:
#
#     config.plugins.Imprint = {
#       :imprint => <<-IMPRINT
#   <h1>Imprint</h1>
#   Information as per §5 TMG / §55 RStV:
#   
#   This forum is run and administered by somone, somewhere.
#       IMPRINT
#     }
#
# === Keywords
# [imprint]
#   Free-form HTML for your Imprint page.
module ImprintPlugin
  include Chessboard::Plugin

  Chessboard::App.controllers :imprint do
    get :imprint, :map => "/imprint" do
      render :erb, Chessboard.config.plugins.ImprintPlugin[:imprint]
    end
  end

  def hook_layout_navigation(options)
    super + content_tag("li"){ link_to(I18n.t("plugins.imprint.imprint"), "/imprint") }
  end

end
