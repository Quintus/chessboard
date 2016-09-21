source "https://rubygems.org"

gem "sinatra"
gem "sinatra-contrib"
gem "sinatra-r18n"
gem "coderay"
#gem "kramdown"
gem "bcrypt"
gem "sequel"
gem "mail"
gem "rake"
gem "net-ldap"
gem "mini_magick"
gem "rb-inotify"

group :development do
  gem "hanna-nouveau"
  gem "sqlite3"
  gem "pg"
end

# If there's a Gemfile.local, load that one.
user_gemfile = File.join(File.expand_path(File.dirname(__FILE__)), "Gemfile.local")
eval_gemfile(user_gemfile) if File.exist?(user_gemfile)
