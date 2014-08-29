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

class ListTask
  def list(store, options = {})
    descriptions = store.list.sort

    descriptions.each do |name|
      name = File.basename(name)
      begin
        description = store.load(name)
      rescue Machinery::Errors::SystemDescriptionError
        puts " #{name}:\n"
        puts "   This description has an incompatible data format or is broken.\n" \
             "   Use `machinery validate #{name}` to see the error message.\n\n"
        next
      end
      scopes = []

      description.scopes.each do |scope|
        entry = Machinery::Ui.internal_scope_list_to_string(scope)
        entry += " (extracted)" if description.scope_extracted?(scope)

        if options["verbose"]
          meta = description[scope].meta
          if meta && meta.modified
            time = Time.parse(meta.modified).getlocal
            date = time.strftime "%Y-%m-%d %H:%M:%S"
          else
            date = "unknown"
          end
          if meta && meta.hostname
            hostname = meta.hostname
          else
            hostname = "Unknown hostname"
          end
          entry += "\n      Host: [#{hostname}]"
          entry += "\n      Date: (#{date})"
        end

        scopes << entry
      end

      puts " #{name}:\n   * " + scopes .join("\n   * ") + "\n\n"
    end
  end
end
