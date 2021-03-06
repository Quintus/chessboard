module Chessboard

  # Module for managing the configuration as a global
  # information.
  module Configuration

    # This method is to be called in the configuration file.
    # It evaluates its block in the context of this module.
    def self.create(&block)
      @config_settings.clear # Already created in ::config_setting
      @forums = []

      @config_finished = false
      instance_eval(&block)
      @config_finished = true
    end

    # Declares a new configuration option which can be set
    # by the user and retrieved by means of the ::[] method.
    def self.config_setting(name, default_value = nil)
      raise "Change of configuration not permitted at runtime!" if @config_finished

      @config_settings ||= {}
      @config_settings[name] = default_value

      define_singleton_method(name) do |*args, &block|
        if block && args.empty?
          @config_settings[name] = block
        elsif args.count == 1
          @config_settings[name] = args[0]
        else
          raise "Invalid configuration."
        end
      end
    end

    # Retrieve the value of a configuration.
    def self.[](name)
      @config_settings ||= {}
      @config_settings[name]
    end

    # Use one of the pre-made configuration snippets available
    # under the Chessboard::Configuration::Mailinglists namespace.
    # Takes the name of the module as a symbol or string, and
    # any arguments you want to pass to this module as a hash.
    def self.use_premade_config(name, args = {})
      @premade_config_args = args
      extend Chessboard::Configuration::Mailinglists.const_get(name)
    end

    # Following is the list of supported configuration options

    config_setting :board_title
    config_setting :board_subtitle
    config_setting :board_url
    config_setting :database_url
    config_setting :threads_per_page, 15
    config_setting :posts_per_page, 10
    config_setting :max_total_attachment_size, 1024 * 1024
    config_setting :edit_timespan, 60 * 60 * 24 * 2 # 2 days
    config_setting :ldap, false
    config_setting :ldap_host
    config_setting :ldap_port, 389
    config_setting :ldap_encryption, nil
    config_setting :ldap_user_dn
    config_setting :ldap_user_subtree
    config_setting :ldap_user_email_attr, "email"
    config_setting :ldap_user_name_attr, "cn"
    config_setting :ldap_user_uid_attr, "uid"
    config_setting :ldap_app_dn
    config_setting :ldap_app_password
    config_setting :load_ml_users
    config_setting :load_ml_mails
    config_setting :subscribe_to_nomail
    config_setting :unsubscribe_from_ml
    config_setting :send_to_ml
    config_setting :monitor_ml
    config_setting :stop_ml_monitor
    config_setting :log, :file
    config_setting :log_file, "/var/log/chessboard.log"
    config_setting :log_facility, :daemon
    config_setting :html_formatter, nil
    config_setting :default_user_title, "Member"
    config_setting :admin_email
    config_setting :board_email
    config_setting :sendmail_path, "sendmail"
    config_setting :default_view_mode, :threads
    config_setting :monitor_method, :inotify
    config_setting :enable_registration, true
    config_setting :confirmation_expiry, 60 * 60 * 24 * 2 # 2 days
    config_setting :hilit_heuristic
    config_setting :max_ip_store_timespan, 60 * 60 * 24 * 14 # 2 weeks
    config_setting :forum_rules, nil
    config_setting :imprint, nil
    config_setting :create_user_hook, nil
    config_setting :delete_user_hook, nil

    # This namespace contains pre-made configuration snippets for
    # certain mailinglist software.
    module Mailinglists

      # Configuration snippets for mlmmj. Requires the :ml_directory
      # argument to be passed to Configuration::use_premade_config.
      module Mlmmj
        def self.extended(other)
          other.module_eval do

            load_ml_users do |forum_ml|
              require "find"
              result = []

              directories = [
                "#{forum_ml}/subscribers.d",
                "#{forum_ml}/digesters.d",
                "#{forum_ml}/nomailsubs.d"
              ]

              directories.each do |dir|
                Find.find(dir) do |path|
                  result.concat(File.readlines(path).map(&:strip)) if File.file?(path)
                end
              end

              result.sort
            end

            subscribe_to_nomail do |forum_ml, email|
              unless system("/usr/bin/mlmmj-sub", "-L", forum_ml, "-a", email, "-n")
                raise("Failed to subscribe '#{email}'!")
              end
            end

            unsubscribe_from_ml do |forum_ml, email|
              unless system("/usr/bin/mlmmj-unsub", "-L", forum_ml, "-a", email)
                raise("Failed to unsubscribe '#{email}'!")
              end
            end

            load_ml_mails do |forum_ml|
              list = Dir.glob("#{forum_ml}/archive/*")
              list.sort!{|a, b| File.mtime(a) <=> File.mtime(b)}
              list
            end

            send_to_ml do |forum_ml, post, refs, tags, attachments|
              mail = Mail.new do
                from "#{post.used_alias} <#{post.author.email}>"
                to File.read(File.join(forum_ml, "control", "listaddress")).strip
                subject post.title

                if post.edited?
                  body sprintf("*** Edit of message from %s (%s) ***\n\n%s",
                               post.edited_at.to_time.strftime("%Y-%m-%d %H:%M:%S"),
                               post.edited_msgid || "unknown message id",
                               post.content)
                else
                  body post.content
                end

                unless refs.empty? # New topic (root post) if empty
                  in_reply_to "<#{refs.last}>"
                  references refs.map{|r| "<#{r}>"}.join(" ")
                end

                # `attachments' is an empty array if no attachments are there.
                attachments.each do |attachment|
                  add_file :filename => attachment[:filename], :content => attachment[:tempfile].read
                end
              end

              mail["User-Agent"] = "Chessboard/#{Chessboard::VERSION}"
              mail["X-Chessboard-Tags"] = tags.map(&:name).join(",") unless tags.empty?
              mail["X-Chessboard-Edited"] = post.edited_msgid
              mail.charset = 'UTF-8'
              mail.content_transfer_encoding = '8bit'
              mail.deliver!

              mail.message_id
            end

            monitor_ml do |forum_ml, forum, monitor_method|
              if monitor_method == :inotify
                notifier = INotify::Notifier.new
                notifier.watch("#{forum_ml}/archive", :moved_to, :create) do |event|
                  # The stop_ml_monitor callback creates this file temporarily to signal
                  # that processing should stop. Note that Notifier#stop does not end
                  # inotify immediately, but only after all pending events have been
                  # processed.
                  if File.basename(event.name) == "TERM_CB_MON"
                    Chessboard.logger.info("Detected TERM_CB_MON, stopping inotify monitor on #{forum_ml}")
                    notifier.stop
                  else
                    # Otherwise its a regular email, submit it to the handler.
                    Chessboard.logger.info("Processing new message #{event.absolute_name}")
                    forum.process_new_ml_message(event.absolute_name)
                  end
                end
                notifier.run
              elsif monitor_method == :poll
                Thread.current[:terminate_monitor] = false
                existing_mails = Dir.glob("#{forum_ml}/archive/*")

                catch :terminate do
                  loop do
                    # Sleep 30 seconds in total, only checking if we shall
                    # terminate while doing this.
                    6.times do
                      if Thread.current[:terminate_monitor]
                        Chessboard.logger.info("Terminating polling monitor on #{forum_ml}")
                        throw :terminate
                      end

                      sleep(5)
                    end

                    now_existing_mails = Dir.glob("#{forum_ml}/archive/*")
                    new_mails = now_existing_mails - existing_mails

                    new_mails.each do |path|
                      Chessboard.logger.info("Processing new message #{path}")
                      forum.process_new_ml_message(path)
                      existing_mails.append(path)
                    end
                  end
                end
              else
                raise NotImplementedError, "The monitor method #{monitor_method} is not supported by the premade mlmmj configuration."
              end
            end

            stop_ml_monitor do |forum_ml, thread, monitor_method|
              if monitor_method == :inotify
                # Create a file in the monitored directory to make the monitor pick
                # it up. Since the file is not needed, delete it afterwards directly.
                path = "#{forum_ml}/archive/TERM_CB_MON"
                File.open(path, "w"){|f| f.write("Terminate it!")}
                File.delete(path)
              elsif monitor_method == :poll
                thread[:terminate_monitor] = true
              else
                raise NotImplementedError, "The monitor method #{monitor_method} is not supported by the premade mlmmj configuration."
              end
            end

          end
        end
      end

      # This configuration snippet is meant for debugging, but you may find
      # it useful still. It allows to run Chessboard without an actual associated
      # mailinglist by simply doing nothing other than submitting send posts
      # to the email processor directly, skipping the mailinglist. If you use
      # this config snippet, you thus do not need to run the mailinglist monitor
      # (and trying to do so will cause it to terminate with an error).
      # If you use this snippet, the forum's +mailinglist+ attribute is only
      # used to distinguish the forums from each other, so you can set it to
      # any value as long as each forum gets a unique one.
      module NullML
        def self.extended(other)
          other.module_eval do
            load_ml_users do |forum_ml|
              Chessboard::User.order(Sequel.asc(:created_at)).select_map(:email)
            end

            subscribe_to_nomail { }
            unsubscribe_from_ml { }

            load_ml_mails do
              raise(NotImplementedError, "Cannot load mails from NullML config!")
            end

            send_to_ml do |forum_ml, post, refs, tags, attachments|
              mail = Mail.new do
                from "#{post.author.display_name.delete('<>')} <#{post.author.email}>"
                to Chessboard::Configuration[:board_email]
                subject post.title

                if post.edited?
                  body sprintf("*** Edit of message from %s (%s) ***\n\n%s",
                               post.edited_at.to_time.strftime("%Y-%m-%d %H:%M:%S"),
                               post.edited_msgid || "unknown message id",
                               post.content)
                else
                  body post.content
                end

                unless refs.empty? # New topic (root post) if empty
                  in_reply_to "<#{refs.last}>"
                  references refs.map{|r| "<#{r}>"}.join(" ")
                end

                # `attachments' is an empty array if no attachments are there.
                attachments.each do |attachment|
                  add_file :filename => attachment[:filename], :content => attachment[:tempfile].read
                end
              end

              mail["User-Agent"] = "Chessboard/#{Chessboard::VERSION}"
              mail["X-Chessboard-Tags"] = tags.map(&:name).join(",") unless tags.empty?
              mail["X-Chessboard-Edited"] = post.edited_msgid
              mail.charset = 'UTF-8'
              mail.content_transfer_encoding = '8bit'

              file = Tempfile.new("nullml")
              begin
                file.write(mail.to_s)
                file.flush
                Chessboard::Post.create_from_file!(file.path, Forum.first(:mailinglist => forum_ml))
              ensure
                file.unlink
              end

              mail.message_id
            end

            monitor_ml do
              raise(NotImplementedError, "NullML config does not need a mail monitor!")
            end

            stop_ml_monitor do
              raise(NotImplementedError, "NullML config does not need a mail monitor!")
            end
          end
        end
      end

      # This premade configuration snippet simply disables code highlighting.
      module NoHilit
        def self.extended(other)
          other.module_eval do
            hilit_heuristic do |*|
              nil
            end
          end
        end
      end

      # This premade configuration snippet contains a very simple
      # heuristic to check whether the given string is code at all and
      # whether it's Ruby or C++ code, or XML markup. You can use it
      # as an example as to how to implement your own heuristic.
      module RubyAndCppAndXMLHilit
        def self.extended(other)
          other.module_eval do

            hilit_heuristic do |code|
              if code =~ /(^|\s+)(def|module)\s|end\n|self|elsif|@\w+\s*=/
                :ruby
              elsif code =~ /^#include|;\n|(^|\s+)(namespace|new)\s|\(\)|NULL|nullptr/
                :cpp
              elsif code =~ %r!^\<\?xml|/>\n|<(.*?)>.*</\1>!m
                :xml
              else
                nil
              end
            end

          end
        end
      end

    end
  end
end
