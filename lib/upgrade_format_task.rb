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

class Machinery::UpgradeFormatTask
  def upgrade(store, name, options = {})
    if !options[:all] && !store.list.include?(name)
      raise Machinery::Errors::SystemDescriptionNotFound.new(
        "System description '#{name}' does not exist."
      )
    end

    if options[:all]
      descriptions = store.list
    else
      descriptions = [name]
    end

    errors = []
    migrations_done = 0

    descriptions.each do |description|
      begin
        hash = Manifest.load(description, store.manifest_path(description)).to_hash
        Machinery.logger.info "Upgrading description '#{description}'"
        Machinery::Ui.print "Reading '#{description}' ... "
        migrated = Migration.migrate_description(store, description, force: options[:force])

        if migrated
          migrations_done += 1
          Machinery::Ui.puts "Successfully upgraded from version"\
            " #{hash["meta"]["format_version"]}"\
            " to #{Machinery::SystemDescription::CURRENT_FORMAT_VERSION}."
        end
      rescue StandardError => e
        errors.push("Upgrading description '#{description}' failed:\n#{e}")
        Machinery::Ui.puts "Upgrade failed."
      end
    end

    unless errors.empty?
      Machinery.logger.error errors.join("\n")
      exception = Machinery::Errors::UpgradeFailed.new("\n" + errors.join("\n") +
        Hint.to_string(:upgrade_format_force, name: name || "--all"))
      raise exception
    end

    if options[:all]
      if migrations_done > 0
        Machinery::Ui.puts(
          "Upgraded #{migrations_done} " \
            "#{Machinery.pluralize(migrations_done, "system description", "system descriptions")}."
        )
      else
        Machinery::Ui.puts "No system descriptions were upgraded."
      end
    end
  end
end
