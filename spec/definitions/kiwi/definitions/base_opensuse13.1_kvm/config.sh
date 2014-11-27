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
# Fixes for base images
#--------------------------------------

echo 'solver.allowVendorChange = true' >> /etc/zypp/zypp.conf
echo 'solver.onlyRequires = true' >> /etc/zypp/zypp.conf

# remove non-static files which break the tests on rebuilds
rm /var/log/YaST2/config_diff_*.log
rm /etc/zypp/repos.d/dir-*.repo

# avoid mac address configured into system, this results in getting
# eth1 instead of eth0 in virtualized environments sometimes
rm -f /etc/udev/rules.d/70-persistent-net.rules

# Disable cron jobs in order to prevent created files breaking the tests
rm /etc/cron.daily/*

#======================================
# Repositories
#--------------------------------------
zypper --gpg-auto-import-keys ar --refresh --name "Main Repository (OSS)" http://download.opensuse.org/distribution/13.1/repo/oss/ download.opensuse.org-oss

#======================================
# Umount kernel filesystems
#--------------------------------------
baseCleanMount

exit 0
