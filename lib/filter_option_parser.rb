# Copyright (c) 2013-2016 SUSE LLC
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

# This class takes care of transforming the user-provided filter options into
# actual Filter objects.
class Machinery::FilterOptionParser
  class <<self
    def parse(command, options)
      filter = Machinery::Filter.from_default_definition(command)

      definitions = skip_files_definitions(options.delete("skip-files"))
      definitions += exclude_definitions(options["exclude"])

      definitions.map! { |definition| definition.gsub("\\@", "@") } # Unescape escaped @s
      definitions.each do |definition|
        filter.add_element_filter_from_definition(definition)
      end

      filter
    end

    private

    def exclude_definitions(exclude)
      return [] unless exclude

      filters = if exclude.start_with?("@")
        expand_filter_file(exclude)
      else
        [exclude]
      end

      filters.reject!(&:empty?) # Ignore empty filters
      filters
    end

    def skip_files_definitions(skip_files)
      return [] unless skip_files

      files = skip_files.split(/(?<!\\),/) # Do not split on escaped commas
      files = files.flat_map do |file|
        if file.start_with?("@")
          expand_filter_file(file)
        else
          file
        end
      end

      files.reject!(&:empty?) # Ignore empty filters
      files.map! { |file| file.chomp("/") } # List directories without the trailing /, in order to
                                            # not confuse the unmanaged files inspector
      files.map { |file| "/unmanaged_files/name=#{file}" }
    end

    def expand_filter_file(path)
      filename = File.expand_path(path[1..-1])

      unless File.exist?(filename)
        raise Machinery::Errors::MachineryError.new(
          "The filter file '#{filename}' does not exist."
        )
      end
      File.read(filename).lines.map(&:strip)
    end
  end
end
