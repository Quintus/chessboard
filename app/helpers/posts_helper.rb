# Helper methods defined here can be accessed in any controller or view in the application

module Chessboard
  class App
    module PostsHelper

      def process_markup(text, markup)
        if markup == Post::DEFAULT_MARKUP_LANGUAGE
          result = markup_default(text)
        elsif lang = Chessboard::Plugin.plugin_markup_languages.find{|m| m.name == markup}
          evaluator = Chessboard::Plugin::Evaluator.new
          result = evaluator.send(lang.implementation, text)
        else
          raise(ArgumentError, "Unknown markup language '#{markup}'!")
        end

        result = replace_emoticons(result)

        call_hook(:hlpr_post_markup, :html => result).html_safe
      end

      def markup_default(text)
        BBRuby.to_html_with_alternative_formatting(text)
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

      def post_url(post)
        url(:posts, :show, post.topic.id, post.id)
      end

    end

    helpers PostsHelper
  end
end
