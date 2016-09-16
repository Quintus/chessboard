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

    Chessboard::User[session["user"].to_i]
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

  # Process +str+ as markdown and return the corresponding HTML.
  def process_markup(str)
    Chessboard::EmailDocument.debug_preprocessor = true
    k = Chessboard::EmailDocument.new(str, :enable_coderay => true)
    k.to_html
  end

  # A much more unobtrusive version of #process_markup
  # that returns a <pre> element.
  def process_raw(str)
    r = Chessboard::RawDocument.new(str)
    r.to_html
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
  def add_to_querystr(key, value)
    str = "?#{request.query_string.dup}"

    unless str == "?"
      str << "&"
    end

    str << CGI.escape(key.to_s) << "=" << CGI.escape(value.to_s)
    request.path + str
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

  def send_registration_email(user)
    link = sprintf("%s/users/%d/confirm/%s",
                   Chessboard::Configuration[:board_url],
                   user.id,
                   user.confirmation_string)

    mail = Mail.new
    mail.subject = t.users.registration_email_subject.to_s
    mail.from = Chessboard::Configuration[:board_email]
    mail.to   = user.email
    mail.body = t.users.registration_email_body(user.current_alias,
                                                Chessboard::Configuration[:board_url],
                                                link,
                                                user.confirmation_expiry_time.strftime("%Y-%m-%d %H:%M")).to_s
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

The reporting user was #{user.current_alias} (#{user.email}).
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
