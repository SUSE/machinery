#!/bin/bash
#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$kiwi_iname]..."

#======================================
# Mount system filesystems
#--------------------------------------
baseMount

#======================================
# Setup baseproduct link
#--------------------------------------
suseSetupProduct

#======================================
# Add missing gpg keys to rpm
#--------------------------------------
suseImportBuildKey

#======================================
# Activate services
#--------------------------------------
suseInsertService sshd

#======================================
# Setup default target, multi-user
#--------------------------------------
baseSetRunlevel 3

#======================================
# SuSEconfig
#--------------------------------------
suseConfig

#======================================
# Vagrant
#--------------------------------------
date > /etc/vagrant_box_build_time
# set vagrant sudo
printf "%b" "
# added by veewee/postinstall.sh
vagrant ALL=(ALL) NOPASSWD: ALL
" >> /etc/sudoers

# speed-up remote logins
printf "%b" "
# added by veewee/postinstall.sh
UseDNS no
" >> /etc/ssh/sshd_config

#======================================
# Repositories
#--------------------------------------
zypper -n --gpg-auto-import-keys ar --refresh --name "Main Repository (OSS)" http://download.opensuse.org/tumbleweed/repo/oss/ download.opensuse.org-oss
zypper -n --gpg-auto-import-keys ar --refresh --name "Machinery" "http://download.opensuse.org/repositories/systemsmanagement:/machinery/openSUSE_Tumbleweed/" machinery
zypper -n --gpg-auto-import-keys refresh

#======================================
# BTRFS sub volumes
#--------------------------------------
cat <<EOF >> /etc/fstab
/dev/vda1 /home btrfs subvol=@/home 0 0
/dev/vda1 /tmp btrfs subvol=@/tmp 0 0
/dev/vda1 /opt btrfs subvol=@/opt 0 0
/dev/vda1 /srv btrfs subvol=@/srv 0 0
/dev/vda1 /var/crash btrfs subvol=@/var/crash 0 0
/dev/vda1 /var/spool btrfs subvol=@/var/spool 0 0
/dev/vda1 /boot/grub2/i386-pc btrfs subvol=@/boot/grub2/i386-pc 0 0
/dev/vda1 /usr/local btrfs subvol=@/usr/local 0 0
/dev/vda1 /var/log btrfs subvol=@/var/log 0 0
/dev/vda1 /var/opt btrfs subvol=@/var/opt 0 0
/dev/vda1 /var/tmp btrfs subvol=@/var/tmp 0 0
EOF

#======================================
# Umount kernel filesystems
#--------------------------------------
baseCleanMount

exit 0
