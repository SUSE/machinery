module ScopeFileAccessFlat
  def retrieve_files_from_system(system, paths)
    system.retrieve_files(paths, scope_file_store.path)
  end

  def write_file(system_file, target)
    raise Machinery::Errors::FileUtilsError, "Not a file" if !system_file.file?

    target_path = File.join(target, system_file.name)
    FileUtils.mkdir_p(File.dirname(target_path))
    FileUtils.cp(file_path(system_file), target_path)
  end

  def file_path(system_file)
    raise Machinery::Errors::FileUtilsError, "Not a file" if !system_file.file?

    File.join(scope_file_store.path, system_file.name)
  end

  def file_content(system_file)
    if !extracted
      raise Machinery::Errors::FileUtilsError, "The requested file '#{system_file.name}' is" \
        " not available because files for scope '#{scope_name}' were not extracted."
    end

    File.read(file_path(system_file))
  end

  def binary?(system_file)
    path = system_file.scope.file_path(system_file)
    return false if File.zero?(path)

    # Code by https://github.com/djberg96/ptools
    # Modified by SUSE Linux GmbH
    # License: Artistic 2.0
    bytes = File.stat(path).blksize
    bytes = 4096 if bytes > 4096
    s = (File.read(path, bytes) || "")
    s = s.encode("US-ASCII", undef: :replace).split(//)
    ((s.size - s.grep(" ".."~").size) / s.size.to_f) > 0.30
  end

  def has_file?(name)
    return true if files.any? { |file| file.name == name }
  end
end
