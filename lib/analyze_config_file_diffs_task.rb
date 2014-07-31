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

class AnalyzeConfigFileDiffsTask
  def analyze(description)
    description.assert_scopes("repositories", "config-files")
    if !description.file_store("config-files")
      raise Machinery::Errors::SystemDescriptionIncomplete.new(
        "Missing extracted config files.\n" \
        "You can extract them using 'machinery inspect -s config-files -x'."
      )
    end

    with_repositories(description) do |zypper|
      description.initialize_file_store("config-file-diffs")
      diffs_path = description.file_store("config-file-diffs")
      extracted_files_path = description.file_store("config-files")

      puts "Generating diffs..."
      cnt = 1
      list = files_by_package(description)
      total = list.map(&:files).flatten.length.to_s
      list.each do |package|
        path = zypper.download_package("#{package.name}-#{package.version}")

        if !path || path.empty?
          STDERR.puts "Warning: Could not download package #{package.name}-#{package.version}."
          cnt += package.files.length
          next
        end

        package.files.each do |file|
          diff = Rpm.new(path).diff(file, File.join(extracted_files_path, file))

          if !diff || diff.empty?
            STDERR.puts "Warning: Could not generate diff for #{file}."
          else
            diff_path = File.join(diffs_path, file + ".diff")
            FileUtils.mkdir_p(File.dirname(diff_path))
            File.write(diff_path, diff)
            puts "[#{cnt.to_s.rjust(total.length)}/#{total}] #{file}"
          end

          cnt += 1
        end
      end
      puts "done"
    end
  end

  private

  # Creates an array of hashes with the RPM names, version and the list of
  # changed file paths, e.g.
  #
  # [
  #   {
  #     "name"    => "aaa_base",
  #     "version" => "3.11.1",
  #     "files"   => ["/etc/modprobe.d/unsupported-modules", "/etc/inittab"]
  #   }
  # ]
  def files_by_package(description)
    files = description["config-files"].
      select { |f| f.changes.include?("md5") }

    files.inject({}) do |result, file|
        key = "#{file.package_name}-#{file.package_version}"
        result[key] ||= Package.new(
          "name"    => file["package_name"],
          "version" => file["package_version"],
          "files"   => []
        )

        result[key]["files"] << file.name
        result
    end.values
  end

  def with_repositories(description, &block)
    puts "Setting up repository access..."
    Zypper.isolated do |zypper|
      begin
        remote_repos = description.repositories.reject do |repo|
          repo.url.start_with?("cd://") || repo.url.start_with?("dvd://")
        end
        remote_repos.each do |repo|
          uri = URI.parse(repo.url)

          if repo.username && repo.password
            uri.user = repo.username
            uri.password = repo.password
          end

          zypper.add_repo(uri.to_s, repo.alias)
        end

        begin
          zypper.refresh
        rescue Cheetah::ExecutionFailed => e
          # If zypper is locked (exit code 7) we're doomed. Bail out completeley.
          raise if e.status.exitstatus == 7

          # Refreshing repositories might fail for various other reasons, but we
          # still stick to the plan because the relevant config files might be
          # available from the other repositories.
          # If they aren't an error message will then be generated for each of
          # the actually missing files instead.
          Machinery.logger.error(e.message)
          Machinery.logger.debug(e.backtrace.join("\n"))
          Machinery.logger.debug("Standard output:\n #{e.stdout}")
          Machinery.logger.debug("Error output:\n #{e.stderr}")
        end

        block.call(zypper)
      end
    end
  end
end
