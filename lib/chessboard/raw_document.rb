class Chessboard::RawDocument

  # Maximum length of a single line.
  MAX_LINE_LENGTH = 100

  def initialize(text, options = {})
    @text = text.dup
    @options = options
    @options[:break_long_lines] ||= false

    # Some text preparation. Remove the noisy carriage returns and
    # mask all email addresses. Also escape all HTML.
    @text.gsub!("\r", "")
    @text.gsub!(/@.*?(\>|\s|$)/, '@xxxxxxx\\1')

    @scanner = StringScanner.new(@text)
    @mode = :normal
    @output = ""
  end

  def to_html
    @output.clear
    @scanner.reset
    process until @scanner.eos?
    @output
  end

  private

  def escape_html(str)
    CGI.escape_html(str)
  end

  def process
    case @mode
    when :normal    then process_normal
    when :quote     then process_quote
    when :codeblock then process_codeblock
    when :signature then process_signature
    when :link      then process_link
    else
      raise("Unknown scanning mode #{@mode} encountered; this is a bug.")
    end
  end

  def process_normal
    # Note that the ^ anchor does not work with StringScanner, since it
    # the slice it passes to the regexp engine is always a line start.
    # Therefore, it has the separate method #beginning_of_line?

    if @scanner.beginning_of_line?
      if str = @scanner.scan(/>+/)
        @mode = :quote
      elsif str = @scanner.scan(/~{3,}|`{3,}/)
        @output << str << @scanner.scan_until(/\n/) # A language indicator would be in this scan_until
        @mode = :codeblock
        @codeblock_delim = str
      elsif str = @scanner.scan(/^ {4,}|\t/)
        @mode = :codeblock
        @codeblock_delim = str

        # The whitespace should be part of the code in this case,
        # so reset the scanner to the beginning of the first line
        # of code.
        @scanner.unscan
      elsif str = @scanner.scan(/^-- ?\n/)
        @mode = :signature
      else
      # Normal character
        @output << escape_html(@scanner.getch)
      end
    elsif str = @scanner.scan(%r!(https?|ftps?)://!)
      @mode = :link
    else
      # Normal character
      @output << escape_html(@scanner.getch)
    end
  end

  def process_quote
    @scanner.unscan # Put the first ">" back on the stack

    level = 0
    last_level = 0
    loop do
      if @scanner.scan(/>/)
        level += 1
        if level > last_level
          @output << "<blockquote>"
        end
      else
        if level < last_level
          (last_level - level).times  do
            @output << "</blockquote>"
          end
        end

        if level == 0 # No ">" were scanned, i.e. the quote ended.
          break
        else
          last_level = level
          level = 0
          # Add the line to the actual quote content. Note that leading
          # space is stripped out so that both quotes like "> str" and ">str"
          # (note the space difference) look equal in the output.
          @output << @scanner.scan_until(/\n/).lstrip
        end
      end
    end

    @mode = :normal
  end

  def process_codeblock
    if @codeblock_delim =~ /^\s+$/ # Indented code block
      code = ""
      loop do
        if @scanner.beginning_of_line?
          if delim = @scanner.scan(/^#{@codeblock_delim}/)
            code << delim << @scanner.scan_until(/\n|\z/)
          elsif @scanner.scan(/\n/)
            # Empty line; a new indented part may follow, so do not terminate
            code << "\n"
          else
            # Something else than an indented line. Break.
            break
          end
        else
          # Not at and end of line? Should not happen
          Chessboard::Application.logger.warn("Unexpectedly ended up not at a line ending while parsing code")
          Chessboard::Application.logger.warn(@scanner.inspect)
          break
        end
      end

      guess_lang_and_hilit(code)
    else # Fenced code block
      code = ""
      until @scanner.scan(/^#{@codeblock_delim}/)
        code << @scanner.getch
      end

      guess_lang_and_hilit(code)
      @output << @scanner.matched
    end

    @codeblock_delim = nil
    @mode = :normal
  end

  def process_signature
    delim = @scanner.matched
    subdocument = self.class.new(@scanner.rest)
    @scanner.terminate # StringScanner#rest above does not advance the scan pointer

    @output << '<div class="signature">' << subdocument.to_html << '</div>'

    @mode = :normal
  end

  def process_link
    protocol = @scanner.matched
    path = @scanner.scan_until(/[[[:space:]]>\)\]\}\(\[\{]/).chop
    url = protocol + path

    @output << "<a href=\"#{url}\">#{url}</a>" << @scanner.matched
    @mode = :normal
  end

  #  # 1. Mask all mail addresses
  #  @text.gsub!(/@.*?(\>|\s|$)/, '@xxxxxxx\\1')
  #
  #  # 2. Forcibly break lines longer than 100 characters. Some email
  #  # clients are just stupid with regard to text mail.
  #  @text = break_long_lines(@text) if @options[:break_long_lines]
  #
  #  # 3. Escape all HTML
  #  @text = CGI.escape_html(@text)
  #
  #  # 4. Colourise quotes
  #  @text.gsub!(/^((&gt;)+)(.*?)$/) do
  #    if $1.length >= 3 * 4 # &gt; has 4 characters
  #      '<span class="ml-quote-n">' + $1 + $3 + '</span>'
  #    elsif $1.length == 2 * 4
  #      '<span class="ml-quote-2">' + $1 + $3 + '</span>'
  #    elsif $1.length == 1 * 4
  #      '<span class="ml-quote-1">' + $1 + $3 + '</span>'
  #    else # Should not happen
  #      $&
  #    end
  #  end
  #
  #  # 5. Highlight source code
  #  @text = highlight_sourcecode(@text)
  #
  #  # 6. Make links links
  #  @text.gsub!(%r!(https?|ftps?)://(.*?)(\s|&gt;|\)|\]|\})!){ %Q!<a href="#{$1}://#{$2}">#{$1}://#{$2}</a>#{$3}! }
  #
  #  '<pre>' + @text + '</pre>'
  #end

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

  def guess_lang_and_hilit(code)
    lang = Chessboard::Configuration[:hilit_heuristic].call(code)
    if lang
      @output << '<div class="CodeRay"><div class="code"><pre>' << CodeRay.scan(code, lang).html << '</pre></div></div>'
    else # Not perceived as code
      @output << code
    end
  end

end
