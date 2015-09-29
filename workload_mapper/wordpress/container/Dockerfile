FROM opensuse:13.2

# see update.sh for why all "apt-get install"s have to stay as one long line
RUN zypper -n --gpg-auto-import-keys refresh
RUN zypper -n --gpg-auto-import-keys update
RUN zypper -n --gpg-auto-import-keys install apache2-devel \
mariadb-client \
libmysqlclient-devel \
php5 \
php5-mcrypt \
php5-gd \
php5-mysql \
apache2-mod_php5 \
which

RUN touch /etc/apache2/sysconfig.d/include.conf

RUN mkdir /srv/www/wordpress
WORKDIR /srv/www/wordpress
ADD ./data /srv/www/wordpress

ADD apache2/listen.conf /etc/apache2/listen.conf
ADD apache2/wordpress_vhost.conf /etc/apache2/vhosts.d/
RUN echo "LoadModule php5_module        /usr/lib64/apache2/mod_php5.so" >> /etc/apache2/sysconfig.d/loadmodule.conf
RUN echo "variables_order = 'GPCSE'" >> /etc/php5/cli/php.ini
