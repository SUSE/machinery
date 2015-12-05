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

for i in $(dpkg --get-selections | grep -v deinstall | awk '{print $1}'); do
  for f in $(dpkg -L $i); do
    TYPE=""
    LINK=""
    if [ -f $f ]; then
      TYPE="-"
    elif [ -d $f ]; then
      TYPE="d"
    elif [ -L $f ]; then
      TYPE="l"
      LINK=" -> $(readlink -f $f)"
    fi

    echo "$TYPE $f$LINK"
  done
done
