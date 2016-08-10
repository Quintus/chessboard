# coding: utf-8
# This module encapsulates the chessboard-specific helper methods that
# are available in the main sinatra router and the views.
module Chessboard::Helpers

  # Returns true if the user is logged in, false otherwise.
  def logged_in?
    !!session["email"]
  end

  # If a user is logged in (see #logged_in?), returns the User
  # instance representing the user. Otherwise returns nil.
  def logged_in_user
    return nil unless logged_in?

    User.first(:email => session["email"])
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

  # Process +str+ as markdown and return the corresponding HTML.
  def process_markup(str)
    Chessboard::EmailDocument.debug_preprocessor = true
    k = Chessboard::EmailDocument.new(str, :enable_coderay => true)
    k.to_html
  end

end
