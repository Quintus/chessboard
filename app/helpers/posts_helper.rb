# Helper methods defined here can be accessed in any controller or view in the application

module Chessboard
  class App
    module PostsHelper

      def process_markup(text, markup)
        str = "process_#{markup.downcase}"
        if respond_to?(str)
          send(str, text)
        else
          raise(ArgumentError, "Unknown markup language '#{markup}'!")
        end
      end

      def process_markdown(text)
        kdoc = Kramdown::Document.new(text, :auto_ids => false, :remove_block_html_tags => true, :remove_span_html_tags => true)
        kdoc.to_remove_html_tags
        kdoc.to_html.html_safe
      end

      def process_bbcode(text)
        BBRuby.to_html_with_formatting(text).html_safe
      end

    end

    helpers PostsHelper
  end
end
