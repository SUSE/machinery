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
zypper -n --gpg-auto-import-keys ar --refresh --name "Main Repository (OSS)" http://download.opensuse.org/distribution/13.1/repo/oss/ download.opensuse.org-oss
zypper -n --gpg-auto-import-keys ar --refresh --name "Main Update Repository" http://download.opensuse.org/update/13.1/ download.opensuse.org-update
zypper -n refresh

#======================================
# Umount kernel filesystems
#--------------------------------------
baseCleanMount

exit 0
