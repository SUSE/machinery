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
      rescue Machinery::SystemDescriptionNotFoundError => e
        puts e
        next
      end
      output = " #{name}: "
      scopes = []

      description.scopes.each do |scope|
        entry = scope
        entry += " (extracted)" if description.scope_extracted?(scope)

        if options["verbose"]
          meta = description[scope].meta
          if meta && meta.modified
            time = Time.parse(meta.modified).getlocal
            date = time.strftime "%Y-%m-%d %H:%M:%S"
          else
            date = "unknown"
          end
          entry += " (#{date})"
        end

        scopes << entry
      end

      puts output + scopes.join(", ")
    end
  end
end
