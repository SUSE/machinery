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

# The SystemDescriptionStoreMemory class is an implementation of a
# SystemDescriptionStore which keeps the description in memory. It is meant for
# transient storage of a system description when it is only used internally in
# a program and doesn't have to be persisted. Attempts to save the
# description or related data will result in an exception.

class SystemDescriptionStoreMemory
  def persistent?
    false
  end
end
