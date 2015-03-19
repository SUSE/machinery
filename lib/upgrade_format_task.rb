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

    errors = []
    migrations_done = 0

    descriptions.sort.each do |description|
      begin
        Machinery.logger.info "Upgrading description \"#{description}\""
        Machinery::Ui.puts "Upgrading description \"#{description}\""
        migrated = Migration.migrate_description(store, description, force: options[:force])
        migrations_done += 1 if migrated
      rescue StandardError => e
        errors.push("Upgrading description \"#{description}\" failed:\n#{e}")
      end
    end

    if !errors.empty?
      Machinery.logger.error errors.join("\n")
      raise Machinery::Errors::UpgradeFailed.new(errors.join("\n"))
    end

    if options[:all]
      if migrations_done > 0
        Machinery::Ui.puts "Upgraded #{migrations_done} system descriptions successfully."
      else
        Machinery::Ui.puts "No system descriptions were upgraded."
      end
    elsif migrations_done > 0
      Machinery::Ui.puts "System description \"#{name}\" successfully upgraded."
    end
  end
end
