# Helper methods defined here can be accessed in any controller or view in the application

module Chessboard
  class App
    module PostsHelper

      def process_markup(text, markup)
        str = "markup_#{markup.downcase}"
        if respond_to?(str)
          result = send(str, text)
        else
          raise(ArgumentError, "Unknown markup language '#{markup}'!")
        end

        replace_emoticons(result).html_safe
      end

      def markup_markdown(text)
        kdoc = Kramdown::Document.new(text, :auto_ids => false, :remove_block_html_tags => true, :remove_span_html_tags => true)
        kdoc.to_remove_html_tags
        kdoc.to_html
      end

      def markup_bbcode(text)
        BBRuby.to_html_with_formatting(text)
      end

      def replace_emoticons(text)
        # Step 1: Common smileys :-) :-( ;-)
        text = text.gsub(/:-?\)/, %Q!<img src="/images/emoticons/#{Chessboard.config.emoticons_set}/smile.gif" alt="smile"/>!)
          .gsub(/:-?\(/, %Q!<img src="/images/emoticons/#{Chessboard.config.emoticons_set}/sad.gif" alt="sad"/>!)
          .gsub(/;-?\)/, %Q!<img src="/images/emoticons/#{Chessboard.config.emoticons_set}/wink.gif" alt="wink"/>!)

        # Step 2: Extended smiley escape sequence
        text.gsub!(Chessboard.config.extended_emoticons_regexp) do
          bare = $&.tr(":", "")
          %Q!<img src="/images/emoticons/#{Chessboard.config.emoticons_set}/#{bare}.gif" alt="bare"/>!
        end

        text
      end

    end

    helpers PostsHelper
  end
end
