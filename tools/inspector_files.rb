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


# This script creates reference data for integration tests
# by inspecting existing machines.
# Therefor it generates files with information of each scope.

# Usage: rake inspector_files[ip-adress,distribution]

require "fileutils"
require "cheetah"

class ReferenceTestData
  def initialize
    @machinery = File.expand_path("../bin/machinery", File.dirname(__FILE__))
    @test_data_path = File.expand_path("../spec/data/", File.dirname(__FILE__))
  end

  def inspect(ip_adress)
    Cheetah.run(@machinery, "inspect", ip_adress, "-xn", "referencetestdata", stdout: :capture)
  end

  def write(destination)
    Inspector.all_scopes.each do |inspector|
      output = Cheetah.run(
        @machinery, "show", "-s", inspector.tr("_", "-"),
        "referencetestdata", stdout: :capture
      )
      File.write(file_path(inspector, destination), output)
    end
  end

  def file_path(inspector, destination)
    FileUtils.mkdir_p("#{@test_data_path}/#{inspector}")
    File.join(@test_data_path, inspector, destination)
  end
end
