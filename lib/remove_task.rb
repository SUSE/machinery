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

class RemoveTask
  def remove(store, name, options = {})
    if !options[:all] && !store.list.include?(name)
        raise Machinery::Errors::SystemDescriptionNotFound.new(
          "System description \"#{name}\" does not exist."
        )
    end

    if options[:all]
      removed_descriptions = store.list
      removed_descriptions.each do |name|
        store.remove(name)
      end
    else
      store.remove(name)
    end

    if options[:verbose]
      if options[:all]
        puts "Removed #{removed_descriptions.length} system descriptions successfully."
      else
        puts "System description \"#{name}\" successfully removed."
      end
    end
  end
end
