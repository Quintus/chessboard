class Chessboard::EmailDocument

  # Maximum length of a single line.
  MAX_LINE_LENGTH = 100

  def initialize(text, options = {})
    @text = text.dup
    @options = options
    @options[:break_long_lines] ||= false

    # Some text preparation. Remove the noisy carriage returns and
    # mask all email addresses. Also escape all HTML.
    @text.gsub!("\r", "")
    @text.gsub!(/([[:alnum:]])@.+?(\>|\s|$)/, '\\1@xxxxxxx\\2')

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
        return
      elsif str = @scanner.scan(/~{3,}|`{3,}/)
        @output << str << @scanner.scan_until(/\n/) # A language indicator would be in this scan_until
        @mode = :codeblock
        @codeblock_delim = str
        return
      elsif str = @scanner.scan(/^ {4,}|\t/)
        @mode = :codeblock
        @codeblock_delim = str

        # The whitespace should be part of the code in this case,
        # so reset the scanner to the beginning of the first line
        # of code.
        @scanner.unscan
        return
      elsif str = @scanner.scan(/^-- ?\n/)
        @mode = :signature
        return
      end
    end

    if @scanner.scan(%r!(https?|ftps?)://!)
      @mode = :link
    elsif @scanner.scan(/\*[[:graph:]]+\*/)
      parse_inline_markup("<strong>", "</strong>")
    elsif @scanner.scan(%r!/[[:graph:]]+/!)
      parse_inline_markup("<em>", "</em>")
    elsif @scanner.scan(/_[[:graph:]]+_/)
      parse_inline_markup("<em class=\"underline\">", "</em>")
    elsif str = parse_emoticon
      @output << str
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
          @output << self.class.new(@scanner.scan_until(/\n|\z/).lstrip).to_html
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

    if path = @scanner.scan_until(/[[[:space:]]\n>\)\]\}\(\[\{]/)
      # Do not make the actual delimiter found with the above regexp
      # part of the link.
      path.chop!
    else
      # Link at end of string; most likely signature. Note \z
      # sets `@scanner.matched' to the empty string.
      path = @scanner.scan_until(/\z/)
    end
    url = protocol + path

    @output << "<a href=\"#{url}\">#{url}</a>" << @scanner.matched
    @mode = :normal
  end

  def parse_inline_markup(start, fin)
    mainstr = @scanner.matched

    # Check if this came behind a space or newline
    if @text[@scanner.pos - mainstr.size - 1] =~ /\s|\n/
      # Check if afterwards comes a space or newline or punctuation
      if @scanner.scan(/\s|\n|[[:punct:]]/)
        # Okay, this is inline markup. Format.
        @output << start << escape_html(mainstr) << fin << @scanner.matched
      else
        # Inter-word. Do not format.
        @output << escape_html(mainstr)
      end
    else
      # Inter-word. Do not format.
      @output << escape_html(mainstr)
    end
  end

  def parse_emoticon
    if @scanner.scan(/:-?D/)
      '<img src="/images/emoticons/biggrin.gif" alt="biggrin emoticon"/>'
    elsif @scanner.scan(/:-\?/)
      '<img src="/images/emoticons/confused.gif" alt="confused emoticon"/>'
    elsif @scanner.scan(/8-?\)/)
      '<img src="/images/emoticons/cool.gif" alt="feelcool emoticon"/>'
    elsif @scanner.scan(/:'-?\(/)
      '<img src="/images/emoticons/cry.gif" alt="cry emoticon"/>'
    elsif @scanner.scan(/O_o/)
      '<img src="/images/emoticons/eek.gif" alt="eek emoticon"/>'
    elsif @scanner.scan(/(^|\s)XD(\s|$)/) # Requires spaces/line edge so it is not processed inside a word
      $1 + ' <img src="/images/emoticons/lol.gif" alt="lol emoticon"/>' + $2
    elsif @scanner.scan(/:-?\|/)
      '<img src="/images/emoticons/neutral.gif" alt="neutral emoticon"/>'
    elsif @scanner.scan(/:-?\(\(/)
      '<img src="/images/emoticons/mad.gif" alt="mad emoticon"/>'
    elsif @scanner.scan(/:-?\(/)
      '<img src="/images/emoticons/sad.gif" alt="sad emoticon"/>'
    elsif @scanner.scan(/:-?\)|^_^/)
      '<img src="/images/emoticons/smile.gif" alt="smile emoticon"/>'
    elsif @scanner.scan(/:-?O/)
      '<img src="/images/emoticons/surprised.gif" alt="surprised emoticon"/>'
    elsif @scanner.scan(/;-?\)/)
      '<img src="/images/emoticons/wink.gif" alt="wink emoticon"/>'
    else
      nil
    end
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

  def guess_lang_and_hilit(code)
    lang = Chessboard::Configuration[:hilit_heuristic].call(code)
    if lang
      @output << '<div class="CodeRay"><div class="code"><pre>' << CodeRay.scan(code, lang).html << '</pre></div></div>'
    else # Not perceived as code
      @output << code
    end
  end

end
