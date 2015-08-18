mariadb_config = "/etc/my.cnf"
if system.runs_service?("mysql") && system.has_file?(mariadb_config)
  identify "mariadb", "db"
  parameter "user", system.read_config(mariadb_config, "user")
  parameter "password", system.read_config(mariadb_config, "password")
end
