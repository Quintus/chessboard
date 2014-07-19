# -*- coding: utf-8 -*-

# Base mixin module for all Chessboard plugins. In order to
# have your module recognized as a Chessboard plugin, you
# have to include this module, which will automatically
# make Padrino’s view helpers available in your module.
#
# See plugins.rdoc on how to write a plugin.
module Chessboard::Plugin
  include Padrino::Helpers::OutputHelpers
  include Padrino::Helpers::TagHelpers
  include Padrino::Helpers::AssetTagHelpers
  include Padrino::Helpers::FormHelpers
  include Padrino::Helpers::FormatHelpers
  #include Padrino::Helpers::RenderHelpers # Would render app/views, which is undesired
  include Padrino::Helpers::NumberHelpers

  # This struct represents a single markup language with
  # name and implementation.
  MarkupLanguage = Struct.new(:plugin, :name, :implementation)

  # Worker class whose only purpose is to get all the plugin
  # modules included. This is only used internally; as a plugin
  # author you should not worry about this class.
  class Evaluator

    # Executes all plugin hook callbacks that have been registered
    # for the hook with the given +name+. +options+ is directly
    # forwarded.
    def call_hook(name, options)
      sym = :"hook_#{name}"
      if respond_to?(sym) # Provided by the plugins, at least by Chessboard::Plugin itself
        logger.debug("Executing hook: #{name}")
        send(sym, options)
      else
        logger.error("Unknown hook called: #{name} (options: #{options.inspect})")
        nil
      end
    end

  end

  # The methods defined in this module are available on the
  # module level of your plugin after including Chessboard::Plugin.
  module ModuleMethods

    # Register a new markup language users can use in their postings.
    #
    # == Parameters
    # [name]
    #   The name of your markup language as it is displayed
    #   to the user. Be sure to pick a unique one.
    # [options]
    #   A hash for further options.
    #   [:process]
    #     The name of the method to invoke when this markup
    #     of this kind needs to be processed. The method
    #     must accept a single argument containing the markup
    #     and is expected to return the HTML corresponding to
    #     it. It is not required to call +html_safe+ on the
    #     result, but the result MUST actually be html safe,
    #     i.e. any HTML special characters have to be escaped
    #     if you don’t want them to show up in the output.
    #
    # == Remarks
    # * Emoticons processing will happen on the result of your
    #   markup process method; you don’t have to do this yourself.
    # * The same goes for any other post-processing that may be
    #   imposed on the formatted output by other plugins.
    #
    # == Example
    #   module MyPlugin
    #     include Chessboard::Plugin
    #
    #     add_markup "MyMarkup", :process => :process_my_markup
    #
    #     def process_my_markup(text)
    #       "<p>Formatted with my plugin: #{text}</p>"
    #     end
    #
    #  end
    def add_markup(name, options)
      Chessboard::Plugin.plugin_markup_languages << MarkupLanguage.new(self, name, options[:process])
    end

  end

  # Returns the list of all loaded plugins.
  def self.all_plugins
    @plugins ||= []
  end

  # Returns an array of MarkupLanguage instances that describes
  # all markup languages that have been added via plugins.
  def self.plugin_markup_languages
    @plugin_markup_languages ||= []
  end

  # Adds the module that includes this to the list
  # of all plugins and includes it into the Evaluator
  # class, which is used by the hook helper.
  def self.included(other) # :nodoc:
    all_plugins << other
    other.extend(Chessboard::Plugin::ModuleMethods)
    Chessboard::Plugin::Evaluator.send(:include, other)
  end

  # Makes Padrino’s #url method available to your plugin.
  def url(*args)
    Chessboard::App.url(*args)
  end

  ########################################
  # Hooks

  # This hook is called in the page layout’s <head>
  # HTML tag. Use it for your custom CSS and Javascript.
  # If your styling/scripting gets more complex, it is
  # recommended to place your CSS and JS files inside
  # one of the following folders:
  #
  # * Stylesheets: public/stylesheets/yourpluginname/
  # * Javascripts: public/javascripts/yourpluginname/
  #
  # You can then use the ordinary +stylesheet_include_tag+
  # and +javascript_include_tag+ helpers provided by
  # Padrino to reference them from this hook.
  #
  # Note that in your javascript you can rely on JQuery
  # and Handlebars being loaded.
  def hook_html_header(options)
    "".html_safe
  end

  # This hook is called in views where you can create
  # posts, before the main post content field.
  #
  # Extra options received:
  # [:post]
  #   The post.
  # [:form]
  #   The form as per Padrino’s form helper.
  def hook_view_reply_pre_content(options)
    "".html_safe
  end

  # This hook is called in views where you can create
  # posts, after the main post content field.
  #
  # Extra options received:
  # [:post]
  #   The post.
  # [:form]
  #   The form as per Padrino’s form helper.
  def hook_view_reply_post_content(options)
    "".html_safe
  end

  # Like #hook_view_reply_pre_content, but for PMs.
  def hook_view_pm_reply_pre_content(options)
    "".html_safe
  end

  # Like #hook_view_reply_post_content, but for PMs.
  def hook_view_pm_reply_post_content(options)
    "".html_safe
  end

  # This hook is called in the posts controller
  # when a post is before being saved. Returning false from
  # this hook will prevent the post from being saved!
  #
  # Extra options received:
  # [:post]
  #   The post being saved.
  # [:params]
  #   Request parameters hash.
  def hook_ctrl_post_create(options)
    true
  end

  # This hook is called in the PersonalPosts controller
  # when a personal post (those for PMs) is before being
  # saved. Returning false from this hook will prevent the
  # personal post from being saved!
  #
  # Extra options:
  # [:post]
  #   The PersonalPost being saved.
  # [:params]
  #   Request parameters hash.
  def hook_ctrl_pp_create(options)
    true
  end

  # This hook is called in the posts controller
  # when a post is before being updated. Returning
  # false from this hook will prevent the post from being
  # updated!
  #
  # Extra options received:
  # [:post]
  #   The post being saved.
  # [:params]
  #   Request parameters hash.
  def hook_ctrl_post_update(options)
    true
  end

  # This hook is called in the personal posts (posts
  # for PMs) controller when a post is before being
  # updated. Returning false from this hook will prevent
  # the post from being updated!
  #
  # Extra options received:
  # [:post]
  #   The PersonalPost being saved.
  # [:params]
  #   Request parameters hash.
  def hook_ctrl_pp_update(options)
    true
  end

  # This hook is called in the topics controller
  # when a topic is before being created. Returning
  # false from this hook will prevent the topic from
  # being updated!
  #
  # Extra options
  # [:topic]
  #   The topic being saved.
  # [:params]
  #   Request parameters hash.
  def hook_ctrl_topic_create(options)
    true
  end

  # This hook is called in the PM controller
  # when a PM is before being created. Returning false
  # from this hook will prevent the PM from being stored!
  #
  # Extra options
  # [:pm]
  #   The PersonalMessage being saved.
  # [:params]
  #   Request parameters hash.
  def hook_ctrl_pm_create(options)
    true
  end

  # This hook is called in the topics controller
  # when a topic is before being updated. Returning
  # false from this hook will prevent the topic from
  # being updated!
  #
  # Extra options:
  # [:topic]
  #   The topic being saved.
  # [:params]
  #   Request parameters hash.
  def hook_ctrl_topic_update(options)
    true
  end

  # This hook is called in the PMs controller when
  # a PM is before being updated. Returning false
  # from this hook will prevent the topic from
  # being updated!
  #
  # Extra options:
  # [:pm]
  #   The PersonalMessage being saved.
  # [:params]
  #   Request parameters hash.
  def hook_ctrl_pm_update(options)
    true
  end

  # This hook is called in the view of the registration page.
  # You can use it to add additional fields to the registration
  # form, which is available as an extra option to this hook.
  #
  # Extra options:
  # [:user]
  #   The user being created; either an empty User instance on
  #   the first try or a partially contructed one if saving
  #   failed for some reason.
  # [:form]
  #   The registration form as per Padrino’s form helper.
  def hook_view_registration(options)
    "".html_safe
  end

  # This hook is called before the newly registered user is
  # saved into the database. Returning false from this prevents
  # this step!
  #
  # Extra options:
  # [:user]
  #   The user who is trying to register.
  # [:params]
  #   params hash.
  def hook_ctrl_registration(options)
    true
  end

  # This hook is called in the helper that formats postings
  # after the markup processing has taken place. You can use
  # it to make final modifications to the text before it
  # is send to to the client.
  #
  # The return value of this hook is what is send to the
  # client. +html_safe+ is called on its return value
  # automatically.
  #
  # Extra options:
  # [:html]
  #   The formatted post.
  def hook_hlpr_post_markup(options)
    options[:html]
  end

  # This hook is called after a post has first been saved into
  # the database. It doesn’t have any effect by default.
  #
  # Extra options:
  # [:post]
  #   The post that was saved.
  def hook_ctrl_post_create_final(options)
  end

  # This hook is called after a personal post (post
  # for PMs) has first been saved into the database.
  # It doesn’t have any effect by default.
  #
  # Extra options:
  # [:post]
  #   The PersonalPost that was saved.
  def hook_ctrl_pp_create_final(options)
  end

  # This hook is called after a topic has first been saved into
  # the database. It doesn’t have any effect by default.
  #
  # Extra options:
  # [:topic]
  #   The topic that was saved.
  def hook_ctrl_topic_create_final(options)
  end

  # This hook is called after a PM has first been saved into
  # the database. It doesn’t have any effect by default.
  #
  # Extra options:
  # [:pm]
  #   The PersonalMessage that was saved.
  def hook_ctrl_pm_create_final(options)
  end

end

# Load the available plugins
Dir[Padrino.root("plugins", "*")].sort.each do |pluginpath|
  pluginfile = File.join(pluginpath, "plugin.rb")
  next unless File.exist?(pluginfile)

  Chessboard::App.logger.info("Found plugin file: #{pluginfile}")
  require(pluginfile)

  # Add plugin's translations if there are any.
  localedir = File.join(pluginpath, "locale")
  I18n.load_path << Dir["#{localedir}/**/*.yml"] if File.exist?(localedir)
end
