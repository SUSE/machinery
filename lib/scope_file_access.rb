class ScopeFileAccess
  def initialize(scope_file_store)
    @scope_file_store = scope_file_store
  end

  # the following methods assume flat file storage

  def retrieve_files_from_system(system, paths)
    system.retrieve_files(paths, @scope_file_store.path)
  end

  # the following methods assume archive file storage

  def retrieve_files_from_system_as_archive(system, files, excluded_files)
    extractor = FileExtractor.new(system, @scope_file_store)
    extractor.extract_files(files, excluded_files)
  end

  def retrieve_trees_from_system_as_archive(system, trees, excluded_files)
    extractor = FileExtractor.new(system, @scope_file_store)
    extractor.extract_trees(trees, excluded_files)
  end
end
