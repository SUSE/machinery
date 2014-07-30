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

class DeployTask
  def deploy(description, cloud_config, options = {})
    Machinery::check_package("python-glanceclient")
    if !File.exists?(cloud_config)
      raise(Machinery::Errors::FileNotFound,
        "The cloud config file '#{cloud_config}' could not be found."
      )
    end

    if options[:image_dir]
      if !Dir.exists?(options[:image_dir])
        raise(Machinery::Errors::FileNotFound,
          "The image directory does not exist."
        )
      end
      image_dir = options[:image_dir]
    else
      image_dir = Dir.mktmpdir("#{description.name}-image", "/tmp")
      is_temporary = true
      task = BuildTask.new
      task.build(description, image_dir)
    end

    meta_data = load_meta_data(image_dir)
    image_file = File.join(image_dir, meta_data[:image_file])

    if meta_data[:description] != description.name
      raise(Machinery::Errors::MissingRequirement,
        "The image file '#{image_file}' was not build from the provided system description."
      )
    end

    if !File.exists?(image_file)
      raise(Machinery::Errors::FileNotFound,
        "The image file '#{image_file}' does not exist."
      )
    end

    command = "/usr/bin/glance"
    command << " --insecure" if options[:insecure]
    command << " image-create"
    command << " --name=#{options[:image_name] || description.name}"
    command << " --disk-format=qcow2 --container-format=bare"
    command << " --file=#{Shellwords.escape(image_file)}"

    system "sh -c '. #{Shellwords.escape(cloud_config)} && #{command}'"

    if is_temporary && image_dir.start_with?("/tmp/")
      FileUtils.rm_rf(image_dir)
    end
  end

  private

  def load_meta_data(meta_dir)
      meta_file = File.join(meta_dir, Machinery::IMAGE_META_DATA_FILE)
      if !File.exists?(meta_file)
        raise(Machinery::Errors::FileNotFound,
          "The meta data file '#{meta_file}' could not be found."
        )
      end

      meta_data = YAML.load_file(meta_file)

      if !meta_data[:image_file] || !meta_data[:description]
        raise(Machinery::Errors::BrokenMetaData,
          "The meta data file '#{meta_file}' is broken."
        )
      end
      meta_data
  end
end
