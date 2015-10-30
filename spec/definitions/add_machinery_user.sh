#!/bin/bash
/usr/sbin/useradd -m machinery
echo "machinery:linux" | /usr/sbin/chpasswd
echo 'machinery ALL=(ALL) NOPASSWD: /usr/bin/find,/usr/bin/cat,/bin/cat,/usr/bin/rsync,/bin/rpm -Va *,/bin/tar --create *' >> /etc/sudoers
