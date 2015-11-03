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

$sudoprefix rpm -Va --nodeps --nodigest --nosignature --nomtime $noscripts || true
