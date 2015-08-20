FROM opensuse:13.2

RUN zypper -n --gpg-auto-import-keys refresh
RUN zypper -n --gpg-auto-import-keys update
RUN zypper -n --gpg-auto-import-keys install mariadb pwgen psmisc net-tools

ADD scripts /scripts
RUN chmod 755 /scripts/*

VOLUME ["/var/lib/mysql", "/var/log/mysql"]
EXPOSE 3306

CMD ["/bin/bash", "/scripts/start.sh"]
