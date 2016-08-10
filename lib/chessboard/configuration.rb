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
      extend Chessboard::Configuration::Mailinglists.const_get(name.capitalize)
    end

    # Following is the list of supported configuration options

    config_setting :board_title
    config_setting :board_subtitle
    config_setting :database_url
    config_setting :threads_per_page, 15
    config_setting :ldap, false
    config_setting :ldap_host
    config_setting :ldap_port, 389
    config_setting :ldap_encryption, nil
    config_setting :ldap_user_dn
    config_setting :load_ml_users
    config_setting :load_ml_mails
    config_setting :subscribe_to_nomail
    config_setting :unsubscribe_from_ml
    config_setting :log, :file
    config_setting :log_file, "/var/log/chessboard.log"
    config_setting :log_facility, :daemon
    config_setting :html_formatter, nil
    config_setting :default_user_title, "Member"
    config_setting :admin_email
    config_setting :sendmail_path, "sendmail"
    config_setting :default_view_mode, :threads

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
              system("/usr/bin/mlmmj-sub", "-L", forum_ml, "-n", email)
            end

            unsubscribe_from_ml do |forum_ml, email|
              system("/usr/bin/mlmmj-unsub", "-L", forum_ml, "-n", email)
            end

            load_ml_mails do |forum_ml|
              list = Dir.glob("#{forum_ml}/archive/*")
              list.sort!{|a, b| File.mtime(a) <=> File.mtime(b)}
              list
            end

          end
        end
      end
    end
  end
end
