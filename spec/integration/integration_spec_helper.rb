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

require_relative "../../lib/machinery"
require_relative "../../../pennyworth/lib/spec"
require_relative "../../../pennyworth/lib/ssh_keys_importer"
require_relative "../support/system_description_factory"

def prepare_machinery_for_host(system, ip, opts = {})
  opts = {
    password: "linux",
    user:     "vagrant"
  }.merge(opts)

  SshKeysImporter.import(ip, opts[:password], File.join(Machinery::ROOT, "spec/keys/machinery_rsa.pub"))

  system.inject_file(
    File.join(Machinery::ROOT, "spec/keys/machinery_rsa"),
    "/home/vagrant/.ssh/id_rsa",
    :owner => "vagrant",
    :mode => "600"
  )

  system.run_command(
    "echo -e \"Host #{ip}\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null\" >> ~/.ssh/config",
    as: opts[:user]
  )
end

Dir[File.join(Machinery::ROOT, "/spec/integration/support/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.include(SystemDescriptionFactory)

  config.vagrant_dir = File.join(Machinery::ROOT, "spec/definitions/vagrant/")
  config.filter_run_excluding :slow => true
end
