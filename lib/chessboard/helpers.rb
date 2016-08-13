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

  # Return a URL to this post, adapting to the user's configuration
  # view mode if available, otherwise defaulting to the global default
  # view mode.
  def post_url(post)
    view_mode = Chessboard::Configuration[:default_view_mode]

    if logged_in?
      view_mode = logged_in_user.view_mode
    end

    "/forums/#{post.forum.id}/#{view_mode}/#{post.id}"
  end

end
