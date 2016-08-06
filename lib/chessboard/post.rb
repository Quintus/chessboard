# coding: utf-8
class Chessboard::Post < Sequel::Model
  many_to_one :forum
  many_to_one :author, :class => Chessboard::User
  many_to_one :parent,  :class => self
  one_to_many :replies, :key => :parent_id, :class => self

  class << self

    # Parse the email file at the given path at as a message targetted
    # at the given Forum instance. This method may create new user
    # accounts, hence the bang at the end. It does not save the Post
    # instance by default, but only returns it.
    def new_from_file!(path, forum)
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
          content = IO.popen(command, "r"){ |io| io.read }
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
      post[:title]      = mail.subject.encode("UTF-8")
      post[:message_id] = mail.message_id
      post[:created_at] = mail.date
      post.forum        = forum
      post.author       = extract_mail_author!(mail)
      post.parent       = find_parent_post(mail)
      post
    end

    # Like ::new_from_file, but also calls #save.
    def create_from_file!(path, forum)
      post = new_from_file!(path, forum)
      post.save
      post
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
      if mail.in_reply_to
        Chessboard::Post.where(:message_id => mail.in_reply_to).first
      else
        # No "In-Reply-To" header, no thread starter.
        # Do not support broken mail clients that do
        # not set this header when replying.
        nil
      end
    end

  end

  # Checks if this post is a thread starter and returns true if so,
  # false otherwise. A thread starter is a post with no parent posts.
  def thread_starter?
    !!parent
  end

  # Returns the Post instance that was the thread starter of the
  # thread this post is a part of. Returns self if this post is
  # a thread starter.
  def thread_starter
    post = self
    loop do
      break unless post.parent
      post = post.parent
    end

    post
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

  private

  def before_create
    self[:created_at] ||= Time.now
  end

end
