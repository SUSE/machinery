# Copyright (c) 2013-2014 SUSE LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail,
# you may find current contact information at www.suse.com

class Hint
  def self.show(hint, options = {})
    text = "\nHint: "
    case hint
    when :how_to_get_started
      text += "You can get started by inspecting a system. Run:\n"
      text += "#{$0} inspect HOSTNAME"
    when :how_to_show_data
      text += "To show the data of the system you just inspected run:\n"
      text += "#{$0} show #{options[:name]}"
    when :how_to_do_complete_inspection
      text += "To do a full inspection containing all scopes and to extract files run:\n"
      text += "#{$0} inspect #{options[:host]} --name #{options[:name]} --extract-files"
    end
    puts text
  end
end
