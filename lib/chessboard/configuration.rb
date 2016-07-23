module Chessboard

  # Module for managing the configuration as a global
  # information.
  module Configuration

    # This method is to be called in the configuration file.
    # It evaluates its block in the context of this module.
    def self.create(&block)
      @config_settings.clear # Already created in ::config_setting
      @forum_groups = {}
      @current_forum_group = nil

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

    # Define a new forum group with the given name and makes this the current
    # forum group. Any subsequent calls to ::add_forum add forums to this
    # forum group.
    def self.add_forum_group(name)
      @forum_groups[name] = []
      @current_forum_group = name
    end

    # Add a new forum to the currently active forum group (see ::add_forum_group).
    #
    # Takes the following options:
    # [name]
    #   Main name of the forum. This is used to display the forum
    #   to the user, and it is used to filter the mails on the mailinglist
    #   unless +catchall+ is set to +true+.
    # [mailinglist]
    #   The mailinglist this forum mirrors. This is passed through
    #   unchanched to the load_ml_* and subscribe_to_nomail callbacks
    #   of the configuration. The Mlmmj config expects this to be
    #   the directory of the mailinglist.
    # [catchall]
    #   Specifies that this forum is a catchall forum, i.e. the mails
    #   on the mirrored mailinglist are not filtered for the forum
    #   name, but all mail that does not match any filter name,
    #   appears here. You should have at least one catchall forum
    #   per mirrored mailinglist, otherwise the forum is going to
    #   lose mails. If you only have one forum for a mailinglist,
    #   always make that one the catchall forum.
    def self.add_forum(options)
      raise "No active forum group!" unless @current_forum_group

      @forum_groups[@current_forum_group] << options
    end

    # Returns the list of defined forums and their forum groups,
    # as a hash of this form:
    #   {"Forum Group" => [{:name => "Forum 1", :description => "foo", ...}, ...], ...}
    def self.forum_groups
      @forum_groups
    end

    # Convenience method that iterates the forum list and returns
    # an array of all mailinglists mirrored. The array is normalised
    # so that no mailinglist is included multiple times even if multiple
    # forums mirror the same mailinglist.
    # The returned array is sorted.
    def self.mirrored_mailinglists
      mailinglists = []
      @forum_groups.each_pair do |groupname, forums|
        forums.each do |options|
          mailinglists << options[:mailinglist] unless mailinglists.include?(options[:mailinglist])
        end
      end

      mailinglists.sort
    end

    # Following is the list of supported configuration options

    config_setting :board_title
    config_setting :board_subtitle
    config_setting :database_url
    config_setting :ldap, false
    config_setting :ldap_host
    config_setting :ldap_port, 389
    config_setting :ldap_encryption, nil
    config_setting :ldap_user_dn
    config_setting :load_ml_users
    config_setting :subscribe_to_nomail
    config_setting :log, :file
    config_setting :log_file, "/var/log/chessboard.log"
    config_setting :log_facility, :daemon

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
          end
        end
      end
    end
  end
end
