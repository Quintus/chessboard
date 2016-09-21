module Chessboard

  # Encapsulates the LDAP configuration for Chessboard.
  # This module is just a thin wrapper around Net::LDAP
  # so one does not have to specify the authentication
  # and connection parameters all the time.
  module LDAP

    # Returns the arguments hash for Net::LDAP.new.
    # This method returns all LDAP communication parameters
    # that are common among all connections. +username+ and
    # +password+ are inserted into the connections hash, so that
    # the return value of this method can be used directly as the
    # arguments hash for Net::LDAP.new.
    def self.arguments(username, password)
      raise "LDAP support not configured!" unless Chesboard::Configuration.ldap

      args = {
        :host => Chessboard::Configuration.ldap_host,
        :port => Chessboard::Configuration.ldap_port,
        :auth => {
          :username => username,
          :password => password
        }
      }

      if Chessboard::Configuration.ldap_encryption
        args[:encryption] = {
          :method => Chessboard::Configuration.ldap_encryption,
          :options => OpenSSL::SSL::SSLContext::DEFAULT_PARAMS
        }
      end

      args
    end

    # Returns the options hash needed for BINDing as a user to the LDAP.
    def self.user_arguments(user, password)
      localpart, domain = user.email.split("@")
      username = sprintf(Chessboard::Configuration.ldap_user_dn,
                         :uid => user.uid,
                         :email => email,
                         :localpart => localpart,
                         :domain => domain)

      arguments(username, password)
    end

    # Return the options hash needed for BINDing as the Chessboard application
    # itself to the LDAP.
    def self.app_arguments
      arguments(Chessboard::Configuration[:ldap_app_dn],
                Chessboard::Configuration[:ldap_app_password])
    end

    # Calls Net::LDAP.new with the arguments as per the user config file options.
    def self.new_user_ldap(user, password)
      Net::LDAP.new(user_arguments(user, password))
    end

    # Calls Net::LDAP.open with the arguments as per the user config file options.
    def self.open_user_ldap(email, password, &block)
      Net::LDAP.open(user_arguments(email, password), &block)
    end

    # Calls Net::LDAP.new with the arguments as per the app config file options.
    def self.new_app_ldap
      Net::LDAP.new(app_arguments)
    end

    # Calls Net::LDAP.open with the arguments as per the app config file options.
    def self.open_app_ldap(&block)
      Net::LDAP.open(app_arguments, &block)
    end

  end

end
