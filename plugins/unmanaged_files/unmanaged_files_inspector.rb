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

class UnmanagedFilesInspector < Inspector
  has_priority 100

  # checks if all required binaries are present
  def check_requirements(check_tar)
    @system.check_requirement(["rpm", "dpkg"], "--version")
    @system.check_create_archive_dependencies if check_tar
  end

  def initialize(system, description)
    @system = system
    @description = description
  end

  def inspect(filter, options = {})
    do_extract = options[:extract_unmanaged_files]
    check_requirements(do_extract)

    scope = UnmanagedFilesScope.new

    file_store_tmp = @description.scope_file_store("unmanaged_files.tmp")
    file_store_final = @description.scope_file_store("unmanaged_files")

    scope.scope_file_store = file_store_tmp

    file_filter = filter.element_filter_for("/unmanaged_files/name").dup if filter
    file_filter ||= ElementFilter.new("/unmanaged_files/name")
    file_filter.add_matchers("=", @description.store.base_path)

    # Add a recursive pendant to each ignored element
    file_filter.matchers.each do |operator, matchers|
      file_filter.add_matchers(operator, matchers.map { |entry| File.join(entry, "/*") })
    end

    helper = MachineryHelper.new(@system)

    if helper_usable?(helper)
      helper_options = {}
      helper_options[:do_extract] = do_extract
      helper_options[:extract_metadata] = options[:extract_metadata]

      run_helper_inspection(helper, file_filter, file_store_tmp, file_store_final,
        scope, helper_options)
    else
      raise Machinery::Errors::MissingRequirement.new(
        "There is no machinery-helper available for the remote system architecture #{@system.arch}."
      )
    end
  end

  def helper_usable?(helper)
    helper.can_help?
  end

  def run_helper_inspection(helper, filter, file_store_tmp, file_store_final, scope, options)
    begin
      helper.inject_helper
      if !helper.has_compatible_version?
        raise Machinery::Errors::UnsupportedHelperVersion.new(
          "Error: machinery-helper is not compatible with this Machinery version." \
            "\nTry to reinstall the package or gem to fix the issue."
        )
      end

      args = []
      args.push("--extract-metadata") if options[:extract_metadata] || options[:do_extract]

      helper.run_helper(scope, *args)
      scope.delete_if { |f| filter.matches?(f.name) }

      if options[:do_extract]
        mount_points = MountPoints.new(@system)
        excluded_trees = mount_points.remote + mount_points.special

        file_store_tmp.remove
        file_store_tmp.create

        files = scope.select { |f| f.file? || f.link? }.map(&:name)
        scope.retrieve_files_from_system_as_archive(@system, files, [])
        show_extraction_progress(files.count)

        scope.retrieve_trees_from_system_as_archive(@system,
          scope.select(&:directory?).map(&:name), excluded_trees) do |count|
          show_extraction_progress(files.count + count)
        end

        file_store_final.remove
        file_store_tmp.rename(file_store_final.store_name)
        scope.scope_file_store = file_store_final
        scope.extracted = true
        scope.has_metadata = true
      else
        file_store_final.remove
        scope.extracted = false
        scope.has_metadata = !!options[:extract_metadata]
      end
    ensure
      helper.remove_helper
    end

    @description["unmanaged_files"] = scope
  end

  def summary
    "#{@description.unmanaged_files.extracted ? "Extracted" : "Found"} " +
      "#{@description.unmanaged_files.count} unmanaged files and trees."
  end

  private

  def show_extraction_progress(count)
    progress = Machinery::pluralize(
      count, " -> Extracted %d file or tree", " -> Extracted %d files and trees",
    )
    Machinery::Ui.progress(progress)
  end
end
