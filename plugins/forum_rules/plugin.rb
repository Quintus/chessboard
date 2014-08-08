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

  def hook_layout_navigation(options)
    content = super

    content += content_tag("li"){ link_to(I18n.t("plugins.forum_rules.forum_rules"), "/rules") }

    content
  end

end
