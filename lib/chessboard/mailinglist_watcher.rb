class Chessboard::MailinglistWatcher

  # Struct that maps forum IDs and their mailinglist attribute to the
  # thread that monitors the corresponding mailinglist. The ML attribute
  # is cached so changes of it during runtime of the application are
  # explicitely *not* detected (would make stopping the threads difficult).
  MonitoredMLThread = Struct.new(:id, :mailinglist, :thread)

  # For each Forum instance in the database, spawn a thread that monitors
  # the corresponding mailinglist. The actual monitoring is deferred to
  # the callback of the configuration option "monitor_ml", which is invoked
  # by this method.
  def self.start_monitoring_threads
    @ml_monitoring_threads = []

    Chessboard::Forum.all.each do |forum|
      Chessboard.logger.info("Monitoring #{forum.mailinglist}")

      t = Thread.new(forum.mailinglist) do |ml|
        Chessboard::Configuration[:monitor_ml].call(ml, forum, Chessboard::Configuration[:monitor_method])
      end

      @ml_monitoring_threads << MonitoredMLThread.new(forum.id, forum.mailinglist, t)
    end
  end

  # Terminate all monitors spawned by ::start_monitoring_threads by invoking
  # the callback of the configuration option "stop_ml_monitor" for each monitor.
  # This method immediately returns. Use ::wait_for_monitoring_threads to block
  # until the threads have actually finished.
  def self.stop_monitoring_threads
    @ml_monitoring_threads.each do |mlt|
      Chessboard::Configuration[:stop_ml_monitor].call(
        mlt.mailinglist,
        mlt.thread,
        Chessboard::Configuration[:monitor_method])
    end
  end

  # Joins all monitoring threads. You should call
  # :.stop_monitoring_threads before you call this as this method
  # blocks until all those threads have terminated.
  def self.wait_for_monitoring_threads
    @ml_monitoring_threads.each{ |mlt| mlt.thread.join }
  end


end
