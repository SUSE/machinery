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

class RemoveTask
  def remove(store, names, options = {})
    if options[:all]
      removed_descriptions = store.list
      removed_descriptions.each do |name|
        store.remove(name)
      end

      if options[:verbose]
        Machinery::Ui.puts "Removed #{removed_descriptions.length} system descriptions successfully."
      end
    end

    errors = []

    Array(names).each do |name|
      if !store.list.include?(name)
        errors.push("System description '#{name}' does not exist.")
      else
        store.remove(name)
        if options[:verbose]
          Machinery::Ui.puts "System description '#{name}' successfully removed."
        end
      end
    end

    if !errors.empty?
      raise Machinery::Errors::SystemDescriptionNotFound.new(errors.join("\n"))
    end
  end
end
