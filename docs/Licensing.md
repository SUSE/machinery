# Licensing
This guide describes what license we use and gives developer some instructions how they should implement the license text into documents.

## Our license

Machinery is licensed under the [GPL v3](http://www.gnu.org/copyleft/gpl.html).

## COPYING file

There is a file named COPYING in our repository's root folder. This file contains the full license text.

## License header in source files

All source files of machinery written by SUSE should include this license header:

```
# Copyright (c) 2013-2014 SUSE LLC
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

```

Source files written by other people should include corresponding license headers.

## Licenses of dependencies

All ruby gems that we use in our code must be GPL v3 compatible. We checked this and they were all ok. There is a full list of [licenses of the used ruby gems](https://github.com/SUSE/machinery/blob/master/docs/Licenses-of-Used-Ruby-Gems.md).

For checking additional gems in the future, there's a list of [GPL-compatible](https://www.gnu.org/licenses/license-list.html#GPLCompatibleLicenses) and [-incompatible](https://www.gnu.org/licenses/license-list.html#GPLIncompatibleLicenses) licenses on gnu.org.
