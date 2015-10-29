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

# Print a list of each package with changed managed files followed by a list of
# the changed files, e.g.
#
#   libpulse0-4.0.git.270.g9490a:
#   S.5......  c /etc/pulse/client.conf
#   ntp-4.2.6p5:
#   S.5......  c /etc/ntp.conf

# Exit immediately if a command exits with a non-zero status.
set -e

if [ $UID -ne "0" ]; then
   sudoprefix="sudo -n"
fi

rpm_supports_noscripts_option () {
  rpm -V --noscripts rpm > /dev/null
}

if rpm_supports_noscripts_option; then
  noscripts="--noscripts"
fi

package_contains_verify_script () {
  rpm --scripts -q $1 | grep "verify scriptlet" > /dev/null
}

check_output () {
  # rpm returns 1 as exit code when modified config files are detected
  # that's why we explicitly detect if sudo failed
  regex="^sudo:.*password is required"
  if [[ "$1" =~ $regex ]]; then
    echo "$1" >&2
    exit 1
  fi
}

inspect_package () {
  package=$1
  output=`$sudoprefix rpm -V --nodeps --nodigest --nosignature --nomtime $noscripts $package 2>&1 || true`

  check_output "$output"

  if [ -z "$noscripts" ] && ( package_contains_verify_script $package ); then
    # remove the lines printed by verify scripts, because we cannot parse these lines
    # in certain rpm versions verify scripts cannot be turned off
    lines=`$sudoprefix rpm -V --nodeps --nodigest --nosignature --nomtime --nofiles $package | wc -l`
    output=`echo -e "$output" | head -n-${lines}`
  fi

  if [ -n "$output" ]; then
    echo -e "$package:\\n$output";
  fi
}

for package in `rpm -qa --queryformat "%{NAME}-%{VERSION}\\n"`; do
  inspect_package $package
done

