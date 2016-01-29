#!/bin/bash
/usr/sbin/useradd -m machinery
echo "machinery:linux" | /usr/sbin/chpasswd
echo 'machinery ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
