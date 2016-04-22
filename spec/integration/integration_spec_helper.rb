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

require "etc"
require "yaml"

require_relative "../../lib/machinery"
require_relative "../../../pennyworth/lib/pennyworth/spec"
require_relative "../../../pennyworth/lib/pennyworth/ssh_keys_importer"
require_relative "../support/system_description_factory"

def prepare_machinery_for_host(system, ip, opts = {})
  if system.runner.is_a?(Pennyworth::LocalRunner)
    prepare_local_machinery_for_host(system, ip)
  else
    prepare_remote_machinery_for_host(system, ip, opts)
  end
end

def prepare_local_machinery_for_host(system, ip)
  system.run_command("ssh-keygen -R #{ip}")
  system.run_command("ssh-keyscan -H #{ip} >> ~/.ssh/known_hosts")
end

def prepare_remote_machinery_for_host(system, ip, opts)
  if opts[:password]
    Pennyworth::SshKeysImporter.import(
      ip,
      opts[:username] || "root",
      opts[:password],
      File.join(Machinery::ROOT, "spec/keys/machinery_rsa.pub")
    )
  end

  system.inject_file(
    File.join(Machinery::ROOT, "spec/keys/machinery_rsa"),
    "/home/vagrant/.ssh/id_rsa",
    owner: "vagrant",
    mode: "600"
  )

  system.run_command(
    "echo -e \"Host #{ip}\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null\" >> ~/.ssh/config",
    as: "vagrant"
  )
end

def normalize_inspect_output(output)
  output.
    gsub(/x86_64|i\d86/, "<arch>"). # Normalize architectures
    gsub(/\d+/, "0"). # Normalize output
    gsub(/(\r\033\[K.*?\r\033\[K).*\r\033\[K(.*)/, "\\1\\2") # strip all progress messages but two
end

def machinery_host(description)
  description.sub!(/.*@/, "")
end

def boxes
  {
    "openSUSE_13_2:x86_64" => "opensuse132",
    "openSUSE_13_1:x86_64" => "opensuse131",
    "leap:x86_64" => "opensuse_leap",
    "sles12:x86_64" => "sles12",
    "sles11:x86_64" => "sles11sp4",
    "rhel5" => "rhel5",
    "rhel6" => "rhel6",
    "docker:openSUSE_13_2" => "base_opensuse13.2"
  }
end

def servers
  {
    "sles12:power_le" => "sles12:power_le",
    "sles12:s390x" => "sles12:s390x"
  }
end

def test_group_hierarchy
  {
    "full" => %w(full_test acceptance_test),
    "acceptance" => %w(acceptance_test)
  }
end

def matrix_path
  File.join(Machinery::ROOT, "spec", "definitions", "support", "integration_tests.yml")
end

def validate_test_group
  ENV["TESTGROUP"] = "full" if ENV["TESTGROUP"].nil?

  message = "#{ENV["TESTGROUP"]} is not a supported TESTGROUP. Valid are acceptance, minimal, full."
  abort message unless test_group_hierarchy.keys.include?(ENV["TESTGROUP"])
end

def include_examples_for_platform(currently_running_on)
  integration_tests = YAML.load_file(matrix_path)

  validate_test_group

  integration_tests.each do |test, support_levels|
    support_levels.each do |_level, matrix|
      matrix.select { |host, _guests| host.include?(currently_running_on) }.each do |_host, guests|
        guests.select! do |_guest, test_group|
          test_group_hierarchy[ENV["TESTGROUP"]].include?(test_group)
        end
        guests.each do |guest, _test_group|
          include_examples test, "#{boxes[guest]}" if boxes[guest]
          include_examples "#{test} #{servers[guest]}" if servers[guest]
          include_examples test if guest == "local"
        end
      end
    end
  end
end

Dir[File.join(Machinery::ROOT, "/spec/integration/support/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.before(:suite) do
    Dir.chdir(File.join(Machinery::ROOT, "machinery-helper")) do
      Cheetah.run("rake", "build")
    end
  end

  config.include(SystemDescriptionFactory)

  config.vagrant_dir = File.join(Machinery::ROOT, "spec/definitions/vagrant/")
  config.filter_run_excluding slow: true
end
