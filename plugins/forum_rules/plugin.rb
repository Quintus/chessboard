# = Forum rules plugin
#
# This plugin adds a link to the top menu referencing a new
# page "Forum rules" that contains a free configurable text.
# It also injects an unticked checkbox "accept rules" into
# the registration form that the user has to tick in order
# to complete the registration.
#
# == Configuration
# Add the following to your settings.rb:
#
#   config.plugins.ForumRulesPlugin = {
#     :rules => <<-RULES
# <h1>Forum rules</h1>
# <p>Your rules here.</p>
#     RULES
#   }
#
# === Keywords
# [rules]
#   Free-form HTML for your rules page.
module ForumRulesPlugin
  include Chessboard::Plugin

  Chessboard::App.controllers :rules do
    get :rules, :map => "/rules" do
      render :erb, Chessboard.config.plugins.ForumRulesPlugin[:rules]
    end
  end

  def hook_view_registration(options)
    content = super

    content += content_tag("p") do
      str = check_box_tag(:accept_forum_rules, :id => "accept_forum_rules")
      str += " <label for=accept_forum_rules>#{I18n.t("plugins.forum_rules.accept")}</label>".html_safe
      str
    end

    content
  end

  def hook_ctrl_registration(options)
    return false unless super

    if options[:params]["accept_forum_rules"].to_i != 1
      options[:user].errors[:base] << I18n.t("plugins.forum_rules.must_accept")
      return false
    end

    true
  end

  def hook_layout_navigation(options)
    content = super

    content += content_tag("li"){ link_to(I18n.t("plugins.forum_rules.forum_rules"), "/rules") }

    content
  end

end
