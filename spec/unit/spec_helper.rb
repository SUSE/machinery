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

require "fakefs/spec_helpers"
require "given_filesystem/spec_helpers"

require File.expand_path('../../../lib/machinery', __FILE__)

require_relative "../support/system_description_factory"
require_relative "../support/machinery_output_silencer"
Dir[File.join(Machinery::ROOT, "/spec/unit/support/*.rb")].each { |f| require f }

bin_path = File.expand_path( "../../../bin/", __FILE__ )

if ENV['PATH'] !~ /#{bin_path}/
  ENV['PATH'] = bin_path + File::PATH_SEPARATOR + ENV['PATH']
end

ENV["MACHINERY_LOG_FILE"] = "/tmp/machinery_test.log"
Machinery.initialize_logger("/tmp/machinery_test.log")

RSpec.configure do |config|
  config.include(SystemDescriptionFactory)
  config.include(MachineryOutputSilencer)

  config.before(:each) do
    allow_any_instance_of(System).to receive(:check_requirement)
  end
end


shared_context "machinery test directory" do
  include FakeFS::SpecHelpers

  let(:test_manifest) {
    test_manifest = <<EOF
{
  "packages": [
    {
      "name": "kernel-desktop",
      "version": "3.7.10",
      "release": "1.0",
      "arch": "x86_64",
      "vendor": "openSUSE",
      "checksum": "6aa7aa6af76da1357219b65c5d32a52e"
    }
  ],
  "meta": {
    "format_version": 2
  }
}
EOF
    test_manifest.chomp
  }
  let(:test_base_path) { "/home/tux/.machinery" }
  let(:test_name) { "description1" }

  def create_machinery_dir
    FileUtils.mkdir_p(test_base_path)

    FileUtils.mkdir_p(File.join(test_base_path, test_name), :mode => 0700)
    FileUtils.touch(File.join(test_base_path, "machinery.log"))
    File.write(File.join(test_base_path, test_name, "manifest.json"), test_manifest)
  end
end

module FakeFS
  module FileUtils
    # In FakeFS, FileUtils.rm_rf is implemented as an alias to FileUtils.rm.
    # This is wrong because then an exception is raised when any of the deleted
    # directories doesn't exist.
    def rm_rf(list, options = {})
      rm_r(list, options.merge(force: true))
    end

    # In FakeFS, FileUtils.mkdir_p does not accept the :mode option.
    def mkdir_p(list, options = {})
      list = [list] unless list.is_a?(Array)
      list.each do |path|
        # FileSystem.add call adds all the necessary parent directories but
        # can't set their mode. Thus, we have to collect created directories
        # here and set the mode later.
        if options[:mode]
          created_dirs = []
          dir = path

          until Dir.exists?(dir)
            created_dirs << dir
            dir = File.dirname(dir)
          end
        end

        FileSystem.add(path, FakeDir.new)

        if options[:mode]
          created_dirs.each do |dir|
            File.chmod(options[:mode], dir)
          end
        end
      end
    end
  end
end

def create_transient_system_description(name, json)
  SystemDescription.from_json(name, SystemDescriptionStoreMemory.new, json)
end
