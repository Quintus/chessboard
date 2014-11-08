# -*- coding: utf-8 -*-

# = Mention plugin
#
# Plugin that sends email for GitHub-like @ mentions.
# Only works for creating topics and posts, not for editing them.
#
# == Configuration
# None.
module MentionPlugin
  include Chessboard::Plugin

  # Regular expression for extracting @ mentions.
  # ">" is for closing HTML tag
  FIND_MENTION_REGEXP = /(^|\s|>)(@[[:alnum:]]+)/

  # Template for the email sent do mentioned users.
  MENTION_EMAIL = Erubis::Eruby.new(<<-EMAIL)
Hi <%= nickname %>,

you have been mentioned in this thread:

<%= post_url %>

The post was:

<%= text.lines.map{|l| "> \#{l}"}.join("") %>

Best regards,
Chessboard mail system

--
You are receiving this mail as a member of the forum at <%= boardlink %>.
  EMAIL

  def hook_hlpr_post_markup(options)
    result = super

    result.gsub(FIND_MENTION_REGEXP) do
      "#$1<strong class='mention'>#$2</strong>"
    end
  end

  def hook_ctrl_post_create_final(options)
    super

    find_mentions(options[:post], options[:request])
  end

  def hook_ctrl_topic_create_final(options)
    super

    find_mentions(options[:topic].posts.first, options[:request])
  end

  private

  def find_mentions(post, request)
    text = post.content
    board_link = request.ssl? ? "https://#{Chessboard.config.domain}/" : "http://#{Chessboard.config.domain}/"

    text.scan(FIND_MENTION_REGEXP) do |ary|
      user = User.find_by(:nickname => ary[1][1..-1]) # [1..-1] removes leading @
      next unless user

      mail         = Mail.new
      mail.from    = "automailer@" + Chessboard.config.domain
      mail.to      = user.email
      mail.subject = "You have been mentioned"
      mail.body    = MENTION_EMAIL.result(:nickname => user.nickname, :text => text, :post_url => board_link.chop + url(:posts, :show, post.topic.id, post.id), :boardlink => board_link)

      # Don’t send mail in test mode
      next if Chessboard::App.delivery_method.keys.first == :test

      # Copy mail settings from main application
      mail.delivery_method Chessboard::App.delivery_method.keys.first, Chessboard::App.delivery_method.values.first

      logger.debug("Delivering mention email to #{ary[0]}.")

      mail.deliver
    end
  end

end
