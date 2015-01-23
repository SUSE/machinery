# unmanaged-files
mkdir /usr/local/magicapp
touch /usr/local/magicapp/one
mkdir /usr/local/magicapp/data
touch /usr/local/magicapp/data/two
touch /etc/magicapp.conf
mkdir /var/lib/chroot_proc
mount --bind /proc /var/lib/chroot_proc
# fix issues of alternating names
rm -rf "/var/lib/yum/history/"*

# config-files
echo '-*/15 * * * *   root  echo config_files_integration_test &> /dev/null' >> /etc/crontab

# changed-managed-files
echo '# changed managed files test entry\n' >> /usr/share/info/sed.info.gz
rm '/usr/share/man/man1/sed.1.gz'

# add NIS placeholder to users/groups
echo "+::::::" >> /etc/passwd
echo "+:::" >> /etc/group

# enable NFS and autofs server for remote file system filtering tests
mkdir -p "/remote-dir/"
mkdir -p "/mnt/unmanaged/remote-dir/"
echo "/tmp     127.0.0.0/8(sync,no_subtree_check)" >> /etc/exports
/usr/sbin/exportfs -a
echo "/remote-dir   /etc/auto.remote_dir" >> /etc/auto.master
echo "server -fstype=nfs 127.0.0.1:/tmp" >> /etc/auto.remote_dir
if [ -x /bin/systemd ]; then
  systemctl enable rpcbind.service
  systemctl enable nfsserver.service
  systemctl enable autofs.service
  systemctl restart rpcbind.service
  systemctl restart nfsserver.service
  systemctl restart autofs.service
else
  if [ -x /etc/init.d/nfsserver ]; then
    /sbin/chkconfig rpcbind on
    /sbin/chkconfig nfsserver on
    /sbin/chkconfig autofs on
    /sbin/rcrpcbind restart
    /usr/sbin/rcnfsserver restart
    /usr/sbin/rcautofs restart
  else
    /sbin/chkconfig nfs on
    /sbin/chkconfig autofs on
    /etc/init.d/nfs restart
    /etc/init.d/autofs restart
  fi
fi
mount -t nfs 127.0.0.1:/tmp "/mnt/unmanaged/remote-dir/"

# mount proc to an uncommon directory for unmanaged-file inspector tests
mkdir -p "/mnt/uncommon-proc-mount"
mount -t proc proc /mnt/uncommon-proc-mount
