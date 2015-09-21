FROM opensuse:13.2

RUN zypper -n --gpg-auto-import-keys refresh
RUN zypper -n --gpg-auto-import-keys update
RUN zypper -n --gpg-auto-import-keys install ca-certificates-mozilla \
apache2-devel \
gcc \
gcc-c++ \
git-core \
libcurl-devel \
mariadb-client \
libmysqlclient-devel \
libopenssl-devel \
libstdc++-devel \
libxml2-devel \
libxslt-devel \
make \
nodejs \
patch \
ruby2.1-devel \
rubygem-bundler \
zlib-devel \
which

RUN touch /etc/apache2/sysconfig.d/include.conf

RUN gem install passenger -v 5.0.7
RUN passenger-install-apache2-module.ruby2.1 -a

RUN mkdir /srv/www/rails
WORKDIR /srv/www/rails
ADD ./data /srv/www/rails
RUN echo "gem: --no-ri --no-rdoc" > /srv/www/rails/.gemrc
RUN chown -R wwwrun:www  /srv/www/rails

RUN bundle config build.nokogiri --use-system-libraries
RUN bundle install --without test development

ADD apache2/sysconfig_apache2 /etc/sysconfig/apache2
ADD apache2/httpd.conf.local /etc/apache2/httpd.conf.local
ADD apache2/listen.conf /etc/apache2/listen.conf
ADD apache2/rails_app_vhost.conf /etc/apache2/vhosts.d/
RUN cat /etc/apache2/httpd.conf.local >> /etc/apache2/httpd.conf

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]

EXPOSE 3000
