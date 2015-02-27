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

require "fakefs/spec_helpers"
require "given_filesystem/spec_helpers"

require File.expand_path('../../../lib/machinery', __FILE__)

require_relative "../support/system_description_factory"
require_relative "../support/machinery_output"
Dir[File.join(Machinery::ROOT, "/spec/unit/support/*.rb")].each { |f| require f }

bin_path = File.expand_path( "../../../bin/", __FILE__ )

if ENV['PATH'] !~ /#{bin_path}/
  ENV['PATH'] = bin_path + File::PATH_SEPARATOR + ENV['PATH']
end

ENV["MACHINERY_LOG_FILE"] = "/tmp/machinery_test.log"
Machinery.initialize_logger("/tmp/machinery_test.log")

RSpec.configure do |config|
  config.include(SystemDescriptionFactory)
  config.include(MachineryOutput)

  config.before(:each) do
    allow_any_instance_of(System).to receive(:check_requirement)
  end
end


shared_context "machinery test directory" do
  include FakeFS::SpecHelpers

  let(:test_manifest) { create_test_description(scopes: ["packages"]).to_json }
  let(:test_base_path) { "/home/tux/.machinery" }
  let(:test_name) { "description1" }

  before(:each) do
    FakeFS::FileSystem.clone("schema/")
  end

  def create_machinery_dir(name = test_name)
    FileUtils.mkdir_p(test_base_path)

    FileUtils.mkdir_p(File.join(test_base_path, name), :mode => 0700)
    FileUtils.touch(File.join(test_base_path, "machinery.log"))
    File.write(File.join(test_base_path, name, "manifest.json"), test_manifest)
  end
end
