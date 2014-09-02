# -*- coding: utf-8 -*-
module Chessboard
  class App < Padrino::Application
    register ScssInitializer
    use ActiveRecord::ConnectionAdapters::ConnectionManagement
    register Padrino::Mailer
    register Padrino::Helpers

    enable :sessions

    use Warden::Manager do |manager|
      manager.default_strategies(*Chessboard.config.authentication_methods)
      manager.failure_app = App
      manager.serialize_into_session{|user| user.id}
      manager.serialize_from_session{|id| User.find(id.to_i)}
    end

    before do
      if env["warden"].authenticated?
        user = env["warden"].user

        # Check if the user has been banned, and if so, forcibly end his session.
        if Ban.matches_any?(user, request)
          env["warden"].logout
          flash[:alert] = I18n.t("bans.banned")
          redirect "/"
        end

        # Report active users
        ActiveUserInfo.add(user.nickname, user.settings.hide_status, Time.now)
      end
    end

    get "/" do
      redirect "/forums"
    end

    get "/unauthenticated" do
      logger.warn("Authentication failure for #{request.ip}")
      flash[:alert] = "Authentication failure."
      redirect "/login"
    end

    post "/unauthenticated" do
      logger.warn("Authentication failure for #{request.ip}")
      flash[:alert] = "Authentication failure."
      redirect "/login"
    end

    get "/login" do
      if env["warden"].authenticated?
        redirect "/forums"
      else
        render "misc/login"
      end
    end

    post "/login" do
      halt 400 if env["warden"].authenticated?

      user = env["warden"].authenticate!
      env["warden"].user.last_login = Time.now
      env["warden"].user.save

      # Delete those warnings that have expired
      user.received_warnings.each{|warning| warning.expire!}

      flash[:notice] = "Logged in successfully."
      logger.info("Successful authentification for user #{user.nickname} from IP #{request.ip}")

      redirect "/forums"
    end

    get "/logout" do
      if env["warden"].authenticated?
        env["warden"].logout
        flash[:notice] = "Logged out successfully."
      end
      redirect "/forums"
    end

    get "/register" do
      redirect url(:users, :user_new)
    end

    get "/personal" do
      env["warden"].authenticate!
      @user = env["warden"].user
      render "misc/personal"
    end

    post "/preview", :provides => [:json] do
      halt 400 unless request.xhr?
      halt 400 unless params["text"]
      halt 400 unless params["markup_language"]

      {:text => process_markup(params["text"], params["markup_language"])}.to_json
    end

    ########################################
    # HTTP error handling

    error 403 do
      [403, render("errors/403")]
    end

    error 404 do
      [404, render("errors/404")]
    end

    error 500 do
      [500, render("errors/500")]
    end

    ########################################
    # Special exception handling

    error ActiveRecord::RecordNotFound do
      logger.info "Showing ActiveRecord::RecordNotFound (#{env['sinatra.error'].message}) as 404."
      [404, render("errors/404")]
    end

    ########################################
    # Mailer

    # Use mailcatcher in development
    configure :development do
      Thread.abort_on_exception = true

      set :delivery_method, :smtp => {
        :address => "localhost",
        :port => 1025
      }
    end

    # No mailer in testing mode
    configure :test do
      set :delivery_method, :test
    end

    # Use user’s settings in production
    configure :production do
      set :delivery_method, Chessboard.config.mail[:type] => Chessboard.config.mail[:options]
    end

  end
end
