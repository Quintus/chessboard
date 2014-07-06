# -*- coding: utf-8 -*-

# Plugin that sends email for GitHub-like @ mentions.
# Only works for creating topics and posts, not for editing them.
module MentionPlugin
  include Chessboard::Plugin

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

    result.gsub(/(^|\s)(@[[:alnum:]]+)/) do
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

    text.scan(/(?:^|\s)@([[:alnum:]]+)/) do |ary|
      user = User.find_by(:nickname => ary[0])
      next unless user

      mail         = Mail.new
      mail.from    = "automailer@" + Chessboard.config.domain
      mail.to      = user.email
      mail.subject = "You have been mentioned"
      mail.body    = MENTION_EMAIL.result(:nickname => ary[0], :text => text, :post_url => board_link.chop + url(:topics, :show, post.topic.id) + "#p#{post.id}", :boardlink => board_link)

      # Don’t send mail in test mode
      next if Chessboard::App.delivery_method.keys.first == :test

      # Copy mail settings from main application
      mail.delivery_method Chessboard::App.delivery_method.keys.first, Chessboard::App.delivery_method.values.first

      logger.debug("Delivering mention email to #{ary[0]}.")

      mail.deliver
    end
  end

end
