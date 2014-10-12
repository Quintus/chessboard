module MailinglistPlugin
  include Chessboard::Plugin

  def self.inotify_thread
    @inotify_thread ||= nil
  end

  def self.inotify_thread=(val)
    @inotify_thread = val
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
        p [event.name, event.absolute_name]
      end

      logger.info "Starting inotify on '#{mlpath}'"
      notifier.run
    end
  end

  def hook_ctrl_post_create_final(options)
    super
  end

end
