# coding: utf-8
class Chessboard::Post < Sequel::Model
  plugin :rcte_tree
  many_to_one :forum
  many_to_one :author, :class => Chessboard::User
  many_to_many :tags
  one_to_many :attachments

  # The rcte_tree plugin creates methods #parent and #children.
  # For readability, here's an alias for children that fits
  # the semantic context better. Likewise for thread starter.
  alias replies children
  alias thread_starter root

  class << self

    # Parse the email file at the given path at as a message targetted
    # at the given Forum instance. This method may create new user
    # accounts, hence the bang at the end. Automatically saves the
    # created instance to the database.
    def create_from_file!(path, forum)
      post = new
      mail = Mail.read(path)

      content = nil

      if text_part = extract_mail_leaf_part(mail, "text/plain")
        content = text_part.body.decoded.strip
        charset = text_part.content_type_parameters["charset"] || "UTF-8"

        # The "mail" gem fails to set the encoding. Bug:
        # https://github.com/mikel/mail/issues/809
        # The above code defaults to UTF-8 if no encoding is specified.
        content.force_encoding(charset)
      elsif Chessboard::Configuration[:html_formatter] && html_part = extract_mail_leaf_part(mail, "text/html")
        begin
          file = Tempfile.new(["chessboard", ".html"], Dir.tmpdir, :encoding => Encoding::BINARY)

          # Generate the temporary file with the content of the HTML mail
          file.write(html_part.body.decoded.strip)
          file.close

          # Have the config's formatter format it to plain text
          command = sprintf(Chessboard::Configuration[:html_formatter], file.path)
          Chessboard.logger.info("Executing: #{command}")
          content = IO.popen(command, "r"){ |io| io.read }

          post[:was_html_only] = true
        ensure
          file.close unless file.closed?
          file.unlink
        end
      else
        Chessboard.logger.warn("Failed to parse message from #{mail.from} with content type #{mail.content_type}")
        content = "ERROR: Unable to parse message content (content type: #{mail.content_type})."
      end

      # Ensure only UTF-8 gets into the database
      content.encode!("UTF-8")

      post[:content]    = content
      post[:title]      = mail.subject ? mail.subject.encode("UTF-8") : "(No subject)"
      post[:message_id] = mail.message_id
      post[:created_at] = mail.date
      post.forum        = forum
      post.author       = extract_mail_author!(mail)
      post.parent       = find_parent_post(mail)

      post.save

      # Parse the X-Chessboard-Tags header regardless of its case
      # and add the tags to the post. Note Sequel.lit is used with
      # an argument to prevent SQL injection.
      if mail["X-Chessboard-Tags"]
        set = mail["X-Chessboard-Tags"].decoded.split(",")
              .map{|tagname| Sequel.function("upper", Sequel.lit("?", tagname))}
        Chessboard::Tag.where(Sequel.function("upper", :name) => set).each do |tag|
          post.add_tag(tag)
        end
      end

      # Store all the attachments
      if mail.multipart?
        mail.attachments.each do |a|
          Chessboard::Attachment.create_from_mail_attachment(a, post)
        end
      end
    end

    # Returns a dataset of all posts which started a topic.
    def thread_starters
      Chessboard::Post.where(:parent_id => nil)
    end

    # Return all announcements, newest one first.
    def announcements
      Chessboard::Post.where(:announcement => true).order(Sequel.desc(:created_at))
    end

    private

    # Extract the author from the mail and return the matching
    # User instance. If the user is not yet in the database,
    # create it.
    def extract_mail_author!(mail)
      user = Chessboard::User.where(:email => mail.from.first).first
      return user if user

      # Create new user if this user is not known yet.
      Chessboard.logger.info("Creating account for newly encountered user #{mail.from.first}")
      user = Chessboard::User.new
      user.email = mail.from.first
      user.reset_password

      # Set display name if the From header has one, otherwise let User to
      # its default procedure to determine a good one.
      if mail["From"].address_list.addresses.first.display_name
        user.display_name = mail["From"].address_list.addresses.first.display_name.encode("UTF-8")
      end

      user.save
    end

    # Extract the part with the given MIME type target_type
    # from the message. Also works on messages with only one
    # part, because the mail itself can be treated like a
    # message part.
    # TODO: Does not consider multipart/alternative. As a result,
    # on a HTML-only mail with a text/plain attachment like
    # for example a logfile, this would return the logfile
    # attachment rather than the main part, which is HTML,
    # when queried for text/plain.
    def extract_mail_leaf_part(part, target_type)
      if part.multipart? # Nested MIME type (multipart/*)
        part.parts.each do |subpart|
          if found = extract_mail_leaf_part(subpart, target_type)
            return found
          end
        end

        return nil
      else # Leaf MIME type
        if part.content_type =~ /^#{Regexp.escape(target_type)}(?:$|;|\s)/
          return part
        else
          return nil
        end
      end
    end

    # Query the "In-Reply-To" header and use it to track down the
    # parent post. Returns nil if none was found or the header
    # was not set in the mail.
    def find_parent_post(mail)
      # 1. Try In-Reply-To: header
      if mail.in_reply_to
        if post = Chessboard::Post.where(:message_id => mail.in_reply_to).first
          return post
        end
      end

      # 2. Try References: header (which may either be a string in case
      # of a single reference, or an array in case of a reply later down
      # the thread).
      if mail.references
        if mail.references.kind_of?(Array)
          mail.references.reverse_each do |msgid| # Newest msgid comes last
            if post = Chessboard::Post.where(:message_id => msgid).first
              return post
            end
          end
        elsif post = Chessboard::Post.where(:message_id => mail.references.to_str).first
          return post
        end
      end

      # 3. Try Subject: header
      if mail.subject.strip =~ /^(Re:|Fw:|Fwd:)\s?(.*)$/
        # Try to find the original post without "Re:" or "Fw:".
        # This will mark it as a direct reply to the OP rather than
        # what it was a reply to exactly, but better than nothing.
        if post = Chessboard::Post.where(:title => $2).first
          return post
        else
          # An "Re:" without an original post? May come as a reply from another
          # ML, but still unusual enough to log it.
          Chessboard.logger.warn("Reply to nonexistant thread: <#{mail.message_id}> #{mail.subject}")
        end
      end

      # 4. Give up. Treat as a thread starter.
      nil
    end

  end # class << self

  # Checks if this post is a thread starter and returns true if so,
  # false otherwise. A thread starter is a post with no parent posts.
  def thread_starter?
    !parent
  end

  # Debugging method for printing the entire thread to the
  # standard output in a nested mannor.
  def print_thread(level = 0, post = thread_starter)
    print "  " * level
    puts "<#{post.author.display_name}> #{post.title}"

    post.replies.each do |child_post|
      print_thread(level + 1, child_post)
    end
  end

  # Returns the title with the [list-tag] removed, if one was configured.
  def pretty_title
    if forum.ml_tag
      title.sub(/#{Regexp.escape(forum.ml_tag)}\s?/, "")
    else
      title
    end
  end

  # Similar to #descendants, but does not return the array in logical order,
  # but sorted by created_at dates, with the oldest reply first.
  def all_replies
    descendants_dataset.order(Sequel.asc(:created_at))
  end

  # Convenience alias for #announcement.
  def announcement?
    announcement
  end

  # Convenience alias for #sticky.
  def sticky?
    sticky
  end

  # Checks if the object validates, and if so, hands it to the
  # configuration's :send_to_ml callback. Otherwise
  # it raises Sequel::ValidationFailed.
  #
  # This method does not call #save, i.e. the instance is not saved
  # to the database. This is intentional, because the post will be
  # picked up by the mailinglist monitor and then saved there.
  def send_to_mailinglist(tags, attachments)
    raise Sequel::ValidationFailed unless valid?

    # Since `self' is not serialised yet, the query must target
    # the parent post, which *is* serialised. The parent post's
    # message ID has to be added separately as it is not part of
    # the result of the query.
    refs = parent.ancestors_dataset.order(Sequel.asc(:created_at)).map(:message_id)
    refs << parent.message_id

    # Hand over to the callback
    Chessboard::Configuration[:send_to_ml].call(forum.mailinglist, self, refs, tags, attachments)
  end

  private

  def before_create
    self[:created_at] ||= Time.now
    super
  end

  # Delete all attachments if the post is deleted.
  def before_destroy
    attachments_dataset.destroy
    super
  end

end
