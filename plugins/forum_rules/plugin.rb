# = Forum rules plugin
#
# This plugin adds a link to the top menu referencing a new
# page "Forum rules" that contains a free configurable text.
# It also injects an unticked checkbox "accept rules" into
# the registration form that the user has to tick in order
# to complete the registration.
#
# == Configuration
# None. This plugin is configured entirely through the admin
# settings page, to which it adds some fields.
#
# === Keywords
# [rules]
#   Free-form HTML for your rules page.
module ForumRulesPlugin
  include Chessboard::Plugin

  Chessboard::App.controllers :rules do
    get :rules, :map => "/rules" do
      hsh = GlobalConfiguration.instance.plugin_data[:ForumRulesPlugin] || {}
      render :erb, (hsh[:forum_rules_content] || "<p>#{I18n.t("plugins.forum_rules.no_rules_specified")}</p>")
    end
  end

  def hook_view_configuration(options)
    content = super

    hsh = options[:configuration].plugin_data[:ForumRulesPlugin] || {}

    str = <<-HTML.html_safe
<div class="header settings-header">
  <label for="forum_rules_version">#{I18n.t("plugins.forum_rules.version")}</label>
</div>
<div class="settings-desc">
  <p>#{I18n.t("plugins.forum_rules.version_desc")}</p>
</div>
<div class="settings-content">
  <p>#{text_field_tag(:forum_rules_version, :id => "forum_rules_version", :value => hsh[:forum_rules_version])}</p>
</div>
<div class="header settings-header">
  <label for="forum_rules_content">#{I18n.t("plugins.forum_rules.content")}</label>
</div>
<div class="settings-desc">
  <p>#{I18n.t("plugins.forum_rules.content_desc")}</p>
</div>
<div class="settings-content">
  <p>#{text_area_tag(:forum_rules_content, :id => "forum_rules_content", :value => hsh[:forum_rules_content])}</p>
</div>
      HTML

    content + str
  end

  def hook_ctrl_configuration(options)
    return false unless super

    if options[:params]["forum_rules_version"].blank?
      options[:configuration].errors[:plugin_data] << I18n.t("plugins.forum_rules.must_specify_version")
      return false
    elsif
      options[:params]["forum_rules_content"].blank?
      options[:configuration].errors[:plugin_data] << I18n.t("plugins.forum_rules.must_specify_content")
      return false
    end

    options[:configuration].plugin_data[:ForumRulesPlugin] ||= {}
    options[:configuration].plugin_data[:ForumRulesPlugin][:forum_rules_version] = options[:params]["forum_rules_version"]
    options[:configuration].plugin_data[:ForumRulesPlugin][:forum_rules_content] = options[:params]["forum_rules_content"]

    options[:configuration].save # Returns true or false
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
