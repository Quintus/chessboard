module Chessboard

  # Module for managing the configuration as a global
  # information.
  module Configuration

    # This method is to be called in the configuration file.
    # It evaluates its block in the context of this module.
    def self.create(&block)
      @config_settings.clear
      instance_eval(&block)
    end

    # Declares a new configuration option which can be set
    # by the user and retrieved by means of the ::[] method.
    def self.config_setting(name, default_value = nil)
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

    config_setting :database_url
    config_setting :ldap, false
    config_setting :ldap_host
    config_setting :ldap_port, 389
    config_setting :ldap_encryption, nil
    config_setting :ldap_user_dn
    config_setting :load_ml_users
    config_setting :subscribe_to_nomail

    # This namespace contains pre-made configuration snippets for
    # certain mailinglist software.
    module Mailinglists

      # Configuration snippets for mlmmj. Requires the :ml_directory
      # argument to be passed to Configuration::use_premade_config.
      module Mlmmj
        def load_ml_users
          require "find"
          result = []
          ml_dir = @premade_config_args[:ml_directory]

          directories = [
            "#{ml_dir}/mltest/subscribers.d",
            "#{ml_dir}/mltest/digesters.d",
            "#{ml_dir}/mltest/nomailsubs.d"
          ]

          directories.each do |dir|
            Find.find(dir) do |path|
              result.concat(File.readlines(path).map(&:strip)) if File.file?(path)
            end
          end

          result.sort
        end

        def subscribe_to_nomail(email)
          system("/usr/bin/mlmmj-sub", "-L", @premade_config_args[:ml_directory], "-n", email)
        end
      end
    end
  end
end
