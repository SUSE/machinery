test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile
baseMount
suseSetupProduct
suseImportBuildKey
suseConfig
zypper -n ar --name='openSUSE_13.1_OSS' --type='yast2' --refresh 'http://download.opensuse.org/distribution/13.1/repo/oss/' 'openSUSE_13.1_OSS'
zypper -n mr --priority=99 'openSUSE_13.1_OSS'
zypper -n ar --name='openSUSE_13.1_Updates' --type='rpm-md' --refresh 'http://download.opensuse.org/update/13.1/' 'openSUSE_13.1_Updates'
zypper -n mr --priority=99 'openSUSE_13.1_Updates'
systemctl disable blk-availability.service
systemctl mask cgroup.service
systemctl mask clock.service
systemctl disable console-getty.service
systemctl enable cron.service
systemctl mask crypto-early.service
systemctl mask crypto.service
systemctl disable debug-shell.service
systemctl mask device-mapper.service
systemctl disable dm-event.service
systemctl disable dm-event.socket
systemctl mask earlysyslog.service
systemctl mask earlyxdm.service
systemctl mask kbd.service
systemctl disable klog.service
systemctl disable klogd.service
systemctl mask ldconfig.service
systemctl mask loadmodules.service
systemctl mask localnet.service
systemctl disable lvm2-lvmetad.service
systemctl disable lvm2-lvmetad.socket
systemctl disable lvm2-monitor.service
systemctl enable network.service
systemctl disable plymouth-halt.service
systemctl disable plymouth-kexec.service
systemctl disable plymouth-poweroff.service
systemctl disable plymouth-quit-wait.service
systemctl disable plymouth-quit.service
systemctl disable plymouth-read-write.service
systemctl disable plymouth-reboot.service
systemctl disable plymouth-start.service
systemctl mask proc.service
systemctl enable purge-kernels.service
systemctl disable rpcbind.service
systemctl disable rpcbind.socket
systemctl disable rsyncd.service
systemctl mask single.service
systemctl enable sshd.service
systemctl mask startpreload.service
systemctl mask stoppreload.service
systemctl enable suse-studio-custom.service
systemctl mask swap.service
systemctl enable syslog-ng.service
systemctl enable syslog.service
systemctl enable systemd-readahead-collect.service
systemctl enable systemd-readahead-drop.service
systemctl enable systemd-readahead-replay.service
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
