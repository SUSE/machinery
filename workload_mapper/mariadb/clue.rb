if system.runs_service?("mysql")
  identify "mariadb", "db"
  parameter "user", "dbuser"
  parameter "name", "defaultdb"
  parameter "password", SecureRandom.base64
end
