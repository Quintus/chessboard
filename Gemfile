# -*- ruby -*-
source 'https://rubygems.org'

# Project requirements
gem 'rake'
gem "kramdown"
gem "coderay"
gem "bb-ruby", "~> 1.0.4"
gem "fabrication", "~> 2.11.3"
gem "faker", "~> 1.4.3"
gem "warden", "~> 1.2.3"
gem "bcrypt", "~> 3.1.7"
gem "mini_magick", "~> 3.8.0"
gem "paint", "~> 0.8.7"

# Component requirements
gem 'sass', "~> 3.3.14"
gem 'erubis'
gem 'activerecord', '~> 4.2.4', :require => 'active_record'
gem 'sqlite3', :group => "sqlite"
gem "pg", :group => "postgres"

# Test requirements
gem 'minitest', :require => 'minitest/autorun', :group => 'test'
gem 'rack-test', :require => 'rack/test', :group => 'test'

# Padrino Stable Gem
gem 'padrino', '0.13.0'

# Plugins
Dir["plugins/*/Gemfile"].sort.each do |path|
  puts "Loading plugin Gemfile '#{path}'"

  # This is necessary to trick bundler into thinking that the plugin
  # Gemfiles are part of the main Gemfile.
  eval(File.read(path), binding)
end
