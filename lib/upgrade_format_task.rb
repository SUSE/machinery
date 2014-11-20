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

class UpgradeFormatTask
  def upgrade(store, name, options = {})
    if !options[:all] && !store.list.include?(name)
      raise Machinery::Errors::SystemDescriptionNotFound.new(
        "System description \"#{name}\" does not exist."
      )
    end

    if options[:all]
      descriptions = store.list
    else
      descriptions = [name]
    end

    migrations_done = 0
    descriptions.each do |description|
      begin
        Machinery.logger.info "Upgrading description \"#{description}\""
        migrated = Migration.migrate_description(store, description)
        migrations_done += 1 if migrated
      rescue StandardError => e
        msg = "Upgrading description \"#{description}\" failed: #{e.to_s}"
        Machinery.logger.error msg
        Machinery::Ui.error msg
      end
    end

    if options[:all]
      if migrations_done > 0
        Machinery::Ui.puts "Upgraded #{migrations_done} system descriptions successfully."
      else
        Machinery::Ui.puts "No system descriptions were upgraded."
      end
    else
      if migrations_done > 0
        Machinery::Ui.puts "System description \"#{name}\" successfully upgraded."
      else
        Machinery::Ui.puts "System description \"#{name}\" is up to date, no upgrade necessary."
      end
    end
  end
end
