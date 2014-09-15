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

class UnmanagedFilesInspector < Inspector
  # checks if all required binaries are present
  def check_requirements(system, check_tar)
    system.check_requirement("rpm", "--version")
    system.check_requirement("sed", "--version")
    system.check_requirement("cat", "--version")
    system.check_requirement("find", "--version")
    system.check_requirement("tar", "--version") if check_tar
    system.check_requirement("gzip", "--version") if check_tar
  end

  # extract pathes from rpm database into ruby hashes
  def extract_rpm_database(system)
    out = system.run_command(
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

  def extract_unmanaged_files(system, description, files, trees, excluded, store_name)
    description.remove_file_store(store_name)
    description.initialize_file_store(store_name)
    store_path = description.file_store(store_name)

    archive_path = File.join(store_path, "files.tgz")
    system.create_archive(files.join("\0"), archive_path, excluded)

    trees.each do |tree|
      tree_name = File.basename(tree)
      parent_dir = File.dirname(tree)
      sub_dir = File.join("trees", parent_dir)

      description.create_file_store_sub_dir(store_name, sub_dir)
      archive_path = File.join(store_path, sub_dir, "#{tree_name}.tgz")
      system.create_archive(tree, archive_path, excluded)
    end
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

  # determine all mount points where we have to check for unmanaged files
  def get_mount_points( system )
    allowed_fs = [ "ext2", "ext3", "ext4", "reiserfs", "btrfs", "vfat", "xfs", "jfs" ]
    mounts = []
    out = system.run_command("cat", "/proc/mounts", :stdout => :capture )
    out.split("\n").each do |line|
      dev, mp, fs = line.split(" ")
      mounts << mp[1..-1] if allowed_fs.include?(fs) && mp.size > 1
    end
    mounts.sort!
    Machinery.logger.debug "get_mount_points #{mounts}"
    mounts
  end

  # find paths below dir until a certain depth is reached
  def get_find_data( system, dir, depth )
    dep = depth - 1
    files = {}
    dirs = {}
    excluded_files = []

    # compute command line
    cmd = "find #{dir.shellescape} -xdev -maxdepth 1 -maxdepth #{depth} "
    cmd += '-printf "%y\0%P\0%l\0"'

    # Cheetah seems to be unable to handle binary zeroes "\0" in parameters
    # misuse stdin for command
    #
    # Filenames can contain invalid UTF-8 characters, so we treat the data as
    # binary information first while splitting the raw output and then convert
    # the separate strings to UTF-8, replacing invalid characters with the
    # "REPLACEMENT CHARACTER" (U+FFFD). That way we have both the raw data
    # (which is needed in order to be able to access the files) and the cleaned
    # string which can be safely used.
    out = system.run_command(
      "/bin/bash",
      {
        :stdin           => cmd,
        :stdout          => :capture,
        :disable_logging => true
      }
    ).force_encoding("binary")


    # find creates three field per path
    out.split("\0", -1).each_slice(3) do |type, raw_path, raw_link|
      next unless raw_path && !raw_path.empty?

      path = scrub(raw_path)
      link = scrub(raw_link)

      if [path, link].any? { |f| f.include?("\uFFFD") }
        broken_names = []
        if path.include?("\uFFFD")
          broken_names << "filename '#{path}'"
          excluded_files << raw_path
        end
        if link.include?("\uFFFD")
          broken_names << "link target '#{link}'"
          excluded_files << raw_link
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
    Machinery.logger.debug "get_find_data dir:#{dir} depth:#{depth} file:#{files.size} dirs:#{dirs.size} excluded:#{excluded_files}"
    [files, dirs, excluded_files]
  end

  def max_depth
    6
  end

  def start_depth
    3
  end

  def inspect(system, description, options = nil)
    do_extract = options && options[:extract_unmanaged_files]
    check_requirements(system, do_extract)

    tmp_file_store = "unmanaged_files.tmp"
    final_file_store = "unmanaged_files"


    ignore_list = [ "tmp", "var/tmp", "lost+found", "var/run", "var/lib/rpm",
      ".snapshots", description.store.base_path.sub(/^\//, "")]

    # Information about users and groups are extracted by the according inspector
    ignore_list += [
      "etc/passwd",
      "etc/shadow",
      "etc/group"
    ]

    # Information about services is extracted by the ServicesInspector, so
    # we ignore the links representing the same information when inspecting
    # unmanaged files.
    ignore_list += [
      "etc/init.d/boot.d",
      "etc/init.d/rc0.d",
      "etc/init.d/rc1.d",
      "etc/init.d/rc2.d",
      "etc/init.d/rc3.d",
      "etc/init.d/rc4.d",
      "etc/init.d/rc5.d",
      "etc/init.d/rc6.d",
      "etc/init.d/rcS.d"
    ]

    rpm_files, rpm_dirs = extract_rpm_database(system)
    mounts = get_mount_points( system )
    mounts_abs = mounts.map{ |m| "/" + m }
    mounts_abs << "/"
    Machinery.logger.debug "inspect unmanaged files mounts_abs:#{mounts_abs}"
    unmanaged_files = []
    unmanaged_trees = []
    excluded_files = []
    unmanaged_links = {}
    dirs_todo = [ "/" ]
    start = start_depth
    max = max_depth
    find_count = 0
    while !dirs_todo.empty?
      find_dir = dirs_todo.first

      # determine files and directories below find_dir until a certain depth
      depth = mounts_abs.include?(find_dir) ? start : max
      files, dirs, excluded = get_find_data( system, find_dir, depth )
      excluded_files += excluded
      find_count += 1
      find_dir += "/" if find_dir.size > 1
      if !mounts.empty?
        # force all mount points to be non-leave directories (find is called with -xdev)
        mounts.each do |mp|
          dirs[mp] = true if dirs.has_key?(mp)
        end
        mounts.reject!{ |mp| dirs.has_key?(mp) }
      end
      if find_dir == "/"
        ignore_list.each do |d|
          td_with_slash = d + "/"
          dirs.reject! {|p| p == d || p.start_with?(td_with_slash) }
          files.reject! {|p| p == d || p.start_with?(td_with_slash) }
        end
      end
      managed, unmanaged = dirs.keys.partition{ |d| rpm_dirs.has_key?(find_dir + d) }

      # unmanaged dirs lead to removal of files and dirs below that dir
      while !unmanaged.empty?
        dir = unmanaged.shift

        # save into list of unmanaged trees
        unmanaged_trees << find_dir + dir
        dir += "/"

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
    end
    Machinery.logger.debug "inspect unmanaged files find calls:#{find_count} files:#{unmanaged_files.size} trees:#{unmanaged_trees.size}"
    begin
      if do_extract
        extract_unmanaged_files(system, description, unmanaged_files, unmanaged_trees, excluded_files, tmp_file_store)
      else
        description.remove_file_store(final_file_store)
      end
      osl = unmanaged_files.map do |p|
        type = unmanaged_links.has_key?(p) ? "link" : "file"
        UnmanagedFile.new(name: p, type: type)
      end
      osl += unmanaged_trees.map { |p| UnmanagedFile.new( name: p + "/", type: "dir") }
      if do_extract
        osl = extract_tar_metadata(osl, description.file_store(tmp_file_store))
        description.remove_file_store(final_file_store)
        description.rename_file_store(
          tmp_file_store, final_file_store
        )
      end
    rescue SignalException => e
      # Handle SIGHUP(1), SIGINT(2) and SIGTERM(15) gracefully
      if [1, 2, 15].include?(e.signo)
        STDERR.puts "Interrupted by user. The partly extracted unmanaged-files are available" \
          " under '#{description.file_store(tmp_file_store)}'"
      end
      raise
    end

    summary = "#{do_extract ? "Extracted" : "Found"} #{osl.size} unmanaged files and trees."

    description["unmanaged_files"] = UnmanagedFilesScope.new(
      extracted: !!do_extract,
      files: osl.sort_by(&:name)
    )
    summary
  end

  private

  # Implementation of String#scrub for Ruby < 2.1. Assumes the string is in
  # UTF-8.
  def scrub(s)
    # We have a string in UTF-8 with possible invalid byte sequences. It turns
    # out that String#encode can remove these sequences when given appropriate
    # options, but just converting into UTF-8 would be a no-op. So let's convert
    # into UTF-16 (which has the same character set as UTF-8) and back.
    #
    # See also: http://stackoverflow.com/a/21315619
    s.dup.force_encoding("UTF-8").encode("UTF-16", invalid: :replace).encode("UTF-8")
  end
end
