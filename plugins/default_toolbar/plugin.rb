# -*- coding: utf-8 -*-

# = Toolbar plugin
#
# This plugin provides Chessboard’s default toolbar used
# when creating new posts or replying. Currently for Markdown
# only the emoticons toolbar is provided, BBCode also has a
# tool toolbar with buttons to insert BBCode.
#
# == Configuration
# None.
module DefaultToolbarPlugin
  include Chessboard::Plugin

  # All tools which appear in the BBCode toolbar. :code is what
  # gets inserted, :show is what the button is labelled. The main
  # key is used as an identifier for JavaScript.
  BB_TAGS = {
    "bold"      => {:code => "[b][/b]", :show => "<strong>b</strong>"},
    "italics"   => {:code => "[i][/i]", :show => "<em>i</em>"},
    "underline" => {:code => "[u][/u]", :show => "<span style='text-decoration: underline'>u</span>"},
    "url"       => {:code => "[url][/url]", :show => "[url]"},
    "fullurl"   => {:code => "[url=][/url]", :show => "[url=]"},
    "img"       => {:code => "[img][/img]", :show => "[img]"},
    "quote"     => {:code => "[quote][/quote]", :show => "[quote]"},
    "code"      => {:code => "[code][/code]", :show => "[code]"},
    "list"      => {:code => "[list][/list]", :show => "[list]"},
    "olist"     => {:code => "[list=1][/list]", :show => "[list=1]"}
  }

  def hook_html_header(options)
    str = super
    str = content_tag("style", :type => "text/css") do
<<CSS.html_safe
.toolbar ul {
  margin: 0px;
  list-style-type: none;
  padding: 0px;
}
.toolbar ul li {
  display: inline-block;
  margin-left: 4px;
}
.tool-emoticon {
  cursor: pointer;
}
.toolbar .tools li {
  background-color: white;
  border: 1px solid #AAAAAA;
  padding: 2px;
  min-width: 30px;
  text-align: center;
  cursor: pointer;
}
CSS
    end

    str += content_tag("script", :type => "text/javascript") do
<<JS.html_safe
$(document).ready(function(){
  $(".tool-emoticon").click(function(){
    $("#post_content, #personal_post_content, #topic_posts_attributes_0_content, #personal_message_posts_attributes_0_content").insertAtCaret(":" + $(this).attr("alt") + ":");
  });

  #{
  BB_TAGS.reduce("".html_safe) do |str, (ident, hsh)|
    str + %Q<$("#tool-#{ident.html_safe}").click(function(){
      $("#post_content, #personal_post_content, #topic_posts_attributes_0_content, #personal_message_posts_attributes_0_content").insertAtCaret("#{hsh[:code].html_safe}");
    });>.html_safe + "\n".html_safe
  end
  }
});
JS
    end

    str
  end

  def hook_view_reply_pre_content(options)
    super + content_tag("div", :class => "toolbar") do
      result = "".html_safe

      if options[:post].markup_language == "BBCode"
        result += content_tag("ul", :class => "tools") do
          BB_TAGS.reduce("".html_safe) do |str, (ident, hsh)|
            li = content_tag("li", :class => "tool", :id => "tool-#{ident}"){hsh[:show].html_safe}

            str + li
          end
        end
      end

      result += content_tag("ul", :class => "emoticons") do
        Chessboard.config.emoticons.reduce("".html_safe) do |str, emoticon|
          li = content_tag("li") do
            image_tag("emoticons/#{Chessboard.config.emoticons_set}/#{emoticon}.gif", :alt => emoticon, :class => "tool-emoticon")
          end

          str + li
        end
      end

      result
    end
  end

  def hook_view_pm_reply_pre_content(options)
    super + hook_view_reply_pre_content(options)
  end

end
