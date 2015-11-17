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

class RpmDatabase
  class ChangedFile < Machinery::Object
    attr_accessor :type

    def initialize(type, attrs)
      super(attrs)
      @type = type
    end

    def config_file?
      @type == "c"
    end
  end

  def initialize(system)
    @system = system
  end

  def changed_files(&block)
    return @changed_files if @changed_files

    out = @system.run_script_with_progress("changed_files.sh", &block)
    result = out.each_line.map do |line|
      line.chomp!
      next unless line.match(/^[^ ]+[ ]+. \/.*$/)

      file, changes, type = parse_rpm_changes_line(line)

      package = @system.run_command("rpm", "-qf", file, stdout: :capture).split.first
      package_name, package_version = package.scan(/(.*)-([^-]*)-[^-]/).first

      ChangedFile.new(
        type,
        name:            file,
        package_name:    package_name,
        package_version: package_version,
        status:          "changed",
        changes:         changes
      )
    end.compact.uniq

    paths = result.reject { |f| f.changes == Machinery::Array.new(["deleted"]) }.map(&:name)
    path_data = get_path_data(paths)
    result.each do |pkg|
      next unless path_data[pkg.name]

      path_data[pkg.name].each do |key, value|
        pkg[key] = value
      end
    end

    @changed_files = result
  end

  def expected_tag?(character, position)
    if @rpm_changes[position] == character
      true
    else
      @unknown_tag ||= ![".", "?"].include?(@rpm_changes[position])
      false
    end
  end

  def parse_rpm_changes_line(line)
    # rpm provides lines per config file where first 9 characters indicate which
    # properties of the file are modified
    @rpm_changes, *fields = line.split(" ")
    # nine rpm changes are known
    @unknown_tag = @rpm_changes.size > 9

    # For config or documentation files there's an additional field which
    # contains "c" or "d"
    type = fields[0].start_with?("/") ? "" : fields.shift
    path = fields.join(" ")

    changes = []
    if @rpm_changes == "missing"
      changes << "deleted"
    elsif @rpm_changes == "........." && path.end_with?(" (replaced)")
      changes << "replaced"
      path.slice!(/ \(replaced\)$/)
    else
      changes << "size" if expected_tag?("S", 0)
      changes << "mode" if expected_tag?("M", 1)
      changes << "md5" if expected_tag?("5", 2)
      changes << "device_number" if expected_tag?("D", 3)
      changes << "link_path" if expected_tag?("L", 4)
      changes << "user" if expected_tag?("U", 5)
      changes << "group" if expected_tag?("G", 6)
      changes << "time" if expected_tag?("T", 7)
      changes << "capabilities" if @rpm_changes.size > 8 && expected_tag?("P", 8)
    end

    if @unknown_tag
      changes << "other_rpm_changes"
    end

    if @rpm_changes.include?("?")
      message = "Could not perform all tests on rpm changes for file '#{path}'."
      Machinery.logger.warn(message)
      Machinery::Ui.warn("Warning: #{message}")
    end

    [path, changes, type]
  end

  def parse_stat_line(line)
    mode, user, group, uid, gid, type, *path_line = line.split(":")
    path = path_line.join(":").chomp

    user = uid if user == "UNKNOWN"
    group = gid if group == "UNKNOWN"

    type = case type
    when "directory"
      "dir"
    when "symbolic link"
      "link"
    when /file$/
      "file"
    else
      raise(
        "The inspection failed because of the unknown type `#{type}` of file `#{path}`."
      )
    end

    [path,
      {
        mode:  mode,
        user:  user,
        group: group,
        type:  type
      }
    ]
  end

  def get_link_target(link)
    @system.run_command(
      "find", link, "-prune", "-printf", "%l",
      stdout:     :capture,
      privileged: true
    ).strip
  end

  # get path data for list of files
  # cur_files is guaranteed to not exceed max command line length
  def get_file_properties(cur_files)
    ret = {}
    out = @system.run_command(
      "stat", "--printf", "%a:%U:%G:%u:%g:%F:%n\\n",
      *cur_files,
      stdout: :capture,
      privileged: true
    )
    out.each_line do |l|
      path, values       = parse_stat_line(l)
      ret[path]          = values
      ret[path][:target] = get_link_target(path) if values[:type] == "link"
    end
    ret
  end

  def get_path_data(paths)
    ret = {}
    path_index = 0
    # arbitrary number for maximum command line length that should always work
    max_len = 50000
    cur_files = []
    cur_len = 0
    while path_index < paths.size
      if cur_files.empty? || paths[path_index].size + cur_len + 1 < max_len
        cur_files << paths[path_index]
        cur_len += paths[path_index].size + 1
        path_index += 1
      else
        ret.merge!(get_file_properties(cur_files))
        cur_files.clear
        cur_len = 0
      end
    end
    ret.merge!(get_file_properties(cur_files)) unless cur_files.empty?
    ret
  end
end
