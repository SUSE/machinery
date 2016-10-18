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

require_relative "spec_helper"

describe Machinery::Rpm do
  subject {
    Machinery::Rpm.new(
      File.join(
        Machinery::ROOT, "spec/data/changed_config_files/minimal-config-file-1-0.x86_64.rpm"
      )
    )
  }
  describe "#diff" do
    it "extracts the file and generates the diff" do
      new_config = Tempfile.new("new_config_file")
      new_config << "key=new_value"
      new_config.close

      expected = <<EOF
@@ -1 +1 @@
-key=value
+key=new_value
\\ No newline at end of file
EOF

      diff = subject.diff("/etc/my_config_file", new_config.path)

      expect(diff).to include(expected)
    end
  end
end
