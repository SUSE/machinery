class ScopeFileAccess
  def initialize(scope, scope_file_store)
    @scope = scope
    @scope_file_store = scope_file_store
  end
end

class ScopeFileAccessFlat < ScopeFileAccess
  def retrieve_files_from_system(system, paths)
    system.retrieve_files(paths, @scope_file_store.path)
  end

  def write_file(system_file, target)
    raise Machinery::Errors::FileUtilsError, "Not a file" if !system_file.file?

    target_path = File.join(target, system_file.name)
    FileUtils.mkdir_p(File.dirname(target_path))
    FileUtils.cp(file_path(system_file), target_path)
  end

  def file_path(system_file)
    raise Machinery::Errors::FileUtilsError, "Not a file" if !system_file.file?

    File.join(@scope_file_store.path, system_file.name)
  end
end

class ScopeFileAccessArchive < ScopeFileAccess
  def retrieve_files_from_system_as_archive(system, files, excluded_files)
    extractor = FileExtractor.new(system, @scope_file_store)
    extractor.extract_files(files, excluded_files)
  end

  def retrieve_trees_from_system_as_archive(system, trees, excluded_files)
    extractor = FileExtractor.new(system, @scope_file_store)
    extractor.extract_trees(trees, excluded_files)
  end

  def export_files_as_tarballs(destination)
    FileUtils.cp(File.join(@scope_file_store.path, "files.tgz"), destination)

    target = File.join(destination, "trees")
    @scope.files.select(&:directory?).each do |system_file|
      raise Machinery::Errors::FileUtilsError if !system_file.directory?

      tarball_target = File.join(target, File.dirname(system_file.name))

      FileUtils.mkdir_p(tarball_target)
      FileUtils.cp(tarball_path(system_file), tarball_target)
    end
  end

  def tarball_path(system_file)
    if system_file.directory?
      File.join(
        system_file.scope.scope_file_store.path,
        "trees",
        File.dirname(system_file.name),
        File.basename(system_file.name) + ".tgz"
      )
    else
      File.join(system_file.scope.scope_file_store.path, "files.tgz")
    end
  end
end
