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

class DockerSystem < System
  attr_accessor :image

  def type
    "docker"
  end

  def initialize(image)
    @image = image

    validate_image_name(image)
  end

  def start
    @container = LoggedCheetah.run("docker", "run", "-id", @image, "bash", stdout: :capture).chomp
  rescue Cheetah::ExecutionFailed => e
    raise Machinery::Errors::MachineryError, "Container could not be started." \
      " The error message was:\n" + e.stderr
  end

  def stop
    LoggedCheetah.run("docker", "rm", "-f", @container) if @container
  end

  def run_command(*args)
    Machinery.logger.info("Running '#{args}'")
    LoggedCheetah.run("docker", "exec", "--user=root", "-i", @container, *args)
  end

  def check_retrieve_files_dependencies
    # Files are retrieved using the `docker cp` command, so there are no additional dependencies
  end

  def check_create_archive_dependencies
    # Archives are created using the machinery-helper binary, so there are no additional
    # dependencies
  end

  # Reads a file from the System. Returns nil if it does not exist.
  def read_file(file)
    run_command("cat", file, stdout: :capture)
  rescue Cheetah::ExecutionFailed => e
    if e.status.exitstatus == 1
      # File not found, return nil
      return
    else
      raise
    end
  end

  # Removes a file from the System
  def remove_file(file)
    run_command("rm", file)
  rescue => e
    raise Machinery::Errors::RemoveFileFailed.new(
      "Could not remove file '#{file}'.\nError: #{e}"
    )
  end

  # Copies a file to the system
  def inject_file(source, destination)
    LoggedCheetah.run("docker", "cp", source, "#{@container}:#{destination}")
  end

  # Retrieves files specified in file_list from the container
  def retrieve_files(file_list, destination)
    file_list.each do |file|
      destination_path = File.join(destination, file)
      FileUtils.mkdir_p(File.dirname(destination_path), mode: 0700)

      LoggedCheetah.run("docker", "cp", "#{@container}:#{file}", "#{destination_path}")
      LoggedCheetah.run("chmod", "go-rwx", destination_path)
    end
  end

  # Retrieves files specified in file_list from the container and creates an archive.
  def create_archive(file_list, archive, exclude = [])
    created = !File.exists?(archive)
    out = File.open(archive, "w")
    begin
      run_command(
        File.join(
          Machinery::REMOTE_HELPER_PATH, "machinery-helper"
        ), "tar", "--create", "--gzip", "--null", "--files-from=-",
        *exclude.flat_map { |f| ["--exclude", f] },
        stdout: out,
        stdin: Array(file_list).join("\0"),
        stderr: STDERR
      )
    rescue Cheetah::ExecutionFailed => e
      if e.status.exitstatus == 1
        # The tarball has been created successfully but some files were changed
        # on disk while being archived, so we just log the warning and go on
        Machinery.logger.info e.stderr
      else
        raise
      end
    end
    out.close
    File.chmod(0600, archive) if created
  end

  def requires_root?
    false
  end

  private

  def validate_image_name(image)
    images = LoggedCheetah.run("docker", "images", stdout: :capture).split("\n")

    if !images.find { |i| i.start_with?("#{image} ") || i.index(" #{image} ") }
      raise Machinery::Errors::InspectionFailed.new(
        "Unknown docker image: '#{image}'"
      )
    end
  end
end
