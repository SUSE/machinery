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

# SystemDescriptionFactory provides factory methods to easily create test
# system descriptions in a temporary environment
module SystemDescriptionFactory
  def self.included(klass)
    klass.extend(self)
  end

  def initialize_system_description_factory_store
    include GivenFilesystemSpecHelpers
    use_given_filesystem
  end

  def system_description_factory_store
    if !(self.class < GivenFilesystemSpecHelpers)
      raise RuntimeError.new("Call 'initialize_system_description_factory_store'" \
        " before trying to access the factory store.")
    end

    @store ||= SystemDescriptionStore.new(given_directory)
  end

  # Generates a system description in the temporary description store from raw
  # JSON. It does not try to parse the JSON into a SystemDescription object, so
  # this can be used to store descriptions with an old format version, for
  # example.
  def store_raw_description(name, json)
    Dir.mkdir(File.join(system_description_factory_store.base_path, name))
    File.write(File.join(system_description_factory_store.base_path, name, "manifest.json"), json)
  end

  # Creates a SystemDescription object. The description and how it is stored can
  # be configured via the options hash.
  #
  # Available options:
  # +name+: The name of the system description. Default: 'description'.
  # +store+: The SystemDescriptionStore where the description should be stored.
  #   Default: The temporary factory description store.
  # +store_on_disk+: If true, the description will be stored in the temporary
  #   description store. If false, the description is only create in-memory.
  # +json+: If this option is given, the system description will be generated
  #   from it. Otherwise an empty description is created.
  def create_test_description(options = {})
    options = {
        name: "description",
        store_on_disk: false
    }.merge(options)

    name  = options[:name] || "description"

    if options[:store_on_disk] && !options[:store]
      store = system_description_factory_store
    else
      store = options[:store]
    end

    if options[:json]
      description = SystemDescription.from_json(name, options[:json], store)
    else
      description = SystemDescription.new(name, {}, store)
    end

    store.save(description) if options[:store_on_disk]

    description
  end
end
