docker_registry_config = "/etc/registry/config.yml"
if system.runs_service?("registry") && system.has_file?(docker_registry_config)
  identify "docker-registry", "registry"
  used_port = /.*:(\d\d\d\d+)/.match(system.read_config(docker_registry_config, "addr")).
    to_a.fetch(1, nil)
  port = "#{used_port}:5000"
  parameter "ports", [port]
  parameter "links", ["web"]
  cert = system.read_config(docker_registry_config, "rootcertbundle")
  extract docker_registry_config, "data"
  extract cert, "data"
end
