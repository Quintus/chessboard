class Chessboard::RawDocument

  # Maximum length of a single line.
  MAX_LINE_LENGTH = 100

  def initialize(text, options = {})
    @text = text.dup
    @options = options
    @options[:break_long_lines] ||= false
  end

  def to_html
    process_raw
  end

  private

  def process_raw
    # 0. Remove carriage returns
    @text.gsub!("\r", "")

    # 1. Mask all mail addresses
    @text.gsub!(/@.*?(\>|\s|$)/, '@xxxxxxx\\1')

    # 2. Forcibly break lines longer than 100 characters. Some email
    # clients are just stupid with regard to text mail.
    @text = break_long_lines(@text) if @options[:break_long_lines]

    # 3. Escape all HTML
    @text = CGI.escape_html(@text)

    # 4. Colourise quotes
    @text.gsub!(/^((&gt;)+)(.*?)$/) do
      if $1.length >= 3 * 4 # &gt; has 4 characters
        '<span class="ml-quote-n">' + $1 + $3 + '</span>'
      elsif $1.length == 2 * 4
        '<span class="ml-quote-2">' + $1 + $3 + '</span>'
      elsif $1.length == 1 * 4
        '<span class="ml-quote-1">' + $1 + $3 + '</span>'
      else # Should not happen
        $&
      end
    end

    # 5. Make links links
    @text.gsub!(%r!(https?|ftps?)://(.*?)(\s|&gt;|\)|\]|\})!){ %Q!<a href="#{$1}://#{$2}">#{$1}://#{$2}</a>#{$3}! }

    '<pre>' + @text + '</pre>'
  end

  def break_long_lines(str)
    lines = str.lines.to_a
    index = 0
    until index >= lines.count
      line = lines[index]

      if line.length > MAX_LINE_LENGTH
        replacement = ""
        charidx = 0
        line.each_char.with_index do |char, ci|
          if charidx >= MAX_LINE_LENGTH
            # Break the line at the next space, ensuring that quotes do
            # not break up by adding > in front of the newliny inserted
            # line if required.
            if char =~ /\s/
              replacement << "\n"
              replacement << $& if ci < line.chars.count - 1 && line =~ /^>\s?/
              charidx = 0
            else
              replacement << char
            end
          else
            replacement << char
          end
          charidx += 1
        end

        lines[index] = replacement
      end

      index += 1
    end

    lines.join("")
  end

end
