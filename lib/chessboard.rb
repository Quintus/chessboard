require "sinatra/base"
require "sinatra/content_for"
require "sinatra/r18n"
require "kramdown"
require "net/ldap"
require "sequel"
require "bcrypt"
require "mail"
require "mini_magick"
require "rb-inotify"
require "logger"
require "json"
require "syslog"
require "syslog/logger"
require "digest/md5"
require "cgi"

# Load configuration as early as possible
require_relative "chessboard/configuration"
require_relative "../config.rb"
require_relative "chessboard/helpers"

# Namespace of this program.
module Chessboard

  # Convenience method for calling Chessboard::Application.logger.
  def self.logger
    Chessboard::Application.logger
  end

  # Version number of this program.
  VERSION = "0.1.0".freeze

  # Main Sinatra application class.
  class Application < Sinatra::Base
    register Sinatra::R18n
    helpers Sinatra::ContentFor
    helpers Chessboard::Helpers

    set :root, File.expand_path(File.join(File.dirname(__FILE__), ".."))

    enable :sessions

    configure :development do
      set :logger, Logger.new($stdout)

      # Always use the same session secret in development so one
      # doesn't have to log in all the time when restarting the server.
      set :session_secret, "xu6yiechiG8cuuy6Heiv"

      MiniMagick.logger = logger
      DB = Sequel.connect("sqlite://#{root}/db/development.db3", :loggers => [logger])

      # In development deliver mails to mailcatcher.
      Mail.defaults do
        delivery_method :smtp, :address => "localhost", :port => 1025
      end
    end

    configure :production do
      if Configuration[:log] == :syslog
        # Note: Syslog::Logger.new takes a facility since Ruby 2.1.0. Before
        # it was impossible to specify a facility.
        set :logger, Syslog::Logger.new("chessboard", Syslog.const_get("LOG_#{Configuration[:log_facility].upcase}"))
      else
        set :logger, Logger.new(Configuration[:log_file])
      end

      # The Sequel database instance. No SQL logger when run in production.
      DB = Sequel.connect(Configuration[:database_url])

      # In production deliver mails via sendmail.
      Mail.defaults do
        delivery_method :sendmail, :location => Chessboard::Configuration[:sendmail_path]
      end
    end

    error do
      # Sinatra's own #logged method does not work in an error handler (contains a Rack::NullLogger)
      Chessboard::Application.logger.error("#{env["sinatra.error"].class}: #{env["sinatra.error"].message}: #{env["sinatra.error"].backtrace.join("\n")}")
      erb :err_500
    end

    not_found do
      erb :err_404
    end

    error 401 do
      @login_required = true
      erb :login
    end

    error 403 do
      # Sinatra's own #logged method does not work in an error handler (contains a Rack::NullLogger)
      Chessboard::Application.logger.warn("#{request.ip} (#{logged_in? ? logged_in_user.email : "not logged in"}) tried to access specifically secured resource #{request.path} without necessary privileges")
      erb :err_403
    end

    get "/" do
      redirect "/forums"
    end

    get "/login" do
      @login_required = false
      erb :login
    end

    post "/login" do
      user = User.first(:email => params["email"])

      if user && user.authenticate(params["password"])
        message t.general.logged_in_successfully
        session["user"] = user.id
        redirect "/"
      else
        [400, t.general.login_failure]
      end
    end

    get "/logout" do
      halt 403 unless logged_in?
      session["user"] = nil
      redirect "/"
    end

    get "/forgotpw" do
      erb :forgotpw
    end

    post "/forgotpw" do
      user = User.first(:email => params["email"])
      halt 400 unless user

      new_pw = user.reset_password!
      Mail.deliver do
        from Chessboard::Configuration[:board_email]
        to user.email
        subject "Password reset"
        body <<EOF
Hi #{user.display_name},

you have used the password reset function to reset
your password. Your old password has been removed,
and your new password is:

    #{new_pw}

The next time you log into the website, use this
password and change it for security reasons.

-- 
Sent by Chessboard.
EOF
        # TODO: Use that user's locale setting for translating
        # the above email text.
      end

      message t.users.forgotpw.reset
      redirect "/"
    end

    get "/settings" do
      halt 401 unless logged_in?

      @user = logged_in_user
      erb :settings
    end

    post "/settings" do
      halt 401 unless logged_in?

      @user = logged_in_user

      @user.hide_status = params["hide_status"] == "1"
      @user.hide_email  = params["hide_email"]  == "1"
      @user.auto_watch  = params["auto_watch"]  == "1"
      @user.always_raw  = params["always_raw"]  == "1"
      @user.locale      = params["language"] if R18n.available_locales.map(&:code).include?(params["language"])

      unless params["password"].to_s.empty?
        if params["password"] != params["repeat_password"]
          alert t.settings.password_mismatch
          redirect "/settings"
        else
          @user.change_password(params["password"].to_s)
        end
      end

      # TODO: Rescue validation error
      @user.save

      if params["avatar"] && !params["delete_avatar"]
        begin
          image = MiniMagick::Image.open(params["avatar"][:tempfile].path)
          image.resize("80x80") if image.width > 80 || image.height > 80
          image.format "gif"
          image.write @user.avatar_path
        rescue => e
          alert t.settings.avatar_upload_failed
          logger.error("#{e.class}: #{e.message}: #{e.backtrace.join("\n\t")}")
        end
      elsif params["delete_avatar"]
        File.delete(@user.avatar_path) if File.file?(@user.avatar_path)
      end

      message t.settings.updated
      redirect "/settings"
    end

    get "/feed" do
      @posts = Post.order(Sequel.desc(:created_at)).limit(20).eager(:author)
      [200, {"Content-Type" => "application/atom+xml;charset=utf8"}, erb(:feed, :layout => false)]
    end

  end
end

# Now load the rest of the library
require_relative "chessboard/routes/forums"
require_relative "chessboard/routes/users"
require_relative "chessboard/routes/posts"
require_relative "chessboard/routes/admin"
require_relative "chessboard/ldap"
require_relative "chessboard/email_document"
require_relative "chessboard/raw_document"
require_relative "chessboard/user"
require_relative "chessboard/forum"
require_relative "chessboard/post"
require_relative "chessboard/tag"
require_relative "chessboard/attachment"
require_relative "chessboard/mailinglist_watcher"
