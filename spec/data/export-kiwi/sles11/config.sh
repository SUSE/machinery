test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile
baseMount
suseSetupProduct
suseImportBuildKey
suseConfig
zypper -n ar --name='SLE-11-SLP' --type='yast2' 'http://dist.suse.de/install/SLP/SLES-11-SP3-GM/i386/DVD1/' 'SLE-11-SLP'
zypper -n mr --priority=99 'SLE-11-SLP'
chkconfig arpd off
chkconfig autofs on
chkconfig boot.cgroup off
chkconfig boot.cleanup on
chkconfig boot.clock on
chkconfig boot.debugfs on
chkconfig boot.device-mapper on
chkconfig boot.efivars on
chkconfig boot.ipconfig on
chkconfig boot.klog on
chkconfig boot.ldconfig on
chkconfig boot.loadmodules on
chkconfig boot.localfs on
chkconfig boot.localnet on
chkconfig boot.lvm on
chkconfig boot.lvm_monitor on
chkconfig boot.md on
chkconfig boot.proc on
chkconfig boot.rootfsck on
chkconfig boot.swap on
chkconfig boot.sysctl on
chkconfig boot.udev on
chkconfig boot.udev_retry on
chkconfig cron on
chkconfig dbus on
chkconfig earlysyslog on
chkconfig gpm off
chkconfig haldaemon on
chkconfig haveged on
chkconfig irq_balancer on
chkconfig kbd on
chkconfig lvm_wait_merge_snapshot on
chkconfig mdadmd off
chkconfig netstat off
chkconfig network on
chkconfig network-remotefs on
chkconfig nfs on
chkconfig nfsserver on
chkconfig postfix on
chkconfig powerd off
chkconfig purge-kernels on
chkconfig random on
chkconfig raw off
chkconfig rpasswdd off
chkconfig rpcbind on
chkconfig rpmconfigcheck off
chkconfig rsync off
chkconfig rsyncd off
chkconfig setserial off
chkconfig skeleton.compat off
chkconfig sshd on
chkconfig syslog on
chkconfig systat off
chkconfig uuidd off
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
