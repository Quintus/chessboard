module Chessboard

  # Encapsulates the LDAP configuration for Chessboard.
  # This module is just a thin wrapper around Net::LDAP
  # so one does not have to specify the authentication
  # and connection parameters all the time.
  module LDAP

    # Returns the arguments hash for Net::LDAP.new.
    # The email is interpolated into the +ldap_user_dn+
    # configuration setting.
    def self.arguments(email, password)
      raise "LDAP support not configured!" unless Chesboard::Configuration.ldap

      localpart, domain = email.split("@")

      args = {
        :host => Chessboard::Configuration.ldap_host,
        :port => Chessboard::Configuration.ldap_port,
        :auth => {
          :username => sprintf(Chessboard::Configuration.ldap_user_dn,
                               :email => email, :localpart => localpart,
                               :domain => domain),
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

    # Calls Net::LDAP.new with the arguments as per the config file.
    def self.new(email, password)
      Net::LDAP.new(arguments(email, password))
    end

    # Calls Net::LDAP.open with the arguments as per the config file.
    def self.open(email, password, &block)
      Net::LDAP.open(arguments(email, password), &block)
    end

  end

end
