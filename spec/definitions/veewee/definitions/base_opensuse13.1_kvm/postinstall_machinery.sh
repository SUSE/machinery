#!/bin/bash

# Add 13.1 repositories as they can not be added via
# autoyast due to some bug.
zypper --gpg-auto-import-keys ar --refresh --name "Main Repository (OSS)" http://download.opensuse.org/distribution/13.1/repo/oss/ download.opensuse.org-oss
zypper --gpg-auto-import-keys ar --refresh --name "Main Repository (NON-OSS)" http://download.opensuse.org/distribution/13.1/repo/non-oss/ download.opensuse.org-non-oss

zypper --gpg-auto-import-keys ar --refresh --name "Main Update Repository" http://download.opensuse.org/update/13.1/ download.opensuse.org-update
zypper --gpg-auto-import-keys ar --refresh --name "Update Repository (Non-Oss)" http://download.opensuse.org/update/13.1-non-oss/ download.opensuse.org-13.1-non-oss

zypper --gpg-auto-import-keys ar --disable --refresh --name "openSUSE-13.1-Debug" http://download.opensuse.org/debug/distribution/13.1/repo/oss/ repo-debug
zypper --gpg-auto-import-keys ar --disable --refresh --name "openSUSE-13.1-Update-Debug" http://download.opensuse.org/debug/update/13.1/ repo-debug-update
zypper --gpg-auto-import-keys ar --disable --refresh --name "openSUSE-13.1-Update-Debug-Non-Oss" http://download.opensuse.org/debug/update/13.1-non-oss/ repo-debug-update-non-oss

zypper --gpg-auto-import-keys ar --disable --refresh --name "openSUSE-13.1-Source" http://download.opensuse.org/source/distribution/13.1/repo/oss/ repo-source

# remove non-static files which break the tests on rebuilds
rm /var/log/YaST2/config_diff_*.log
rm /etc/zypp/repos.d/dir-*.repo

# avoid mac address configured into system, this results in getting
# eth1 instead of eth0 in virtualized environments sometimes
rm -f /etc/udev/rules.d/70-persistent-net.rules

# Disable cron jobs in order to prevent created files breaking the tests
rm /etc/cron.daily/*

# Make sure that everything's written to disk, otherwise we sometimes get
# empty files in the image
sync
