if system.runs_service?("mysql")
  identify "mariadb", "db"
  parameter "user", "dbuser"
  parameter "password", SecureRandom.base64
end
