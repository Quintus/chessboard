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

    config_setting :database_url
    config_setting :ldap, false
    config_setting :ldap_host
    config_setting :ldap_port, 389
    config_setting :ldap_encryption, nil
    config_setting :ldap_user_dn
    config_setting :load_ml_users
    config_setting :subscribe_to_nomail
  end
end
