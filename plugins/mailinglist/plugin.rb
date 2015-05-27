# coding: utf-8
require "lmtp"

# = Mailinglist plugin
#
# This plugin allows you to mirror a mailinglist both for read
# and write access to your Chessboard forum. For incoming email,
# Chessboard acts as an LMTP server on a UNIX domain socket where
# you can direct your MTA (like Postfix) to deliver its mail to
# via the LMTP protocol.
#
# It currently is only possible to mirror one single mailinglist;
# multiple mailinglists are not possible. The mailinglist is mirrored
# to exactly one forum on the site.
#
# == Configuration
#
# Add the following to your settings.rb:
#
#   config.plugins.MailinglistPlugin = {
#     :socket_path => "/var/spool/postfix/chessboard",
#     :forum_id => 2,
#     :markup_language => "Preformatted",
#     :ml_address => "test-ml@example.invalid",
#     :from_address => "automailer@example.invalid"
#   }
#
# === Keywords
#
# [socket_path]
#   This is where the listening UNIX domain socket is created. Ensure
#   Chessboard has sufficient permissions to create a file in that
#   directory.
# [forum_id]
#   This is the ID of the target forum. You can find it in your
#   browser’s URL bar when you look at the target forum in your
#   browser.
# [markup_language]
#   The markup language which mails to the ML are assumed to be in.
#   This plugin adds a special markup language called "Preformatted",
#   which wraps the entire mail text body in a PRE tag. If you can’t
#   get your mailinglist users to use a uniform markup, this is probably
#   the best you can do.
# [ml_address]
#   The main email address of the mirrored mailinglist, i.e. where posts
#   are sent to when they are created on the website.
# [from_address]
#   The address to use in order to post to the mailinglist. Ensure this
#   address has a) write access to the mailinglist and b) does not receive
#   any posts from the mailinglist if you can’t handle skipping them on
#   your mail server.
module MailinglistPlugin
  include Chessboard::Plugin

  add_markup "Preformatted", :process => :markup_preformatted

  def markup_preformatted(text)
    '<pre class="ml-post">' + text + '</pre>'
  end

  def self.lmtp_thread
    @lmtp_thread ||= nil
  end

  def self.lmtp_thread=(val)
    @lmtp_thread = val
  end

  def hook_boot(options)
    super

    sock_path = Chessboard.config.plugins.MailinglistPlugin[:socket_path]
    MailinglistPlugin.lmtp_thread = Thread.new do
      begin
        lmtp_server = LmtpServer.new(sock_path, 0666){ |email| handle_incoming_email(Mail.new(email)) }

        lmtp_server.logging do |level, msg|
          case level
          when :debug   then logger.debug(msg)
          when :info    then logger.info(msg)
          when :notice  then logger.info(msg)
          when :alert   then logger.warn(msg)
          when :warning then logger.warn(msg)
          when :err     then logger.error(msg)
          when :crit    then logger.fatal(msg)
          else
            logger.warn(msg)
          end
        end

        lmtp_server.start
      rescue => e
        logger.error("LMTP server failed: #{e.class.name}: #{e.message}: #{e.backtrace.join('\n\t')}")
      end
    end
  end

  def hook_html_header(options)
    str = super
    str += content_tag("style", :type => "text/css") do
<<CSS.html_safe
pre.ml-post {
  overflow-y: visible;
  max-height: none;
}
CSS
    end

    str
  end

  def hook_ctrl_post_create_final(options)
    super

    # Exclude any posts not in the monitored forum
    return unless options[:post].topic.forum_id == Chessboard.config.plugins.MailinglistPlugin[:forum_id]

    mail = construct_common_mail(options[:env]["warden"], options[:post])
    mail.subject = "Re: #{options[:post].topic.title}"

    # Have the reply display nicely in the MUAs.
    topic = options[:post].topic
    prevpost_data = topic.posts.to_a[-2].plugin_data
    if prevpost_data[:MailinglistPlugin] && prevpost_data[:MailinglistPlugin][:ml_msgid]
      mail.in_reply_to = "<#{prevpost_data[:MailinglistPlugin][:ml_msgid]}>"

      # Try to at least rudimentaryly conform to section 3.6.4(10) of RFC 2822
      ary = []
      topic.posts.each do |replypost|
        if replypost.plugin_data[:MailinglistPlugin] && replypost.plugin_data[:MailinglistPlugin][:ml_msgid]
          ary << "<#{replypost.plugin_data[:MailinglistPlugin][:ml_msgid]}>"
        end
      end
      mail.references = ary
    else
      # Ignore. This happens if the posting was there before the ML
      # plugin was activated or if the previous post was an ML post
      # with X-no-archive set. #handle_incoming_mail doesn’t need the
      # References: header, X-Chessboard-Post: takes precedence.
    end

    logger.info("Sending reply to topic '#{topic.title}' to the mailinglist.")
    mail.deliver
  end

  def hook_ctrl_topic_create_final(options)
    super

    # Exclude any topics not in the monitored forum
    return unless options[:topic].forum.id == Chessboard.config.plugins.MailinglistPlugin[:forum_id]

    mail = construct_common_mail(options[:env]["warden"], options[:topic].posts.first)
    mail.subject = options[:topic].title

    Chessboard::App.logger.info("Sending new topic '#{options[:topic].title}' on website to mailinglist.")
    mail.deliver
  end

  private

  def handle_incoming_email(mail)
    # Honour user’s request to not save his article to the WWW
    return if mail["X-no-archive"] ||mail["X-No-Archive"]

    # If this mail has been generated by ourselves, i.e. it
    # has been generated when a user added a post on the website.
    if mail["X-Chessboard-Post"]
      post = Post.find(mail["X-Chessboard-Post"].decoded)
    else
      post = create_new_post_from_mail(mail)
    end

    post.plugin_data[:MailinglistPlugin] ||= {}

    if post.plugin_data[:MailinglistPlugin][:ml_msgid]
      # If a msgid is set, but X-Chessboard-Post exists, someone
      # is trying to trick us to overwrite the ID mappings.
      logger.warn("Detected crafted email that intended to overwrite an existing Message-ID mapping. Ignoring.")
      raise(LmtpServer::RejectMail.new(550, "5.7.0 Rejecting request to overwrite existing message ID. Do no set X-Chessboard-Post please."))
    end

    post.plugin_data[:MailinglistPlugin][:ml_msgid] = mail.message_id

    post.save!
    logger.debug("Post #{post.id} => Message-ID #{mail.message_id}")

    # In case of new posts via ML notify users watching this thread.
    unless mail["X-Chessboard-Post"]
      notify_subscribers(post, mail)
    end
  end

  def create_new_post_from_mail(mail)
    post                 = Post.new
    post.content         = extract_mail_body(mail)
    post.markup_language = Chessboard.config.plugins.MailinglistPlugin[:markup_language]
    post.created_at      = Time.now.utc # Do not use mail.date, because a malicious user
    post.updated_at      = Time.now.utc # could make his posts appear first in a topic otherwise.
    post.author          = extract_mail_author(mail)
    post.ip              = "::1" # Localhost

    # Check the mail headers to find the post the the reply was for.
    if mail.in_reply_to && mail.in_reply_to.kind_of?(String) && prevpost = find_post_by_messageid(mail.in_reply_to) # Single = intended; String test as we do not handle Array (multi-parent reply)
      logger.info "Reply to topic '#{prevpost.topic.title}' via mailinglist."
      topic = prevpost.topic
    elsif mail.references.kind_of?(String) && prevpost = find_post_by_messageid(mail.references) # Single = intended
      logger.info "Reply to topic '#{prevpost.topic.title}' via mailinglist."
      topic = prevpost.topic
    elsif mail.references.kind_of?(Array) && prevpost = mail.references.reverse.find{|msgid| find_post_by_messageid(msgid)}
      logger.info "Reply to topic '#{prevpost.topic.title}' via mailinglist."
      topic = prevpost.topic
    else
      # This can happen in three cases:
      # 1. New topic (intended case).
      # 2. Reply via ML to ML post that was there before the ML plugin was activated.
      # 3. Reply via ML to forum post that was there before the ML plugin was activated.
      # In all cases we make a new topic. For 3), we could with a lot of
      # guessing probably find the original topic, but that’s not worth the effort.

      logger.info "Creating new topic '#{mail.subject}' from mailinglist post."

      topic = Topic.new
      topic.title = mail.subject
      topic.forum = Forum.find(Chessboard.config.plugins.MailinglistPlugin[:forum_id])
      topic.author = post.author
    end

    post.topic = topic
    post
  end

  def extract_mail_author(mail)
    if user = User.where(:email => mail.from.first).first
      return user
    else
      User.where(:nickname => "Guest").first
    end
  end

  def extract_mail_body(mail)
    if mail.multipart?
      logger.debug("Orks. This is a multipart email.")

      if plain_part = mail.parts.find{|part| part.content_type =~ /^text\/plain;/i} # Single = intended
        logger.debug("Multipart email with plain/text part. Using that one.")
        text = plain_part.decoded.strip.force_encoding("UTF-8")
      else
        logger.warn("Multipart (ahem) email without text/plain part. Trying whatever is first.")
        text = CGI.escape_html(parts.first.decoded.strip.force_encoding("UTF-8"))
      end
    else
      logger.debug("Plaintext only email. Good.")
      text = mail.body.decoded.dup.force_encoding("UTF-8")
      # ↑ mail fails to set the encoding, and I won’t extract the charset from the Content-Type header. Bug: https://github.com/mikel/mail/issues/809
    end

    preamble = <<EOF
From: #{mask_address(mail.from.first)}
To:   #{mask_address(mail.to.first)}
Date: #{mail.date.strftime('%Y-%m-%d %H:%M %z')}
Subject: #{mail.subject}

EOF

   preamble + text
  end

  def mask_address(str)
    str.sub(/@.*(\>?|$)/, "@xxxxxxxxxx")
  end

  def construct_common_mail(warden, post)
    mail = Mail.new
    mail.from = Chessboard.config.plugins.MailinglistPlugin[:from_address]
    mail.reply_to = warden.user.email
    mail.to = Chessboard.config.plugins.MailinglistPlugin[:ml_address]
    mail["X-Chessboard-Topic"] = post.topic.id
    mail["X-Chessboard-Post"]  = post.id

    str = "Post via forum by #{warden.user.nickname} <#{mask_address(warden.user.email)}>:"
    str += "\n"
    str += post.content
    str += "\n\n" + "-- " + "\n" # The signature separator is "-- " (with space) per RFC.
    str += "Sent by Chessboard."
    mail.body = str

    # Copy mail settings from main application
    mail.delivery_method Chessboard::App.delivery_method.keys.first, Chessboard::App.delivery_method.values.first

    mail
  end

  def find_post_by_messageid(messageid)
    # Replies are more likely to happen on recent topics, thus fetch
    # the reverse list. This will keep the iteration interval as short
    # as possible.
    ary = Post.order(:id => :desc).pluck(:id, :plugin_data)
    subary = ary.find{ |id, hsh| hsh[:MailinglistPlugin] && hsh[:MailinglistPlugin][:ml_msgid] == messageid }

    if subary
      Post.find(subary.first)
    else
      nil
    end
  end

  def notify_subscribers(post, mail)
    post.topic.watchers.where.not(:id => post.author.id).pluck(:email, :nickname).each do |email_addr, nickname|
      deliver :posts, :watch_email, email_addr, nickname, post, url(:posts, :show, post.topic.id, post.id), url(:topics, :show, post.topic.id), "http://#{Chessboard.config.domain}/" # FIXME: HTTPS detection?
    end
  end

end
