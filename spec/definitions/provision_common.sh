# unmanaged-files
mkdir /usr/local/magicapp
touch /usr/local/magicapp/one
mkdir /usr/local/magicapp/data
touch /usr/local/magicapp/data/two
touch /etc/magicapp.conf
mkdir /var/lib/chroot_proc
mount --bind /proc /var/lib/chroot_proc
echo 42 > /opt/test-quote-char/test-dir-name-with-\'\ quote-char\ \'/unmanaged-file-with-\'\ quote\ \'
mkdir /opt/test-quote-char/test-dir-name-with-\'\ quote-char\ \'/unmanaged-dir-with-\'\ quote\ \'
ln -sf /opt/test-quote-char/target-with-quote\'-foo /opt/test-quote-char/link
# fix issues of alternating names
rm -rf "/var/lib/yum/history/"*
cd /; tar xf /vagrant/unmanaged_files.tgz

# config-files
echo '-*/15 * * * *   root  echo changed_config_files_integration_test &> /dev/null' >> /etc/crontab
echo 'change in umlauts config file' >> /etc/umlaut-äöü.conf

# changed-managed-files
echo '# changed managed files test entry\n' >> /usr/share/info/sed.info.gz
rm '/usr/share/man/man1/sed.1.gz'
mv /usr/bin/crontab /usr/bin/crontab_link_target
ln -s /usr/bin/crontab_link_target /usr/bin/crontab
echo 'change in umlauts file' >> /usr/bin/umlaut-äöü

# add NIS placeholder to users/groups
echo "+::::::" >> /etc/passwd
echo "+:::" >> /etc/group
