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

class UnmanagedFilesInspector < Inspector
  has_priority 100

  # checks if all required binaries are present
  def check_requirements(check_tar)
    @system.check_requirement("rpm", "--version")
    @system.check_requirement("sed", "--version")
    @system.check_requirement("cat", "--version")
    @system.check_requirement("find", "--version")
    @system.check_create_archive_dependencies if check_tar
  end

  # extract pathes from rpm database into ruby hashes
  def extract_rpm_database
    out = @system.run_command(
      ["rpm", "-qlav"],
      ["sed", "s/^\\(.\\)[^/]* /\\1 /"],
      :stdout => :capture
    )
    files = {}
    dirh = {}
    links = {}
    # result of above command is lines with type as first character, then a path
    # handled types are: "-" for normal files, "d" for directories, "l" for links
    # links have " -> " with link content after path
    out.each_line do |l|
      type = l[0]
      entry = l[2..-2]
      if type == "-"
        files[entry] = ""
      elsif type == "d"
        dirh[entry] = true
      elsif type == "l"
        pair = entry.split(" -> ",2)
        files[pair.first] = pair[1]
      end
    end
    # make sure that all parent directories of managed rpm directories are considered
    # managed
    dirh.dup.keys.each do |d|
      dir = d.rpartition("/").first

      while !dirh.has_key?(dir) && dir.size > 1
        dirh[dir] = false
        dir = dir[0..dir.rindex("/") - 1]
      end
    end

    files.each do |f,e|
      dir, sep, file = f.rpartition("/")

      # make sure that dirs leading to a managed file are treated as if they were
      # in rpm database, otherwise we cannot exclude whole unmanaged trees
      while( !dirh.has_key?(dir) && dir.size > 1 )
        dirh[dir] = false
        dir=dir[0..dir.rindex("/") - 1]
      end

      # put links to a managed directory also into directory hash
      if !e.empty? && dirh.has_key?(e)
        dirh[f] = false
      end
    end
    Machinery.logger.debug "extract_rpm_database files:#{files.size} dirs:#{dirh.size}"
    [files, dirh]
  end

  def check_consistency(files, dirh)
    p "files=#{files.size} dirs=#{dirh.size}"
    p "dirs in rpmdb=#{dirh.select{|k,e| e}.size} added:#{dirh.select{|k,e| !e}.size}"
    list = files.select { |f| !f.start_with?("/") }
    p "should not happen non-abs file:#{list}" unless list.empty?
    list = dirh.select { |f| !f.start_with?("/") }
    p "should not happen non-abs dirs:#{list}" unless list.empty?
  end

  # extract metadata from extracted tar archives and put data into Object
  def extract_tar_metadata(osl, destdir)
    if Dir.exists?(destdir)
      tarballs = [File.join(destdir, "files.tgz")]
      osl.select{ |os| os.type == "dir" }.map(&:name).each do |d|
        base = File.dirname(d)
        tarballs << File.join(destdir, "trees", base, "#{File.basename(d)}.tgz")
      end

      tarballs.each do | archive|
        files = Tarball.new(archive).list

        files.each do |file|
          os = osl.find do |o|
            o.name == "/#{file[:path]}#{file[:type] == :dir ? "/" : ""}"
          end
          if !os
            raise Machinery::Errors::UnexpectedInputData.new(
              "The inspection failed because of the unexpected input data:\n#{file.inspect}\n\n" \
                "Please file a bug report at: https://github.com/SUSE/machinery/issues/new"
            )
          end

          os.user = file[:user]
          os.group = file[:group]
          if file[:type] != :link
            os.size = file[:size]
            os.mode = file[:mode]
          end

          # unmanaged dirs are trees and only have one entry in the manifest
          if os.type == "dir"
            os.size = files.map { |d| d[:size] }.reduce(:+)
            os.files = files.size
            break
          end
        end
      end
    end
    osl
  end

  # find paths below dir until a certain depth is reached
  def get_find_data(dir, depth )
    dep = depth - 1
    files = {}
    dirs = {}

    # compute command line
    cmd = ["find", dir, "-xdev", "-maxdepth", "1", "-maxdepth", depth.to_s]
    cmd += ["-printf", '%y\0%P\0%l\0']

    out = ""
    begin
      out = @system.run_command(
        *cmd,
        stdout:          :capture,
        disable_logging: true,
        privileged:      true
      ).force_encoding("binary")
    rescue Cheetah::ExecutionFailed => e
      out = e.stdout
      message = "Warning: The command find of the unmanaged-file inspector" \
       " ran into an issue. The error output was:\n#{e.stderr}"
      Machinery.logger.warn(message)
      Machinery::Ui.warn(message)
    end

    # find creates three field per path
    out.split("\0", -1).each_slice(3) do |type, raw_path, raw_link|
      next unless raw_path && !raw_path.empty?

      # Filenames can contain invalid UTF-8 characters, so we treat the data as
      # binary information first while splitting the raw output and then convert
      # the separate strings to UTF-8, replacing invalid characters with the
      # "REPLACEMENT CHARACTER" (U+FFFD). That way we have both the raw data
      # (which is needed in order to be able to access the files) and the cleaned
      # string which can be safely used.
      path = Machinery.scrub(raw_path)
      link = Machinery.scrub(raw_link)

      if [path, link].any? { |f| f.include?("\uFFFD") }
        broken_names = []
        if path.include?("\uFFFD")
          broken_names << "filename '#{path}'"
        end
        if link.include?("\uFFFD")
          broken_names << "link target '#{link}'"
        end

        warning = broken_names.join(" and ")
        warning += " contain#{"s" if broken_names.length == 1}"
        warning += " invalid UTF-8 characters. Skipping."
        warning[0] = warning[0].upcase

        Machinery.logger.warn(warning)
        Machinery::Ui.warn(warning)
        next
      end

      files[path] = link if type == "l"
      files[path] = "" if type == "f"

      # dirs at maxdepth could be non-leafs all othere are leafs
      dirs[path] = path.count("/") == dep if type == "d"
    end
    Machinery.logger.debug "get_find_data dir:#{dir} depth:#{depth} file:#{files.size}" \
      " dirs:#{dirs.size}"
    [files, dirs]
  end

  def max_depth
    6
  end

  def start_depth
    3
  end

  def initialize(system, description)
    @system = system
    @description = description
  end

  def inspect(filter, options = {})
    do_extract = options && options[:extract_unmanaged_files]
    check_requirements(do_extract)

    scope = UnmanagedFilesScope.new

    file_store_tmp = @description.scope_file_store("unmanaged_files.tmp")
    file_store_final = @description.scope_file_store("unmanaged_files")

    scope.scope_file_store = file_store_tmp

    file_filter = filter.element_filter_for("/unmanaged_files/files/name").dup if filter
    file_filter ||= ElementFilter.new("/unmanaged_files/files/name")
    file_filter.add_matchers("=", @description.store.base_path)

    # Add a recursive pendant to each ignored element
    file_filter.matchers.each do |operator, matchers|
      file_filter.add_matchers(operator, matchers.map { |entry| File.join(entry, "/*") })
    end

    helper = MachineryHelper.new(@system)
    if helper_usable?(helper)
      run_helper_inspection(helper, file_filter, do_extract, file_store_tmp, file_store_final,
        scope)
    else
      run_inspection(file_filter, options, do_extract, file_store_tmp, file_store_final, scope)
    end
  end

  def helper_usable?(helper)
    if !helper.can_help?
      Machinery::Ui.puts(
        "Note: Using traditional inspection because there is no helper binary for" \
        " architecture '#{@system.arch}' available."
      )
    elsif @system.respond_to?(:remote_user) && @system.remote_user != "root"
      Machinery::Ui.puts(
        "Note: Using traditional inspection because only 'root' is supported as remote user."
      )
    else
      return true
    end

    false
  end

  def run_helper_inspection(helper, filter, do_extract, file_store_tmp, file_store_final, scope)
    begin
      helper.inject_helper
      if !helper.has_compatible_version?
        raise Machinery::Errors::UnsupportedHelperVersion.new(
          "Error: machinery-helper is not compatible with this Machinery version." \
            "\nTry to reinstall the package or gem to fix the issue."
        )
      end

      scope = helper.run_helper(scope)

      scope.delete_if { |f| filter.matches?(f.name) }

      if do_extract
        mount_points = MountPoints.new(@system)
        excluded_trees = mount_points.remote + mount_points.special

        file_store_tmp.remove
        file_store_tmp.create

        files = scope.files.select { |f| f.file? || f.link? }.map(&:name)
        scope.retrieve_files_from_system_as_archive(@system, files, [])
        show_extraction_progress(files.count)

        scope.retrieve_trees_from_system_as_archive(@system,
          scope.files.select(&:directory?).map(&:name), excluded_trees) do |count|
          show_extraction_progress(files.count + count)
        end

        scope = extract_tar_metadata(scope, file_store_tmp.path)
        file_store_final.remove
        file_store_tmp.rename(file_store_final.store_name)
        scope.scope_file_store = file_store_final
        scope.extracted = true
      else
        file_store_final.remove
        scope.extracted = false
      end
    ensure
      helper.remove_helper
    end

    @description["unmanaged_files"] = scope
  end

  def run_inspection(file_filter, options, do_extract, file_store_tmp, file_store_final, scope)
    mount_points = MountPoints.new(@system)

    rpm_files, rpm_dirs = extract_rpm_database

    # Btrfs subvolumes and local mounts need to be inspected separately because
    # they are not part of the `get_find_data` return data
    local_filesystems = mount_points.local + btrfs_subvolumes

    unmanaged_files = []
    unmanaged_trees = []
    excluded_files = []
    unmanaged_links = {}
    remote_dirs = mount_points.remote
    special_dirs = mount_points.special


    remote_dirs.delete_if { |e| file_filter.matches?(e) }

    excluded_files += remote_dirs
    excluded_files += special_dirs

    if options[:verbose] && !remote_dirs.empty?
      warning = "The content of the following remote directories is ignored:" \
        " #{remote_dirs.uniq.join(", ")}."
      Machinery.logger.warn(warning)
      Machinery::Ui.warn(warning)
    end
    if options[:verbose] && !special_dirs.empty?
      warning = "The content of the following special directories is ignored:" \
        " #{special_dirs.uniq.join(", ")}."
      Machinery.logger.warn(warning)
      Machinery::Ui.warn(warning)
    end

    dirs_todo = ["/"]
    start = start_depth
    max = max_depth
    find_count = 0
    sub_tree_containing_remote_fs = []

    while !dirs_todo.empty?
      find_dir = dirs_todo.first

      # determine files and directories below find_dir until a certain depth
      depth = local_filesystems.include?(find_dir) ? start : max
      files, dirs = get_find_data(find_dir, depth)
      find_count += 1
      find_dir += "/" if find_dir.size > 1
      if !local_filesystems.empty?
        # force all mount points to be non-leave directories (find is called with -xdev)
        local_filesystems.each do |mp|
          dirs[mp] = true if dirs.has_key?(mp)
        end
        local_filesystems.reject! { |mp| dirs.has_key?(mp) }
      end
      if find_dir == "/"
        dirs.reject! do |dir|
          file_filter.matches?("/" + dir)
        end

        files.reject! do |dir|
          file_filter.matches?("/" + dir)
        end
      end
      managed, unmanaged = dirs.keys.partition{ |d| rpm_dirs.has_key?(find_dir + d) }

      # unmanaged dirs lead to removal of files and dirs below that dir
      while !unmanaged.empty?
        dir = unmanaged.shift

        # Ignore special mounts, e.g. procfs mounts in a chroot
        next if special_dirs.include?(find_dir + dir)

        # save into list of unmanaged trees
        if !remote_dirs.include?(find_dir + dir)
          unmanaged_trees << find_dir + dir
        end
        dir = File.join(dir, "/")

        # find sub trees containing remote file systems
        remote_dirs.each do |remote_dir|
          if unmanaged.include?(remote_dir[1..-1])
            sub_tree_containing_remote_fs << remote_dir
            unmanaged = unmanaged.drop_while{ |d| d.start_with?(remote_dir[1...-1]) }
          end
        end
        # remove all possible further references starting with this subdir
        unmanaged = unmanaged.drop_while{ |d| d.start_with?(dir) }
        files.reject!{ |d| d.start_with?(dir) }
      end

      # remove all (currently known) leaf directories
      managed.select!{ |d| dirs[d] }

      # update list for still to handle directories
      dirs_todo.shift
      managed.map!{ |d| find_dir + d }
      dirs_todo.push(*managed)

      # unmanaged files are simply stored
      managed, unmanaged = files.keys.partition{ |d| rpm_files.has_key?(find_dir + d) }
      links = unmanaged.reject { |d| files[d].empty? }
      unmanaged.map!{ |d| find_dir + d }
      unmanaged_files.push(*unmanaged)
      links.each { |d| unmanaged_links[find_dir + d] = "" }

      count = unmanaged_files.length + unmanaged_trees.length
      progress = Machinery::pluralize(
        count, " -> Found %d file or tree...", " -> Found %d files and trees...",
      )
      Machinery::Ui.progress(progress)
    end
    Machinery.logger.debug "inspect unmanaged files find calls:#{find_count} files:#{unmanaged_files.size} trees:#{unmanaged_trees.size}"

    processed_files = run_extraction(unmanaged_files, unmanaged_trees, unmanaged_links,
      excluded_files, remote_dirs, do_extract, file_store_tmp, file_store_final, scope)

    scope.extracted = !!do_extract
    scope += processed_files.sort_by(&:name)
    @description["unmanaged_files"] = scope
  end

  def run_extraction(unmanaged_files, unmanaged_trees, unmanaged_links, excluded_files, remote_dirs,
      do_extract, file_store_tmp, file_store_final, scope)
    begin
      if do_extract
        file_store_tmp.remove
        file_store_tmp.create

        scope.retrieve_files_from_system_as_archive(@system,
          unmanaged_files, excluded_files)
        show_extraction_progress(unmanaged_files.count)

        scope.retrieve_trees_from_system_as_archive(@system,
          unmanaged_trees, excluded_files) do |count|
          show_extraction_progress(unmanaged_files.count + count)
        end
      else
        file_store_final.remove
      end
      osl = unmanaged_files.map do |p|
        type = unmanaged_links.has_key?(p) ? "link" : "file"
        UnmanagedFile.new(name: p, type: type)
      end
      osl += unmanaged_trees.map { |p| UnmanagedFile.new( name: p + "/", type: "dir") }
      if do_extract
        osl = extract_tar_metadata(osl, file_store_tmp.path)
        file_store_final.remove
        file_store_tmp.rename(file_store_final.store_name)
        scope.scope_file_store = file_store_final
      end
    rescue SignalException => e
      # Handle SIGHUP(1), SIGINT(2) and SIGTERM(15) gracefully
      if [1, 2, 15].include?(e.signo)
        Machinery::Ui.warn "Interrupted by user. The partly extracted unmanaged-files are available" \
          " under '#{@description.file_store(file_store_tmp)}'"
      end
      raise
    end
    remote_dirs.each do |remote_dir|
      osl << UnmanagedFile.new( name: remote_dir + "/", type: "remote_dir")
    end

    osl
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

  def btrfs_subvolumes
    @system.run_command(
      ["btrfs", "subvolume", "list", "/"],
      ["awk", "{print $NF}"],
      stdout: :capture
    ).split
  end
end
