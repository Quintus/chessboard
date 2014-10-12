# -*- coding: utf-8 -*-
module MailinglistPlugin
  include Chessboard::Plugin

  # Regular expression used for marker-less MLs.
  NORMAL_REGEXP = /^(Re|Fw):\s+/
  # Regular expression used for MLs containing a "[mailinglist]" marker in the subject lines.
  MARKER_REGEXP = /^(Re|Fw):\s+\[.*?\]\s+/
  # Regular expression used to extract the subject for a new post on markered mailinglists.
  SUBJECT_MARKER_REGEXP = /^\[.*?\]\s+/

  add_markup "ML Markup", :process => :markup_ml_markup

  def self.inotify_thread
    @inotify_thread ||= nil
  end

  def self.inotify_thread=(val)
    @inotify_thread = val
  end

  def self.file_mutex
    @file_mutex ||= Mutex.new
  end

  def hook_boot(options)
    super

    ml_path = Chessboard.config.plugins.MailinglistPlugin[:ml_path]
    if !File.directory?(ml_path) || !File.readable?(ml_path)
      logger.error "Mailinglist directory '#{ml_path}' does not exist or is not readable. Disabling mailinglist read access."
      return
    end

    MailinglistPlugin.inotify_thread = Thread.new(ml_path) do |mlpath|
      notifier = INotify::Notifier.new
      notifier.watch(mlpath, :create) do |event|
        process_new_file(event.absolute_name)
      end

      logger.info "Starting inotify on '#{mlpath}'"
      notifier.run
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
  end

  # Markup parser target for the "ML Markup" markup, which is basically
  # just a <pre> tag around the text.
  def markup_ml_markup(text)
    "<pre class=\"ml-post\">" + text + "</pre>"
  end

  private

  def process_new_file(path)
    mail = Mail.read(path)

    post                 = Post.new
    post.content         = extract_mail_body(mail)
    post.markup_language = Chessboard.config.plugins.MailinglistPlugin[:markup_language]
    post.created_at      = mail.date
    post.updated_at      = mail.date
    post.author          = extract_mail_author(mail)
    post.ip              = "::1" # Localhost

    # Determine whether the ML subject headers contain a "[ml-name]" tag.
    # In that case we have to exclude that one from the subject when
    # processing; on the other hand, an "[ANN]" posting on a ML that does
    # not have markers in their subject lines should not get swallowed.
    if Chessboard.config.plugins.MailinglistPlugin[:bracket_marked_ml]
      regexp = MARKER_REGEXP
    else
      regexp = NORMAL_REGEXP
    end

    # If this is a reply to an existing thread
    if mail.subject =~ regexp
      real_title = $'
      topic      = Topic.where(:title => real_title).first

      unless topic
        # If we get here, a mail started with Re: although the corresponding topic
        # does not exist in the database. This may be the case for replies sent
        # right after the mailinglist plugin has first been activated, or for misformatted
        # subject lines (which may actually be a crosspost). We just create a new topic then.
        Chessboard::App.logger.warn("Mailinglist reply to nonexisting topic '#{mail.subject}', creating new topic.")
        topic        = Topic.new
        topic.title  = real_title
        topic.forum  = Forum.find(Chessboard.config.plugins.MailinglistPlugin[:forum_id])
        topic.author = post.author
        topic.save!
      end
    else # New topic
      Chessboard::App.logger.info("Creating new topic '#{mail.subject}' from mailinglist post.")

      topic        = Topic.new
      topic.forum  = Forum.find(Chessboard.config.plugins.MailinglistPlugin[:forum_id])
      topic.author = post.author

      if Chessboard.config.plugins.MailinglistPlugin[:bracket_marked_ml]
        if mail.subject =~ SUBJECT_MARKER_REGEXP
          topic.title = $'
        else
          # Malformed subject line, shouldn’t happen
          Chessboard::App.logger.warn("Malformed mailinglist subject line '#{mail.subject}', copying verbosely.")
          topic.title = mail.subject
        end
      else
        topic.title  = mail.subject
      end

      topic.save!
    end

    Chessboard::App.logger.info("Adding new mailinglist post to topic '#{topic.title}'.")
    post.topic = topic
    post.save!
  end

  # Extracts the plaintext body, or, if that fails, the HTML body and escapes it.
  # Returns the string "[unreadable message]" if the mail contains neither a
  # plaintext nor an HTML part.
  def extract_mail_body(mail)
    if mail.multipart?
      # First try the plaintext part.
      if plain_part = mail.parts.find{|part| part.content_type =~ /^text\/plain;/i} # Single = intended
        text = plain_part.decoded.strip
      # If there is none, use the escaped HTML part.
      elsif html_part = mail.parts.find{|part| part.content_type =~ /^text\/html;/i} # Single = intended
        text = CGI.escape_html(html_part.decoded).strip
      else
        text = "[unreadable message]"
      end
    else
      encoded_body = mail.body.decoded.dup
      encoded_body.force_encoding("UTF-8") # mail fails to set the encoding, and I won’t extract the charset from the Content-Type header. Bug: https://github.com/mikel/mail/issues/809
      text = encoded_body
    end

    text = "Received via mailinglist from #{extract_mail_display_name(mail)}" + "\n\n" + text
  end

  # Extracts a display name of the form
  #   Foo <foo@xxxxxx>
  # or, if the display part is not available,
  #   foo@xxxxxxx
  # .
  def extract_mail_display_name(mail)
    # Uncomment once we update to mail 2.6.x
    # name = mail.header[:From].address_list.addresses.first.display_name
    name = nil

    if name
      name << "<" << mail.from.first.sub(/@.*$/, "@xxxxxxxxxx") << ">"
    else
      name = mail.from.first.sub(/@.*$/, "@xxxxxxxxxx")
    end

    name
  end

  # Checks if the author of the mail (From: header) is registered on
  # the forum, and if so, returns its record. If not, the generic
  # Guest record is returned.
  def extract_mail_author(mail)
    if user = User.where(:email => mail.from.first).first
      return user
    else
      User.where(:nickname => "Guest").first
    end
  end

end
