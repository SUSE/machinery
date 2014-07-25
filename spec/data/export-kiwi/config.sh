test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile
baseMount
suseSetupProduct
suseImportBuildKey
suseConfig
zypper -n ar --name='SUSE-Linux-Enterprise-Server-11-SP3 11.3.3-1.138' --type='yast2' --refresh 'http://example.com/SLES11-SP3' 'SUSE-Linux-Enterprise-Server-11-SP3 11.3.3-1.138'
zypper -n mr --priority=99 'SUSE-Linux-Enterprise-Server-11-SP3 11.3.3-1.138'
chmod 644 '/etc/crontab'
chown root:root '/etc/crontab'
chmod 644 '/usr/share/bash/helpfiles/read'
chown root:root '/usr/share/bash/helpfiles/read'
rm -rf '/usr/share/bash/helpfiles/cd'
chkconfig arpd off
chkconfig autoyast off
chkconfig boot.cgroup off
chkconfig boot.cleanup on
chkconfig boot.clock on
chkconfig boot.compliance on
chkconfig boot.crypto off
chkconfig boot.crypto-early off
chkconfig boot.debugfs on
chkconfig boot.device-mapper on
chkconfig boot.dmraid off
chkconfig boot.efivars on
chkconfig boot.ipconfig on
chkconfig boot.klog on
chkconfig boot.ldconfig on
chkconfig boot.loadmodules on
chkconfig boot.localfs on
chkconfig boot.localnet on
chkconfig boot.lvm off
chkconfig boot.lvm_monitor on
chkconfig boot.md off
chkconfig boot.multipath off
chkconfig boot.proc on
chkconfig boot.rootfsck on
chkconfig boot.swap on
chkconfig boot.sysctl on
chkconfig boot.udev on
chkconfig boot.udev_retry on
chkconfig cron on
chkconfig dbus on
chkconfig fbset on
chkconfig haldaemon on
chkconfig haveged on
chkconfig kbd on
chkconfig lvm_wait_merge_snapshot on
chkconfig mdadmd off
chkconfig multipathd off
chkconfig network on
chkconfig network-remotefs on
chkconfig postfix on
chkconfig powerd off
chkconfig purge-kernels on
chkconfig random on
chkconfig raw off
chkconfig rpasswdd off
chkconfig rpmconfigcheck off
chkconfig rsyncd off
chkconfig setserial off
chkconfig skeleton.compat off
chkconfig sshd on
# Apply the extracted unmanaged files
find /tmp/unmanaged-files -name *.tgz -exec tar -C / -X '/tmp/unmanaged_files_build_excludes' -xf {} \;
rm -rf '/tmp/unmanaged-files' '/tmp/unmanaged_files_build_excludes'
baseCleanMount
exit 0
