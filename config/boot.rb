# -*- coding: utf-8 -*-
# Defines our constants
RACK_ENV = ENV['RACK_ENV'] ||= 'development'  unless defined?(RACK_ENV)
PADRINO_ROOT = File.expand_path('../..', __FILE__) unless defined?(PADRINO_ROOT)

# Load our dependencies
require 'rubygems' unless defined?(Gem)
require "ostruct"
require "ipaddr"
require "digest/md5"
require "time"
require 'bundler/setup'
require "mail"
Bundler.require(:default, RACK_ENV)

# Load settings
module Chessboard
  def self.configure
    @config = OpenStruct.new
    @config.plugins = OpenStruct.new
    yield(@config)
  end
  def self.config
    @config
  end
end
load File.join(PADRINO_ROOT, "settings.rb")

require_relative "bbruby"
require_relative "warden"
require_relative "emoticons"

##
# ## Enable devel logging
#
# Padrino::Logger::Config[:development][:log_level]  = :devel
# Padrino::Logger::Config[:development][:log_static] = true
#
## Configure your I18n

I18n.available_locales = [:en, :de]
I18n.default_locale = Chessboard.config.default_locale
I18n.enforce_available_locales = true

# ## Configure your HTML5 data helpers
#
# Padrino::Helpers::TagHelpers::DATA_ATTRIBUTES.push(:dialog)
# text_field :foo, :dialog => true
# Generates: <input type="text" data-dialog="true" name="foo" />
#
# ## Add helpers to mailer
#
# Mail::Message.class_eval do
#   include Padrino::Helpers::NumberHelpers
#   include Padrino::Helpers::TranslationHelpers
# end

##
# Add your before (RE)load hooks here
#
Padrino.before_load do
end

##
# Add your after (RE)load hooks here
#
Padrino.after_load do
end

Padrino.load!

# Call the boot hook to allow plugins to initialize themselves.
unless Chessboard::Plugin.all_plugins.empty?
  Chessboard::Plugin::Evaluator.new.call_hook(:boot, :root => Chessboard::App.root)
end
