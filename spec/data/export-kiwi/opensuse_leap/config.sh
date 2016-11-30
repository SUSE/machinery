test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile
baseMount
suseSetupProduct
suseImportBuildKey
suseConfig
zypper -n ar --name='openSUSE-Leap-42.2-Oss' --type='yast2' --refresh 'http://download.opensuse.org/distribution/leap/42.2/repo/oss/' 'repo-oss'
zypper -n mr --priority=99 'openSUSE-Leap-42.2-Oss'
systemctl enable auditd.service
systemctl enable autovt@.service
systemctl disable blk-availability.service
systemctl disable btrfsmaintenance-refresh.service
systemctl disable console-getty.service
systemctl disable console-shell.service
systemctl enable cron.service
systemctl enable dbus-org.opensuse.Network.AUTO4.service
systemctl enable dbus-org.opensuse.Network.DHCP4.service
systemctl enable dbus-org.opensuse.Network.DHCP6.service
systemctl enable dbus-org.opensuse.Network.Nanny.service
systemctl disable debug-shell.service
systemctl disable dm-event.service
systemctl disable dm-event.socket
systemctl disable dmraid-activation.service
systemctl enable getty@tty1.service
systemctl disable grub2-once.service
systemctl enable irqbalance.service
systemctl disable kexec-load.service
systemctl disable lvm2-lvmetad.service
systemctl enable lvm2-lvmetad.socket
systemctl disable lvm2-monitor.service
systemctl enable network.service
systemctl disable ntp-wait.service
systemctl enable ntpd.service
systemctl enable postfix.service
systemctl enable purge-kernels.service
systemctl disable rsyncd.service
systemctl disable serial-getty@.service
systemctl enable sshd.service
systemctl disable systemd-bootchart.service
systemctl disable systemd-nspawn@.service
systemctl disable systemd-timesyncd.service
systemctl enable wicked.service
systemctl enable wickedd-auto4.service
systemctl enable wickedd-dhcp4.service
systemctl enable wickedd-dhcp6.service
systemctl enable wickedd-nanny.service
perl /tmp/merge_users_and_groups.pl /etc/passwd /etc/shadow /etc/group
rm /tmp/merge_users_and_groups.pl
rm -rf '/usr/share/doc/packages/rsync/NEWS'
chmod 664 '/usr/share/doc/packages/rsync/README'
chown bin:wheel '/usr/share/doc/packages/rsync/README'
rm -rf '/usr/share/man/man1/sendmail.1.gz'
ln -s '/test-f'\''le' '/usr/share/man/man1/sendmail.1.gz'
chown --no-dereference root:root '/usr/share/man/man1/sendmail.1.gz'
chmod 600 '/etc/crontab'
chown root:root '/etc/crontab'
rm -rf '/etc/postfix/LICENSE'
chmod 666 '/etc/postfix/TLS_LICENSE'
chown bin:users '/etc/postfix/TLS_LICENSE'
rm -rf '/etc/postfix/generic'
ln -s '/test-f'\''le' '/etc/postfix/generic'
chown --no-dereference root:root '/etc/postfix/generic'
# Apply the extracted unmanaged files
find /tmp/unmanaged_files -name *.tgz -exec tar -C / -X '/tmp/unmanaged_files_kiwi_excludes' -xf {} \;
rm -rf '/tmp/unmanaged_files' '/tmp/unmanaged_files_kiwi_excludes'
baseCleanMount
exit 0
