# Install test data RPM
rpm -i /vagrant/SUSE-test-data-files-1.0-1.noarch.rpm || rpm -i /vagrant/RedHat-test-data-files.noarch.rpm

# enable NFS and autofs server for remote file system filtering tests
mkdir -p "/remote-dir/"
mkdir -p "/mnt/unmanaged/remote-dir/"
echo "/opt     127.0.0.0/8(sync,no_subtree_check)" >> /etc/exports
/usr/sbin/exportfs -a
echo "/remote-dir   /etc/auto.remote_dir" >> /etc/auto.master
echo "server -fstype=nfs 127.0.0.1:/opt" >> /etc/auto.remote_dir
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
mount -t nfs 127.0.0.1:/opt "/mnt/unmanaged/remote-dir/"

# mount proc to an uncommon directory for unmanaged-file inspector tests
mkdir -p "/mnt/uncommon-proc-mount"
mount -t proc proc /mnt/uncommon-proc-mount

# change content of /etc/stat-test/test.conf
echo "My pretty changes!" > /etc/stat-test/test.conf

