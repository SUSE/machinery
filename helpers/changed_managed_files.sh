#!/bin/bash
# Copyright (c) 2013-2015 SUSE LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail,
# you may find current contact information at www.suse.com

# Exit immediately if a command exits with a non-zero status.
set -e

# Print a list of each package with changed managed files followed by a list of
# the changed files, e.g.
#
#   libpulse0-4.0.git.270.g9490a:
#   S.5......  c /etc/pulse/client.conf
#   ntp-4.2.6p5:
#   S.5......  c /etc/ntp.conf

if [ $UID -ne "0" ]; then
   SUDOPREFIX="sudo -n"
fi

for package in `rpm -qa --queryformat "%{NAME}-%{VERSION}\\n"`; do
  # rpm returns 1 as exit code when modified config files are detected
  # that's why we explicitly detect if sudo failed
  OUTPUT=`$SUDOPREFIX rpm -V --nodeps --nodigest --nosignature --nomtime $package 2>&1 || true`;
  if [ -n "$OUTPUT" ]; then
    REGEX="^sudo:.*password is required"
    if [[ "$OUTPUT" =~ $REGEX ]]; then
      echo "$OUTPUT" >&2
      exit 1
    fi
    echo -e "$package:\\n$OUTPUT";
  fi;
done
