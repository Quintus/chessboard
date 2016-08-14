class Chessboard::Forum < Sequel::Model
  one_to_many :posts

  # Struct that maps forum IDs and their mailinglist attribute to the
  # thread that monitors the corresponding mailinglist. The ML attribute
  # is cached so changes of it during runtime of the application are
  # explicitely *not* detected (would make stopping the threads difficult).
  MonitoredMLThread = Struct.new(:id, :mailinglist, :thread)

  # Call #synchronize_with_mailinglist! on all instances of this class
  # currently in the database.
  def self.sync_with_mailinglists!
    all.each{ |forum| forum.synchronize_with_mailinglist! }
  end

  # For each Forum instance in the database, spawn a thread that monitors
  # the corresponding mailinglist. The actual monitoring is deferred to
  # the callback of the configuration option "monitor_ml", which is invoked
  # by this method.
  def self.start_monitoring_threads
    @ml_monitoring_threads = []
    Chessboard.logger.info("Starting monitoring threads")

    all.each do |forum|
      t = Thread.new(forum.mailinglist) do |ml|
        Chessboard::Configuration[:monitor_ml].call(ml, forum, Chessboard::Configuration[:monitor_method])
      end

      @ml_monitoring_threads << MonitoredMLThread.new(forum.id, forum.mailinglist, t)
    end
  end

  # Terminate all monitors spawned by ::start_monitoring_threads by invoking
  # the callback of the configuration option "stop_ml_monitor" for each monitor.
  def self.stop_monitoring_threads
    Chessboard.logger.info("Stopping monitoring threads")

    @ml_monitoring_threads.each do |mlt|
      Chessboard::Configuration[:stop_ml_monitor].call(
        mlt.mailinglist,
        mlt.thread,
        Chessboard::Configuration[:monitor_method])
    end

    @ml_monitoring_threads.each{ |mlt| mlt.thread.join }
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
  def sync_with_mailinglist!(max_age = Time.at(0))
    posts_dataset.destroy

    # Callback is required to sort by date descending
    Chessboard::Configuration[:load_ml_mails].call(self[:mailinglist]).each do |path|
      process_new_ml_message(path)
    end
  end

  # Process the file at the given path as a new message received
  # on the mailinglist. Convenience method for invoking
  # Chessboard::Post::create_from_file.
  def process_new_ml_message(path)
    Chessboard::Post.create_from_file!(path, self)
  end

  def submit_new_email(path)
    puts "!!!!!!!!!!!!!!!!!!"
    puts path
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
