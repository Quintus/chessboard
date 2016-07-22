Chessboard::Configuration.create do |config|

  database_url "postgres://user@host:password/dbname"

  ldap false
  # ldap_host "my_host"
  # ldap_port 389
  # ldap_encryption :start_tls # or :simple_tls for LDAPS
  # ldap_user_dn "uid=%s,ou=users,dc=example,dc=com"

  load_ml_users do |root|
    result = []
    require "find"

    directories = [
      "/tmp/mltest/subscribers.d",
      "/tmp/mltest/digesters.d",
      "/tmp/mltest/nomailsubs.d"
    ]

    directories.each do |dir|
      Find.find(dir) do |path|
        result.concat(File.readlines(path).map(&:strip)) if File.file?(path)
      end
    end

    result.sort
  end

  subscribe_to_nomail do |email|
    `/usr/bin/mlmmj-sub -L /tmp/testml -n #{email}`
  end
end
