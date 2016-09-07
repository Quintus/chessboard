class Chessboard::Forum < Sequel::Model
  one_to_many :posts

  # Call #synchronize_with_mailinglist! on all instances of this class
  # currently in the database.
  def self.sync_with_mailinglists!
    all.each{ |forum| forum.synchronize_with_mailinglist! }
  end

  # Returns a dataset with those Post instances that are thread starters.
  # The neweest thread starter comes first.
  def thread_starters
    posts_dataset.where(:parent_id => nil).order(:created_at).reverse
  end

  # Return a dataset of all sticky posts in this forum. Newest
  # one comes first.
  def stickies
    posts_dataset.where(:sticky => true).order(:created_at).reverse
  end

  # Clear all posts from this forum and resynchronise it with the
  # mailinglist. This executes the load_:ml_mails configuration hook
  # passing it this forums +mailinglist+ attribute and passes each
  # path returned by that hook to #process_new_ml_message (faking
  # it as a newly received message).
  #
  # If a block is given, it is invoked each time a message has been
  # processed. The block gets passed the path to the processed
  # message, the number of the current message and the total number
  # of messages to be processed. It is guaranteed that in the last
  # iteration the current message number and the number of total
  # messages are equal; the first message has number 1.
  def sync_with_mailinglist!(max_age = Time.at(0))
    posts_dataset.destroy

    # Callback is required to sort by date descending
    pathes = Chessboard::Configuration[:load_ml_mails].call(self[:mailinglist])
    pathes.reject!{ |path| File.mtime(path) < max_age }
    total_messages = pathes.count

    pathes.each_with_index do |path, index|
      process_new_ml_message(path)
      yield(path, index + 1, total_messages) if block_given?
    end
  end

  # Process the file at the given path as a new message received
  # on the mailinglist. Convenience method for invoking
  # Chessboard::Post::create_from_file.
  def process_new_ml_message(path)
    Chessboard::Post.create_from_file!(path, self)
  end

  # Takes a post's title and strips the forum's ML tag from it.
  # The method may be more logical to be on the Post class,
  # but having it here is more performant as the Post class would
  # have to wire the Forum instance out of the database first,
  # whereas one is usually already available.
  def prettify_post_title(post_title)
    if ml_tag
      post_title.sub(/#{Regexp.escape(ml_tag)}\s?/, "")
    else
      post_title
    end
  end

  private

  def before_create
    self[:created_at] = Time.now
    super
  end

  # The posts cannot exist without the forum, so they must go when
  # this forum is destroyed.
  def before_destroy
    posts_dataset.destroy
    super
  end

end
