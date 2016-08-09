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
  # Note that line breaks in the input are *preserved*!
  def process_markup(str)
    # Remove emailish newlines
    str.gsub!("\r\n", "\n")

    # Remove inline PGP. We cannot usefully include it because we
    # display the mail signature as a distinct element. This does not
    # hurt because people can still view the raw content if they want
    # to verify the signature.
    str.sub!(/^(\-+)BEGIN PGP SIGNED MESSAGE\1.*?\n\n(.*)\1BEGIN PGP SIGNATURE\1.*\1END PGP SIGNATURE\1$/m) do
      "[ PGP inline signed message; view raw format to verify the signature ]\n{:.pgp-inline}\n\n#$2"
    end

    # Cut off signature and ensure it always is a code block.
    # The signature is appended later again.
    # (many people use ASCII art in their signature).
    str.sub!(/^-- ?$(.*)\z/m, "")
    signature = $1 ? "\n\n~~~~~~~~~~\n#{$1.strip}\n~~~~~~~~~~\n{:.signature}" : ""

    # Fix links not surrounded with angle brackets.
    # Link reference definitions need to be excluded.
    str.gsub!(/(?<!\]:)([^<])(http|https|ftp):\/\/(.+)([^>])/, '\1<\2://\3>\4')

    # Obsure email addresses
    str.gsub!(/@[a-z0-9\.]+?\.\w+/i, "@xxxxxxxxxx")

    # Center lines with more than 4 spaces at the beginning, unless
    # preceeded by a line with 4 spaces.
    newstr = ""
    encountered_4_spaces = false
    str.lines.each do |line|
      if line =~ /^( {4,})(.*)$/
        if $1.length == 4
          encountered_4_spaces = true
        else
          if encountered_4_spaces
            newstr << line
          else
            newstr << "#{line.strip}\n{:.center}\n\n"
          end
          next
        end
      else
        encountered_4_spaces = false
      end

      newstr << line
    end

    str = newstr
    newstr = ""

    # Ensure links on footer are referenced with proper colons, otherwise
    # it is invalid markdown.
    str.lines.each do |line|
      if line =~ /^\[(\d)\][^:]\s?((http:|https:|ftp:).*)$/
        newstr << "[#$1]: #$2\n"
      else
        # Fix incomplete references
        newstr << line.gsub(/([^\[\]\s]+)\[(\d+)\]/, '[\1][\2]')
      end
    end

    newstr = newstr + signature

    k = Kramdown::Document.new(newstr, :enable_coderay => true)
    k.to_html

    #r = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(:escape_html => true, :hard_wrap => true),
    #                            :autolink => true,
    #                            :tables => true,
    #                            :fenced_code_blocks => true,
    #                            :lax_spacing => false,
    #                            :space_after_headers => true)
    #r.render(str)
  end

end
