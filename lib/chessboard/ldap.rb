module Chessboard

  # Encapsulates the LDAP configuration for Chessboard.
  # This module is just a thin wrapper around Net::LDAP
  # so one does not have to specify the authentication
  # and connection parameters all the time.
  module LDAP

    # Returns the arguments hash for Net::LDAP.new.
    # The username is interpolated into the +ldap_user_dn+
    # configuration setting.
    def self.arguments(username, password)
      raise "LDAP support not configured!" unless Chesboard::Configuration.ldap

      args = {
        :host => Chessboard::Configuration.ldap_host,
        :port => Chessboard::Configuration.ldap_port,
        :auth => {
          :username => sprintf(Chessboard::Configuration.ldap_user_dn, username),
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
    def self.new(username, password)
      Net::LDAP.new(arguments(username, password))
    end

    # Calls Net::LDAP.open with the arguments as per the config file.
    def self.open(&block)
      Net::LDAP.open(arguments(username, password), &block)
    end

  end

end
