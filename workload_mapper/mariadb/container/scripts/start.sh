#!/bin/bash

set -e

if [ -r /var/lib/mysql/configured.txt ]; then
  rm -f /run/mysqld/mysqld.sock
  exec /usr/bin/mysqld_safe
else
  /scripts/config_mariadb.sh
fi

