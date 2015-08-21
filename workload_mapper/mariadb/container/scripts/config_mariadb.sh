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
  MYSQL_ROOT_PASS="${MYSQL_ROOT_PASS-$(pwgen -s -1 12)}"
  MYSQL_USER="${MYSQL_USER-dbuser}"
  MYSQL_PASS="${MYSQL_PASS-$(pwgen -s -1 12)}"
  MYSQL_DB_NAME="${MYSQL_DB_NAME-db}"
  printf "root password=%s\n" "$MYSQL_ROOT_PASS"
  printf "MYSQL_DB_NAME=%s\n" "$MYSQL_DB_NAME"
  printf "MYSQL_USER=%s\n" "$MYSQL_USER"
  printf "MYSQL_PASS=%s\n" "$MYSQL_PASS"
  mysqladmin -u root password "$MYSQL_ROOT_PASS"
  mysql -uroot -p"$MYSQL_ROOT_PASS" <<-EOF
	DELETE FROM mysql.user WHERE user = '$MYSQL_USER';
	FLUSH PRIVILEGES;
	CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASS';
	GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'localhost' WITH GRANT OPTION;
	CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASS';
	GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'%' WITH GRANT OPTION;
	CREATE DATABASE $MYSQL_DB_NAME;
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
