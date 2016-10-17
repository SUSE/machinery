# Copyright (c) 2013-2016 SUSE LLC
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

class BuildTask
  def build(system_description, output_path, options = {})
    LocalSystem.validate_architecture("x86_64")
    LocalSystem.validate_existence_of_packages(["kiwi", "kiwi-desc-vmxboot"])
    system_description.validate_build_compatibility

    tmp_config_dir = Dir.mktmpdir("machinery-config", "/tmp")
    tmp_image_dir = Dir.mktmpdir("machinery-image", "/tmp")
    img_extension = "qcow2"

    config = Machinery::KiwiConfig.new(system_description, options)
    config.write(tmp_config_dir)

    begin
      FileUtils.mkdir_p(output_path)
    rescue Errno::EACCES
      raise Machinery::Errors::BuildDirectoryCreateError.new(output_path, CurrentUser.new.username)
    end

    if tmp_image_dir.start_with?("/tmp/") && tmp_config_dir.start_with?("/tmp/")
      tmp_script = write_kiwi_wrapper(tmp_config_dir, tmp_image_dir,
        output_path, img_extension)

      begin
        with_c_locale do
          LoggedCheetah.run(
            "sudo",
            tmp_script.path,
            stdout: $stdout,
            stderr: $stderr
          )
        end
      rescue SignalException => e
        # Handle SIGHUP(1), SIGINT(2) and SIGTERM(15) gracefully
        if [1, 2, 15].include?(e.signo)
          Machinery::Ui.warn "Warning: Interrupted by user. Waiting for build process to abort..."

          # When we got a SIGHUP or a SIGTERM we send a SIGINT to all processes
          # in our progress group (forked by Cheetah).
          # For SIGINT that's not needed because it is propagated automatically.
          #
          # The reason for killing the child processes with SIGINT (vs SIGTERM)
          # is that with SIGTERM the bash wrapper script around kiwi returns
          # while the unmounting of /proc is still in progress. That would break
          # the cleanup of the temporary kiwi directories below.
          if [1, 15].include?(e.signo)
            trap("INT") {}
            `sudo kill -INT -#{Process.getpgrp}`
          end
          Process.waitall

          Machinery::Ui.warn "Cleaning up temporary files..."
          [tmp_config_dir, tmp_image_dir].each do |path|
            LoggedCheetah.run("sudo", "rm", "-r", path) if Dir.exist?(path)
          end
        end
        raise
      rescue Cheetah::ExecutionFailed
        raise(
          Machinery::Errors::BuildFailed,
          "The execution of the build script failed."
        )
      ensure
        tmp_script.delete
      end
    else
      raise RuntimeError.new(
        "The Kiwi temporary build directories are not in /tmp. This should " \
        "never happen, so nothing is deleted."
      )
    end

    image_file = Dir.glob(File.join(output_path, "*.#{img_extension}")).first

    unless image_file
      raise(Machinery::Errors::BuildFailed, "The image build process failed. Check " \
        "build log '#{tmp_image_dir}/kiwi-terminal-output.log' for more " \
        "details."
      )
    end

    meta_data = {
      description: system_description.name,
      image_file: File.basename(image_file)
    }
    File.write(File.join(output_path, Machinery::IMAGE_META_DATA_FILE),
      meta_data.to_yaml
    )
  end

  def kiwi_wrapper(tmp_config_dir, tmp_image_dir, output_path, image_extension)
    script = "#!/bin/bash\n"
    script << "/usr/sbin/kiwi --build '#{tmp_config_dir}' --destdir '#{tmp_image_dir}' --logfile '#{tmp_image_dir}/kiwi-terminal-output.log'\n"
    script << "if [ $? -eq 0 ]; then\n"
    script << "  mv '#{tmp_image_dir}/'*.#{image_extension} '#{output_path}'\n"
    script << "  rm -rf '#{tmp_image_dir}'\n"
    script << "else\n"
    script << "  echo -e 'Building the Image with Kiwi failed.\nThe Kiwi build directory #{tmp_image_dir} was not removed.'\n"
    script << "fi\n"
    script << "rm -rf '#{tmp_config_dir}'\n"
  end

  def write_kiwi_wrapper(tmp_config_dir, tmp_image_dir, output_path, image_extension)
    begin
      script = Tempfile.new('machinery-kiwi-wrapper-script')
      script << kiwi_wrapper(tmp_config_dir, tmp_image_dir, output_path, image_extension)
    ensure
      script.close unless script == nil
    end
    File.chmod(0755, script.path)
    script
  end
end
