class ScopeFileAccess
  def initialize(scope_file_store)
    @scope_file_store = scope_file_store
  end

  # the following methods assume flat file storage

  def retrieve_files_from_system(system, paths)
    system.retrieve_files(paths, @scope_file_store.path)
  end
end
