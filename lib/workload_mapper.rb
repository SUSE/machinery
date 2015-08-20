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
class WorkloadMapper
  def write_compose_file(workloads, path)
    compose_nodes = {}
    workloads.each do |workload, config|
      compose_nodes.merge!(compose_service(workload, config))
    end
    File.write(File.join(path, "docker-compose.yml"), compose_nodes.to_yaml)
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
    template = YAML::load(File.read(File.join(workload_mapper_path, workload, "compose-template.yml")))
    template[workload]
  end

  def identify_workloads(system_description)
    system_description.assert_scopes("services")

    workloads = {}
    mapper = WorkloadMapperDSL.new(system_description)

    Dir["#{File.expand_path(workload_mapper_path)}/*"].each do |workload_dir|
      workload = mapper.check_clue(File.read(File.join(workload_dir, "clue.rb")))
      workloads.merge!(workload.to_h)
    end
    workloads
  end

  private

  def workload_mapper_path
    File.join(Machinery::ROOT, "workload_mapper")
  end

  def compact(service)
    service.each { |_, attr| attr.is_a?(Hash) && attr.reject! { |_, val| val.nil? } }
  end

  def fill_in_template(service, parameters)
    service.each do |sk, sv|
      sv.is_a?(Hash) && sv.each { |ki, kv| service[sk][ki] = parameters[kv.to_s] }
    end
  end
end
