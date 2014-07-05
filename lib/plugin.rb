# -*- coding: utf-8 -*-

# Base mixin module for all Chessboard plugins. In order to
# have your module recognized as a Chessboard plugin, you
# have to include this module, which will automatically
# make Padrino’s view helpers available in your module.
module Chessboard::Plugin
  include Padrino::Helpers::OutputHelpers
  include Padrino::Helpers::TagHelpers
  include Padrino::Helpers::AssetTagHelpers
  include Padrino::Helpers::FormHelpers
  include Padrino::Helpers::FormatHelpers
  #include Padrino::Helpers::RenderHelpers # Would render app/views, which is undesired
  include Padrino::Helpers::NumberHelpers

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

  # Returns the list of all loaded plugins.
  def self.all_plugins
    @plugins ||= []
  end

  # Adds the module that includes this to the list
  # of all plugins and includes it into the Evaluator
  # class, which is used by the hook helper.
  def self.included(other) # :nodoc:
    all_plugins << other
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
  end

  # This hook is called in views where you can create
  # posts, before the main post content field.
  #
  # Extra options received:
  # [:post]
  #   The post.
  def hook_reply_pre_content(options)
  end

  # This hook is called in views where you can create
  # posts, after the main post content field.
  #
  # Extra options received:
  # [:post]
  #   The post.
  def hook_reply_post_content(options)
  end

  # This hook is called in the posts controller
  # when a post is before being saved. Returning false from
  # this hook will prevent the post from being saved!
  #
  # Extra options received:
  # [:post]
  #   The post being saved.
  def hook_ctrl_post_create(options)
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
  def hook_ctrl_post_update(options)
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
  def hook_ctrl_topic_create(options)
    true
  end

end

# Load the available plugins
Dir[Padrino.root("plugins", "*", "plugin.rb")].sort.each do |pluginpath|
  Chessboard::App.logger.info("Found plugin file: #{pluginpath}")
  require(pluginpath)
end
