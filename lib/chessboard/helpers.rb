# coding: utf-8
# This module encapsulates the chessboard-specific helper methods that
# are available in the main sinatra router and the views.
module Chessboard::Helpers

  # Returns true if the user is logged in, false otherwise.
  def logged_in?
    !!session["user"]
  end

  # If a user is logged in (see #logged_in?), returns the User
  # instance representing the user. Otherwise returns nil.
  def logged_in_user
    return nil unless logged_in?

    # Cache the logged in user to not always query the database
    # for each call to #logged_in_user.
    env["chessboard.logged_in_user"] ||= nil
    if env["chessboard.logged_in_user"] && env["chessboard.logged_in_user"].id == session["user"].to_i
      # Normal case. The same user has made some more requests,
      # return the cached version.
      env["chessboard.logged_in_user"]
    else
      # User has logged in; note that it may be a log in under a
      # new user ID (in that case the part behind the && above
      # triggers). In any case, renew the cache.
      env["chessboard.logged_in_user"] = Chessboard::User[session["user"].to_i]
    end
  end

  # Convenience method for calling Sinatra's halt method
  # with an argument of 400 (authentication error).
  def require_log_in!
    halt 400 unless logged_in?
  end

  # Escape HTML content in +str+.
  def h(str)
    CGI.escapeHTML(str)
  end

  # If vaue is trueish, return the string 'checked="checked"', otherwise
  # return an empty string. This is useful when building forms with
  # checkboxes to tick them based on a model value.
  def checked(value)
    value ? 'checked="checked"' : ""
  end

  # Store +str+ in the user session. Returns it again
  # if +str+ is ommitted, clearing it from the session.
  def message(str = nil)
    if str
      session[:message] = str
    else
      session.delete(:message)
    end
  end

  # Checks if #message without an argument would return something
  # other than nil.
  def message?
    !!session[:message]
  end

  # Like #message, but for other messages, namely alerts.
  def alert(str = nil)
    if str
      session[:alert] = str
    else
      session.delete(:alert)
    end
  end

  # Like #message?, but for alerts.
  def alert?
    !!session[:alert]
  end

  # A much more unobtrusive version of #process_markup
  # that returns a <pre> element.
  def process_email(str)
    if ENV["RACK_ENV"] == "production"
      begin
        r = Chessboard::EmailDocument.new(str)
        r.to_html
      rescue => e
        # This is an archive, it must not be unable to display a message just
        # because some weird message fails to parse. Log the incident still so
        # that the parser can later be improved.
        Chessboard::Application.logger.error("#{e.class.name}: #{e.message}: #{e.backtrace.join("\n")}")
        Chessboard::Application.logger.error("Failed to process this, returning raw unprocessed text")
        str
      end
    else
      # If not running in production, crash it so the problem
      # can more easily be debugged.
      r = Chessboard::EmailDocument.new(str)
      r.to_html
    end
  end

  # Return a URL to this post, adapting to the user's configuration
  # view mode if available, otherwise defaulting to the global default
  # view mode.
  # If +honor_view_mode+ is true (default), then the link is made to
  # the logged in user's configured view mode (thread or topic view).
  # Otherwise it is made to the default view mode.
  def post_url(post, honor_view_mode = true)
    view_mode = Chessboard::Configuration[:default_view_mode]

    if honor_view_mode && logged_in?
      view_mode = logged_in_user.view_mode
    end

    "/forums/#{post.forum_id}/#{view_mode}/#{post.id}"
  end

  # Append the given key-value pair to this URL's query string
  # and return the resulting full path such that it can be
  # used in an anchor tag's HREF attribute.
  # Does return the current full path including query string
  # without any modification if the current query string
  # already includes this key-value pair.
  def add_to_querystr(key, value)
    newelement = CGI.escape(key.to_s) + "=" + CGI.escape(value.to_s)
    if request.query_string.include?(newelement)
      request.path + "?" + request.query_string
    else
      str = "?#{request.query_string}"

      unless str == "?"
        str << "&"
      end

      str << newelement
      request.path + str
    end
  end

  # Takes a number and formats it as a byte size with appropriate
  # size suffix (B, KiB, MiB, GiB).
  def readable_bytesize(number)
    case number
    when 0..1024                                   then "#{number}&nbsp;B"
    when (1024..(1024*1024))                       then "#{number/1024}&nbsp;KiB"
    when ((1024*1024)..(1024*1024*1024))           then "#{number/1024/1024}&nbsp;MiB"
    when ((1024*1024*1024)..(1024*1024*1024*1024)) then "#{number/1024/1024/1024}&nbsp;GiB"
    else
      "#{number/1024/1024/1024}&nbsp;GiB"
    end
  end

  # Display an error message to the user when the template of this handler
  # is rendered that says he made an input error.
  def user_error!
    @user_error = true
  end

  # Returns true if #user_error! was called during the handling of this request,
  # nil otherwise.
  def user_error?
    @user_error
  end

  def send_registration_email(user)
    link = sprintf("%s/users/%d/confirm/%s",
                   Chessboard::Configuration[:board_url],
                   user.id,
                   user.confirmation_string)

    mail = Mail.new
    mail.subject = t.users.registration_email_subject.to_s
    mail.from = Chessboard::Configuration[:board_email]
    mail.to   = user.email
    mail.body = t.users.registration_email_body(user.uid,
                                                Chessboard::Configuration[:board_url],
                                                link,
                                                user.confirmation_expiry_time.strftime("%Y-%m-%d %H:%M")).to_s
    mail.charset = 'UTF-8'
    mail.content_transfer_encoding = '8bit'
    mail.deliver
  end

  def send_report_mail(post, user)
    mail = Mail.new
    mail.subject = "Post Abuse Report"
    mail.from = Chessboard::Configuration[:board_email]
    mail.to   = Chessboard::Configuration[:admin_email]
    mail.body =<<REPORT
Hi,

this post has been reported as abuse:

  #{Chessboard::Configuration[:board_url]}#{post_url(post)}

The reporting user was #{user.uid} (#{user.email}).
The report was filed on #{Time.now.utc.strftime('%Y-%m-%d %H:%M %z')}.

A copy of the post is below.

******************** Copy ********************
From:    #{post.used_alias} <#{post.author.email}>
To:      #{post.forum.mailinglist}
Date:    #{post.created_at.strftime('%Y-%m-%d %H:%M:%S %z')}
Subject: #{post.title}

#{post.content}
************** End of Post Copy **************
REPORT

    mail.charset = 'UTF-8'
    mail.content_transfer_encoding = '8bit'
    mail.deliver
  end

  def generate_registration_token(user)
    token = Array.new(5){ ("A".."Z").to_a.sample }
    token.concat(Array.new(5) { user.email.chars.to_a.sample })
    token << (Time.now.utc.sec * 2).to_s
    token.concat(Array.new(user.email.chars.inject(0){|sum, c| sum + c.ord} % 6))
    token.concat(Array.new(5){ ("1".."9").to_a.sample })
    token.join("")
  end

end
