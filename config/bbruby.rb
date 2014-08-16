# -*- coding: utf-8 -*-
require "strscan"

# Extensions/replacements for bb-ruby
module BBRuby
  @@tags.merge!("Code"=> ### Syntax highlighting ###
               [/\[code(=.+?)?\](.*?)\[\/code\1?\]/mi,
                lambda{|match|
                  lang = match[1]
                  content = CGI.unescape_html(match[2].strip)

                  # Legacy FluxBB highlighting language
                  if content =~ /^\[==(.*?)==\]$/
                    lang = $1.strip
                    content = $'.strip
                  elsif lang
                    lang.gsub!("=", "") # Remove equal sign from BBCode tag
                  end

                  if lang
                    lang = "cpp" if lang == "c++" # c++ was the old ID, but CodeRay wants cpp
                    begin
                      CodeRay.scan(content, lang).html(:wrap => :div, :line_numbers => :table, :css => :class)
                    rescue ArgumentError => e
                      "<pre>ERROR: #{e.message}</pre>"
                    end
                  else
                    "<pre>#{content}</pre>"
                  end
                },
                "Code Text with highlight",
                "[code=ruby]some code[/code]",
                :code],

                ### Unordered list compatible to FluxBB ###
                'Unordered List' => [/\[list(?:=\*)?\](.*?)\[\/list\]/mi,
                                     '<ul>\1</ul>',
                                     'Unordered list',
                                     'My favorite people (order of importance): [list][li]Jenny[/li][li]Alex[/li][li]Beth[/li][/list]',
                                     :unorderedlist],

                ### Ordered list compatible to FluxBB ###
                'Ordered List' => [/\[list=1\](.*?)\[\/list\]/mi,
                                   '<ol>\1</ol>',
                                   'Ordered list',
                                   'My favorite people (alphabetical order): [list=1][li]Jenny[/li][li]Alex[/li][li]Beth[/li][/list]',
                                   :orderedlist],

                ### List item compatible to FluxBB ###
                'List Item (alternative)' => [/\[\*\](.*?)(?:\[\/\*\]|$)/mi,
                                              '<li>\1</li>',
                                              'List item (alternative)',
                                              '[*]list item',
                                              :listitem],

                ### <fieldset> is overkill for quotes ###
                'Quote' => [
                            /\[quote(:.*)?=(?:&quot;)?(.*?)(?:&quot;)?\](.*?)\[\/quote\1?\]/mi,
                            '<blockquote><strong>\2:</strong><br/>\3</blockquote>',
                            'Quote with citation',
                            "[quote=mike]Now is the time...[/quote]",
                            :quote],

                ### <fieldset> is overkill for quotes ###
                'Quote (Sourceless)' => [/\[quote(:.*)?\](.*?)\[\/quote\1?\]/mi,
                                         '<blockquote>\2</blockquote>',
                                         'Quote (sourceclass)',
                                         "[quote]Now is the time...[/quote]",
                                         :quote],
               )

  # Similar to the original ::to_html_with_formatting, but does NOT
  # add newline formatting inside <pre> blocks, where it is undesired.
  def self.to_html_with_alternative_formatting(*args)
    text = process_tags(*args)

    ss = StringScanner.new(text)
    result = ""

    until ss.eos?
      if target_str = ss.scan_until(/<table class="CodeRay">/)
        result << format_paragraphs(target_str[0..-24]) << '<table class="CodeRay">' # Don’t format <table class="CodeRay"> tag start itself

        raw_str = ss.scan_until(/<\/table>/)
        result << raw_str
      elsif target_str = ss.scan_until(/<pre>/)
        result << format_paragraphs(target_str[0..-6]) << "<pre>" # Don’t format <pre> tag start itself

        raw_str = ss.scan_until(/<\/pre>/)
        result << raw_str
      else # No <pre> or <table class="CodeRay"> at all/anymore
        result << format_paragraphs(ss.rest)
        ss.terminate
      end
    end

    result
  end

  private

  def self.format_paragraphs(text)
    result = ""
    ss = StringScanner.new(text)

    # If the first thing we see is not an HTML tag, assume a paragraph.
    if text.lstrip.start_with?("<")
      in_p = false
    else
      result << "<p>"
      in_p = true
    end

    until ss.eos?
      if str = ss.scan_until(/\n+/)
        if in_p
          result << str.strip << "</p>"
          in_p = false
        elsif str.lstrip.start_with?("<") # HTML tag
          result << str.strip
        else
          result << "<p>" << str.strip << "</p>"
          in_p = false
        end
      else
        result << "<p>" << ss.rest.strip << "</p>"
        ss.terminate
      end
    end

    result
  end

end
