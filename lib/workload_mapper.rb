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
class Machinery::WorkloadMapper
  def save(workloads, path)
    workloads.each do |workload, config|
      FileUtils.mkdir_p(File.join(path, workload))
      FileUtils.cp_r(
        File.join(workload_mapper_path, workload, "container", "."),
        File.join(path, workload)
      )
    end
    compose_services = compose_services(workloads)
    linked_services = link_compose_services(compose_services)
    File.write(File.join(path, "docker-compose.yml"), linked_services.to_yaml)
    linked_services
  end

  def link_compose_services(services)
    services.each do |service, config|
      config.fetch("links", {}).each do |linked_service|
        services[service]["environment"] ||= {}
        if services[linked_service]
          vars = services[linked_service].fetch("environment", {})
          services[service]["environment"].merge!(vars)
        else
          raise Machinery::Errors::ComposeServiceLink.new(
            "Could not detect '#{linked_service}', which is referenced by '#{service}'."\
          )
        end
      end
    end
  end

  def compose_service(workload, config)
    name = config["service"]
    service = {
      name => compact(load_compose_template(workload))
    }
    fill_in_template(service[name], config["parameters"])
    service
  end

  def load_compose_template(workload)
    template = YAML::load(
      File.read(File.join(workload_mapper_path, workload, "compose-template.yml"))
    )
    template[workload]
  end

  def identify_workloads(system_description)
    system_description.assert_scopes("services", "unmanaged_files", "changed_config_files")

    ["unmanaged_files", "changed_config_files"].each do |scope|
      next if system_description.scope_extracted?(scope)

      raise Machinery::Errors::SystemDescriptionError.new(
        "Required scope: '#{scope}' was not extracted. Can't continue."
      )
    end

    workloads = {}

    Dir["#{File.expand_path(workload_mapper_path)}/*"].each do |workload_dir|
      mapper = Machinery::WorkloadMapperDSL.new(system_description)
      workload = mapper.check_clue(File.read(File.join(workload_dir, "clue.rb")))
      workloads.merge!(workload.to_h)
    end
    workloads
  end

  def fill_in_template(service, parameters)
    service.each do |key, value|
      if value.is_a?(Hash)
        fill_in_template(value, parameters)
      elsif value.is_a?(Symbol)
        service[key] = parameters[value.to_s]
      end
    end
  end

  def extract(system_description, workloads, path)
    Dir.mktmpdir do |dir|
      unless workloads.select { |_, w| w["data"] }.empty?
        system_description.unmanaged_files.export_files_as_tarballs(dir)
        workloads.each do |workload, config|
          config.fetch("data", {}).each do |origin, destination|
            file = system_description.unmanaged_files.find { |f| f.name == origin }
            file ||= system_description.changed_config_files.find { |f| f.name == origin }
            if file && file.directory?
              tgz_file = File.join(dir, "trees", "#{origin.chop}.tgz")
              output_path = File.join(path, workload, destination)
              FileUtils.mkdir_p(output_path)
              strip_number = origin.split("/").size - 1
              Cheetah.run("tar", "zxf", tgz_file, "-C", output_path, "--strip=#{strip_number}")
              copy_workload_changed_config_files(workload, output_path)
            end
            if file && file.file?
              output_path = File.join(path, workload, destination, origin)
              FileUtils.mkdir_p(File.dirname(output_path))
              File.write(output_path, file.content)
            end
          end
        end
      end
    end
  end

  private

  def copy_workload_changed_config_files(workload, path)
    FileUtils.cp_r(File.join(workload_mapper_path, workload, "config", "."), path)
  end

  def workload_mapper_path
    File.join(Machinery::ROOT, "workload_mapper")
  end

  def compact(service)
    service.each { |_, attr| attr.is_a?(Hash) && attr.reject! { |_, val| val.nil? } }
  end

  def compose_services(workloads)
    compose_services = {}
    workloads.each do |workload, config|
      compose_services.merge!(compose_service(workload, config))
    end
    compose_services
  end
end
