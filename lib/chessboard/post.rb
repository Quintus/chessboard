# coding: utf-8
class Chessboard::Post < Sequel::Model
  plugin :rcte_tree
  plugin :validation_helpers
  many_to_one :forum
  many_to_one :author, :class => Chessboard::User
  many_to_many :tags
  many_to_many :users_who_read_this, :left_key => :post_id, :right_key => :user_id, :class => :User, :join_table => :read_posts
  many_to_many :direct_watchers,     :left_key => :post_id, :right_key => :user_id, :class => :User, :join_table => :watched_posts
  one_to_many :attachments

  # Regular expression for extracting @ mentions.
  # ">" is for closing HTML tag
  FIND_MENTION_REGEXP = /(^|\s|>)(@[_[[:alnum:]]]+)/

  # Template for the email sent do mentioned users.
  MENTION_EMAIL = ERB.new(<<-EMAIL)
Hi <%= nickname %>,

you have been mentioned in this thread:

<%= post_url %>

The post was:

<%= text.lines.map{|l| "> \#{l}"}.join("") %>

Best regards,
Chessboard mail system

-- 
You are receiving this mail as a member of the forum at <%= Chessboard::Configuration[:board_url] %>.
  EMAIL


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

      # Blank email without content
      content = "[This message had no content]" if content.empty?

      # If the mail lacks a proper display name in the From: header, use the
      # part before the email address' @ sign. A display is not proper if it
      # contains only whitespace, is the empty string, or the From: header is
      # missing altogether.
      if mail["From"].address_list.addresses.first.display_name.to_s.strip.empty?
        display_name = mail.from.first.split("@")[0]
      else
        display_name = mail["From"].address_list.addresses.first.display_name.encode("UTF-8")
      end

      post.forum        = forum
      post.author       = extract_mail_author!(mail, display_name)
      post.parent       = find_parent_post(mail)
      post[:content]    = content
      post[:title]      = mail.subject ? mail.subject.encode("UTF-8") : "(No subject)"
      post[:message_id] = mail.message_id
      post[:used_alias] = display_name
      post[:created_at] = mail.date.to_time.utc

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

      # Auto-watch if requested
      if post.author.auto_watch
        post.author.watch!(post)
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
    # User instance. If the user is not in the database (or,
    # if LDAP authentication is enabled, not in the LDAP), returns
    # the Guest user instance (Chessboard::User.guest).
    #
    # +display_name+ has to be constructed from the mail's
    # From: header, this method does not do that itself to
    # prevent code duplication.
    def extract_mail_author!(mail, display_name)
      if Chessboard::Configuration[:ldap]
        ldap = Chessboard::LDAP.new_app_ldap
        result = ldap.search(:base => Chessboard::Configuration[:ldap_user_subtree],
                             :filter => Net::LDAP::Filter.eq("mail", mail.from.first),
                             :size => 1,
                             :attributes => [Chessboard::Configuration[:ldap_user_email_attr],
                                             Chessboard::Configuration[:ldap_user_name_attr],
                                             Chessboard::Configuration[:ldap_user_uid_attr]],
                             :result_set => true)

        if result.nil?
          # LDAP error. Make this a guest post to not lose the mail.
          Chessboard::Application.logger.error("LDAP failure while determining author of mail by #{mail.from}:")
          Chessboard::Application.logger.error(ldap.get_operation_result.inspect)
          user = Chessboard::User.guest
        else
          # Only one entry can match this query, get it from the result array
          if result.first
            user = Chessboard::User.get_from_ldap_entry!(result.first)
          else
            # User not in LDAP. Make this a Guest post.
            user = Chessboard::User.guest
          end
        end
      else
        # Non-LDAP setup.
        user = Chessboard::User.where(:email => mail.from.first).first

        # If the user is not in the DB, make a Guest post.
        unless user
          user = Chessboard::User.guest
        end
      end

      user
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
    puts "<#{post.used_alias}> #{post.title}"

    post.replies.each do |child_post|
      print_thread(level + 1, child_post)
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
    # Since the post is not saved into the database directly, but
    # transformed into an email first, the Post model uses explicit
    # validations rather than only relying on the database constraints.
    # These explicit validations match the database constraints closely
    # (or should do that) and have the advantage that they can be checked
    # without saving the object into the database.
    raise Sequel::ValidationFailed unless valid?

    # Since `self' is not serialised yet, the query must target
    # the parent post, which *is* serialised. The parent post's
    # message ID has to be added separately as it is not part of
    # the result of the query.
    # If this is a new root post (new topic), then no parent setting
    # is needed of course.
    if parent
      refs = parent.ancestors_dataset.order(Sequel.asc(:created_at)).select_map(:message_id)
      refs << parent.message_id if parent.message_id # Importers may not set a message ID if the imported posts were never send to a mailinglist
    else
      refs = []
    end

    # Hand over to the callback
    Chessboard::Configuration[:send_to_ml].call(forum.mailinglist, self, refs, tags, attachments)
  end

  # Returns a dataset for all User instances that are watching this post.
  def watchers_dataset
    db = Chessboard::Application::DB

    Chessboard::User
      .with(:ancestors, ancestors_dataset) # Get all ancestors into the query
      .with(:target_post, Chessboard::Post # Get the direct target post into the query (can surely be simplified, since we have the ID here, a real SELECT is not really needed..)
                          .where(Sequel.qualify(:posts, :id) => id)
                          .select(Sequel.qualify(:posts, :id)))
      .with(:all_ids, db[:target_post] # Concatenate the ancestors and the target post IDs into one virtual table
                      .select(Sequel.qualify(:target_post, :id))
                      .union(db[:ancestors].select(Sequel.qualify(:ancestors, :id)),
                             :all => true))
      .join(:watched_posts, Sequel.qualify(:users, :id) => Sequel.qualify(:watched_posts, :user_id))
      .where(Sequel.qualify(:watched_posts, :post_id) => db[:all_ids].select(Sequel.qualify(:all_ids, :id)))
      .distinct # User may be watching multiple posts in the ancestor hierarchy

      # Actual work starts at the #join call above. Standard join,
      # then the result set is reduced to those users who watch the
      # target post or one of its ancestors.
  end

  # Executes the #watchers_dataset and returns an array of User instances.
  def watchers
    watchers_dataset.all
  end

  # This post's title with the forum's ML tag stripped from it.
  # If you call this often, eager-load the +forum+ association
  # as the method needs to access it.
  def pretty_title
    if forum.ml_tag
      title.sub(/#{Regexp.escape(forum.ml_tag)}\s?/, "")
    else
      title
    end
  end

  # Checks whether this post can still be edited. A post is editable,
  # if a) it has no replies (i.e. children_dataset is empty) and b)
  # no more time than configured in the +edit_timespan+ configuration
  # option has passed since its creation (created_at).
  def editable?
    (Time.now - Chessboard::Configuration[:edit_timespan] <= created_at) &&
      (children_dataset.empty?)
  end

  # Checks whether this post has been edited and if so, returns true.
  # Otherwise returns false.
  def edited?
    !!edited_at
  end

  private

  def validate
    super

    validates_not_null [:forum_id, :author_id]
    validates_presence [:title, :content, :sticky, :announcement, :was_html_only, :views, :created_at, :last_post_date, :used_alias]
    validates_min_length 2, :title
    validates_min_length 1, :used_alias
    validates_length_range 2..100_000, :content
    validates_integer :views

    errors.add(:views, "View count must be >= 0") if views.to_i < 0
    errors.add(:last_post_date, "The date of the last post in this thread must be >= the date of this post.") if last_post_date && created_at && last_post_date < created_at
  end

  def before_validation
    self[:created_at]     ||= Time.now.utc
    self[:last_post_date] ||= self[:created_at]
    self[:sticky]         ||= false
    self[:announcement]   ||= false
    self[:was_html_only]  ||= false
    self[:views]          ||= 0

    # Delete "<" and ">" characters because they cannot be used in
    # an email's display name.
    if self[:used_alias]
      self[:used_alias] = self[:used_alias].delete("<>")
    end

    super
  end

  def after_create
    super

    # Update the root post's last-post information.
    # Note that for a new topic `thread_starter' is identical
    # to `self', which does no harm here, but actually
    # sets the correct information.
    starter = thread_starter
    if starter.last_post_date < created_at
      starter.last_post_date = created_at
      starter.save
    end

    # Deliver @-mentions
    post_url = Chessboard::Configuration[:board_url] + "/forums/#{forum_id}/threads/#{id}"
    content.scan(FIND_MENTION_REGEXP) do |ary|
      bare_name = ary[1][1..-1] # Remove leading @
      # Try both the direct name and "_" replaced with " ",
      # as the user's uid names may contain spaces (?).
      # This breaks if the user name has both "_" and " ",
      # but this is rare enough to ignore.
      user = Chessboard::User.first(:uid => [bare_name, bare_name.gsub("_", " ")])
      unless user
        Chessboard::Application.logger.warn("@-mentioned user not found: #{bare_name}")
        next
      end

      mail = Mail.new
      # Variables for the ERuby context
      nickname = user.uid
      text     = content

      mail.subject = "You have been mentioned"
      mail.from = Chessboard::Configuration[:board_email]
      mail.to   = user.email
      mail.body = MENTION_EMAIL.result(binding)
      mail.charset = 'UTF-8'
      mail.content_transfer_encoding = '8bit'

      mail.deliver
    end

    # Deliver watch emails
    watchers.each do |watcher|
      mail = Mail.new
      mail.subject = "New post in thread: #{title}"
      mail.from = Chessboard::Configuration[:board_email]
      mail.to watcher.email
      mail.body =<<MAIL
Hi #{watcher.uid},

a new post has been added to a thread you are watching. The post
is here:

  #{Chessboard::Configuration[:board_url]}/forums/#{forum_id}/threads/#{id}

The post was written by #{used_alias} <#{author.email}> on
#{created_at.strftime('%Y-%m-%d %H:%M')}.

******************** Start of post ********************
#{content}
MAIL
      mail.charset = 'UTF-8'
      mail.content_transfer_encoding = '8bit'
      mail.deliver
    end
  end

  # Delete all attachments if the post is deleted.
  # Also refresh the last-update information on the root post
  # and reparent children.
  def before_destroy
    super

    if thread_starter?
      # All posts that are direct children of this post now need
      # to be made thread starters
      children_dataset.update(:parent_id => nil)
    else
      second_to_last_post = thread_starter
                            .descendants_dataset
                            .order(Sequel.desc(:created_at))
                            .offset(1)
                            .first

      # If there's a second-to-last post, take its date. Otherwise
      # the thread starter is the only thing that remains and is
      # thus what should be used for the last reply date.
      if second_to_last_post
        thread_starter.last_post_date = second_to_last_post.created_at
      else
        thread_starter.last_post_date = thread_starter.created_at
      end

      thread_starter.save

      # All posts that are direct children of this post now
      # need to be reparented to this post's parent.
      children_dataset.update(:parent_id => parent_id)
    end

    # Remove dependant records
    attachments.each(&:destroy)

    # Clear records in the many2many tables
    Chessboard::Application::DB[:posts_tags].where(:post_id => id).delete
    Chessboard::Application::DB[:read_posts].where(:post_id => id).delete
  end

end
