# -*- ruby -*-
source 'https://rubygems.org'

# Distribute your app as a gem
# gemspec

# Server requirements
# gem 'thin' # or mongrel
# gem 'trinidad', :platform => 'jruby'

# Optional JSON codec (faster performance)
# gem 'oj'

# Project requirements
gem 'rake'
gem "kramdown"
gem "coderay"
gem "bb-ruby"
gem "fabrication"
gem "faker"
gem "warden"
gem "bcrypt"
gem "mini_magick"
gem "paint"

# Component requirements
gem 'sass'
gem 'erubis', '~> 2.7.0'
gem 'activerecord', '>= 3.1', :require => 'active_record'
gem 'sqlite3', :group => "sqlite"
gem "pg", :group => "postgres"

# Test requirements
gem 'minitest', :require => 'minitest/autorun', :group => 'test'
gem 'rack-test', :require => 'rack/test', :group => 'test'

# Padrino Stable Gem
gem 'padrino', '0.12.3'

# Plugins
Dir["plugins/*/Gemfile"].sort.each do |path|
  puts "Loading plugin Gemfile '#{path}'"

  # This is necessary to trick bundler into thinking that the plugin
  # Gemfiles are part of the main Gemfile.
  eval(File.read(path), binding)
end
