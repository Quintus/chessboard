# -*- coding: utf-8 -*-

module Chessboard
  class App
    module PluginsHelper

      # Helper method to use in controllers and views when a hook is to
      # be called. It creates an instances of Plugin::Evaluator and
      # calls it’s +call_hook+ method with the options you supply to
      # this method; additionally, your options hash is automatically
      # merged with the default hook options :request, :session, :env,
      # and :flash. Usage example:
      #
      #   call_hook(:ctrl_post_create, :post => @post, :params => params)
      #
      # This will execute all code registered with the :hook_ctrl_post_create
      # method and pass it an option hash consisting of the default hook
      # options mentioned above plus the extra options :post and :params.
      def call_hook(hook, options = {})
        return if Chessboard::Plugin.all_plugins.empty?

        options.merge!({:request => request, :session => session, :env => env, :flash => flash})

        # This class has all plugins `include'd.
        evaluator = Chessboard::Plugin::Evaluator.new
        evaluator.call_hook(hook, options)
      end

    end

    helpers PluginsHelper
  end
end
