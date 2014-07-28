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

require_relative "../../lib/machinery"
require_relative "../../../pennyworth/lib/spec"

def prepare_machinery_for_host(system, ip, opts = {})
  opts = {
    password: "linux",
    user:     "vagrant"
  }.merge(opts)

  system.run_command(
    "cd; pennyworth/bin/pennyworth copy-ssh-keys #{ip} -p #{opts[:password]}; ",
    as: opts[:user]
  )

  system.run_command(
    "echo -e \"Host #{ip}\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null\" >> ~/.ssh/config",
    as: opts[:user]
  )
end

Dir[File.join(Machinery::ROOT, "/spec/integration/support/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.vagrant_dir = File.join(Machinery::ROOT, "spec/definitions/vagrant/")
end
