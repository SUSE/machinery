module ScopeFileAccessArchive
  def retrieve_files_from_system_as_archive(system, files, excluded_files)
    archive_path = File.join(scope_file_store.path, "files.tgz")
    system.create_archive(files, archive_path, excluded_files)
  end

  def retrieve_trees_from_system_as_archive(system, trees, excluded_files, &callback)
    trees.each_with_index do |tree, index|
      tree_name = File.basename(tree)
      parent_dir = File.dirname(tree)
      sub_dir = File.join("trees", parent_dir)

      scope_file_store.create_sub_directory(sub_dir)
      archive_path = File.join(scope_file_store.path, sub_dir, "#{tree_name}.tgz")
      system.create_archive(tree, archive_path, excluded_files)

      callback.call(index + 1) if callback
    end
  end

  def export_files_as_tarballs(destination)
    FileUtils.cp(File.join(scope_file_store.path, "files.tgz"), destination)

    target = File.join(destination, "trees")
    files.select(&:directory?).each do |system_file|
      raise Machinery::Errors::FileUtilsError if !system_file.directory?

      tarball_target = File.join(target, File.dirname(system_file.name))

      FileUtils.mkdir_p(tarball_target)
      FileUtils.cp(tarball_path(system_file), tarball_target)
    end
  end

  def has_file?(name)
    return true if files.any? { |file| file.name == name }
    if files.any? { |file| file.name == File.join(File.dirname(name), "") }
      tgz_file = File.join(scope_file_store.path, "trees", "#{File.dirname(name)}.tgz")
      return Cheetah.run("tar", "ztf", tgz_file, stdout: :capture).split(/\n/).
        any? { |f| "/#{f}" == name }
    end
    false
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

  def file_content(system_file)
    if !extracted
      raise Machinery::Errors::FileUtilsError, "The requested file '#{system_file.name}' is not" \
        " available because files for scope '#{scope_name}' were not extracted."
    end

    tarball_path = File.join(scope_file_store.path, "files.tgz")
    begin
      Cheetah.run("tar", "xfO", tarball_path, system_file.name.gsub(/^\//, ""), stdout: :capture)
    rescue
      raise Machinery::Errors::FileUtilsError,
        "The requested file '#{system_file.name}' was not found."
    end
  end

  def binary?(system_file)
    content = file_content(system_file)
    return false if content.empty?

    Machinery.content_is_binary?(content.slice(0, 1024))
  end
end
