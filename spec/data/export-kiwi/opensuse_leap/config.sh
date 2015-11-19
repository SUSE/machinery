test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile
baseMount
suseSetupProduct
suseImportBuildKey
suseConfig
zypper -n ar --name='Main Repository (OSS)' --type='yast2' --refresh 'http://download.opensuse.org/distribution/leap/42.1/repo/oss/' 'download.opensuse.org-oss'
zypper -n mr --priority=99 'Main Repository (OSS)'
systemctl enable autofs.service
systemctl disable blk-availability.service
systemctl mask cgroup.service
systemctl mask clock.service
systemctl disable console-getty.service
systemctl enable cron.service
systemctl mask crypto-early.service
systemctl mask crypto.service
systemctl enable dbus-org.opensuse.Network.AUTO4.service
systemctl enable dbus-org.opensuse.Network.DHCP4.service
systemctl enable dbus-org.opensuse.Network.DHCP6.service
systemctl enable dbus-org.opensuse.Network.Nanny.service
systemctl disable debug-shell.service
systemctl mask device-mapper.service
systemctl enable dm-event.service
systemctl enable dm-event.socket
systemctl disable dmraid-activation.service
systemctl mask earlysyslog.service
systemctl mask earlyxdm.service
systemctl disable grub2-once.service
systemctl mask kbd.service
systemctl disable klogd.service
systemctl mask ldconfig.service
systemctl mask loadmodules.service
systemctl mask localnet.service
systemctl disable lvm2-lvmetad.service
systemctl enable lvm2-lvmetad.socket
systemctl disable lvm2-monitor.service
systemctl enable network.service
systemctl disable nfs-blkmap.service
systemctl disable nfs-server.service
systemctl disable nfs.service
systemctl enable nfsserver.service
systemctl mask proc.service
systemctl enable purge-kernels.service
systemctl enable rpcbind.service
systemctl enable rpcbind.socket
systemctl disable rsyncd.service
systemctl mask single.service
systemctl enable sshd.service
systemctl mask startpreload.service
systemctl mask stoppreload.service
systemctl mask swap.service
systemctl enable systemd-readahead-collect.service
systemctl enable systemd-readahead-drop.service
systemctl enable systemd-readahead-replay.service
systemctl enable wicked.service
systemctl enable wickedd-auto4.service
systemctl enable wickedd-dhcp4.service
systemctl enable wickedd-dhcp6.service
systemctl enable wickedd-nanny.service
perl /tmp/merge_users_and_groups.pl /etc/passwd /etc/shadow /etc/group
rm /tmp/merge_users_and_groups.pl
rm -rf '/usr/share/bash/helpfiles/cd'
chmod 644 '/usr/share/bash/helpfiles/read'
chown root:root '/usr/share/bash/helpfiles/read'
chmod 644 '/etc/crontab'
chown root:root '/etc/crontab'
# Apply the extracted unmanaged files
find /tmp/unmanaged_files -name *.tgz -exec tar -C / -X '/tmp/unmanaged_files_kiwi_excludes' -xf {} \;
rm -rf '/tmp/unmanaged_files' '/tmp/unmanaged_files_kiwi_excludes'
baseCleanMount
exit 0
