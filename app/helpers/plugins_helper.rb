# -*- coding: utf-8 -*-

module Chessboard
  class App
    module PluginsHelper

      def call_hook(hook, options = {})
        return if Chessboard::Plugin.all_plugins.empty?

        options.merge!({:request => request, :session => session, :env => env})

        # This class has all plugins `include'd.
        evaluator = Chessboard::Plugin::Evaluator.new
        evaluator.call_hook(hook, options)
      end

    end

    helpers PluginsHelper
  end
end
