#!/bin/bash

set -e

__mysql_config() {
  echo "Running the mysql_config function."
  mysql_install_db
  chown -R mysql:mysql /var/lib/mysql
  /usr/bin/mysqld_safe &
  sleep 10
}

__start_mysql() {
  printf "Running the start_mysql function.\n"
  DB_ROOT_PASS="${DB_ROOT_PASS-$(pwgen -s -1 12)}"
  DB_USER="${DB_USER-dbuser}"
  DB_PASS="${DB_PASS-$(pwgen -s -1 12)}"
  DB_NAME="${DB_NAME-db}"
  printf "root password=%s\n" "$DB_ROOT_PASS"
  printf "DB_NAME=%s\n" "$DB_NAME"
  printf "DB_USER=%s\n" "$DB_USER"
  printf "DB_PASS=%s\n" "$DB_PASS"
  mysqladmin -u root password "$DB_ROOT_PASS"
  mysql -uroot -p"$DB_ROOT_PASS" <<-EOF
	DELETE FROM mysql.user WHERE user = '$DB_USER';
	FLUSH PRIVILEGES;
	CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
	GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost' WITH GRANT OPTION;
	CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';
	GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'%' WITH GRANT OPTION;
	CREATE DATABASE $DB_NAME;
EOF

  killall mysqld
  sleep 10
}

# Call all functions
DB_FILES=$(echo /var/lib/mysql/*)
DB_FILES="${DB_FILES#/var/lib/mysql/\*}"
DB_FILES="${DB_FILES#/var/lib/mysql/lost+found}"
if [ -z "$DB_FILES" ]; then
  printf "Initializing empty /var/lib/mysql...\n"
  __mysql_config
  __start_mysql
fi

# Don't run this again.
rm -f /scripts/config_mariadb.sh
