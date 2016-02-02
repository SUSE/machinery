#!/bin/bash
# Copyright (c) 2013-2016 SUSE LLC
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

if [ $UID -ne "0" ]; then
   sudoprefix="sudo -n"
fi

for i in $($sudoprefix dpkg --get-selections | grep -v deinstall | awk '{print $1}'); do
  while read f; do
    type=""
    link=""
    path=${f#*:}
    case "$f" in
      directory:*)
        type="d"
        ;;
      symbolic\ link:*)
        type="l"
        link=" -> $($sudoprefix readlink "$path")"
        ;;
      regular*\ file:*)
        type="-"
        ;;
      *)
        ;;
    esac
    echo "$type $path$link"
  done <<< "$($sudoprefix dpkg -L $i | \
    sed -e 's/^package diverts others to: //' \
        -e 's/^diverted by .* to: //' \
        -e 's/^locally diverted to: //' | xargs -n100 -d'\n' $sudoprefix stat -c "%F:%n")"
done
