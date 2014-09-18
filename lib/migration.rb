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

# = SystemDescription Migrations
#
# Migrations are used for migrating descriptions with an older format version to
# the current version. They are defined as subclasses of `Migration` in
# `schema/migrations`.
#
# == Naming schema
#
# Migrations need to follow a naming schema defining which format version they
# are working on. `Migrate1To2` defines a migration which converts a version 1
# description to a version 2 one, for example.
#
# == Defining migrations
#
# The migration classes need to define a `migrate` method which does the actual
# migration. The raw hash of the system description in question is made
# available as the `@hash` instance variable, the path to the description on
# disk is given ash the `@path` instance variable.
#
# Migrations also need to describe their purpose using the `desc` class method
# (see example below).
#
# *Note*: Migrations do not need to take care of updating the format version
# attribute in the system description. That is already handled by the base
# class.
#
# Simple example migration which adds a new attribute to the JSON:
#
#   class Migrate1To2 < Migration
#     desc <<-EOT
#       Add 'foo' element to the system description root.
#     EOT
#
#     def migrate
#       is_extracted = Dir.exists?(File.join(@path, "config-files"))
#       @hash["config_files"]["extracted"] = is_extracted
#     end
#   end
class Migration
  MIGRATIONS_DIR= File.join(Machinery::ROOT, "schema/migrations")

  class <<self
    attr_reader :migration_desc

    def desc(s)
      @migration_desc = s
    end

    def migrate_description(store, description_name)
      load_migrations

      hash = JSON.parse(store.load_json(description_name))
      path = store.description_path(description_name)

      current_version = hash["meta"]["format_version"]
      if !current_version
        raise Machinery::Errors::SystemDescriptionError.new(
          "The system description #{description_name} has an incompatible data " \
          "format and can not be read.\n\n"
        )
      end

      (current_version..SystemDescription::CURRENT_FORMAT_VERSION-1).each do |version|
        next_version = version + 1
        begin
          klass = Object.const_get("Migrate#{version}To#{next_version}")
        rescue NameError
          return
        end

        # Make sure that the migration was documented
        if klass.migration_desc.nil?
          raise Machinery::Errors::MigrationError.new(
            "Invalid migration '#{klass}'. It does not specify its purpose using" \
            " the 'desc' class method."
          )
        end

        klass.new(hash, path).migrate
        hash["meta"]["format_version"] = next_version
      end

      File.write(store.manifest_path(description_name), JSON.pretty_generate(hash))
    end

    private

    def load_migrations
      Dir.glob(File.join(MIGRATIONS_DIR, "*")).each do |migration|
        require migration
      end
    end
  end

  attr_accessor :hash
  attr_accessor :path

  abstract_method :migrate

  def initialize(hash, path)
    @hash = hash
    @path = path
  end
end
