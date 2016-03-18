# Copyright (c) 2015 SUSE LLC
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
require_relative "feature_spec_helper"

RSpec.describe "Analyze File Diff", type: :feature do
  initialize_system_description_factory_store

  let(:store) { system_description_factory_store }
  let(:description) {
    description = create_test_description(
      scopes:           ["changed_config_files"],
      name:             "name",
      store:            store,
      store_on_disk:    true,
      extracted_scopes: ["changed_config_files"]
    )

    file = description.changed_config_files.find(&:file?)

    File.write(
      File.join(description.description_path, "changed_config_files", file.name),
      "Other content\n"
    )

    diff_file_path = File.join(
      description.description_path,
      "analyze",
      "changed_config_files_diffs",
      File.dirname(file.name)
    )

    FileUtils.mkdir_p(diff_file_path)
    crontab_diff = <<EOF
-Stub data for /etc/cron tab.
\\ No newline at end of file
+Other content
EOF
    File.write(File.join(diff_file_path, "#{File.basename(file.name)}.diff"), crontab_diff)
    description
  }

  context "when showing an analyzed system description" do
    before(:each) do
      description
      Server.set :system_description_store, store
    end

    it "checks the diff" do
      visit("/name")

      link = first(".diff-toggle")
      link.hover

      expect(find(".popover")).to have_content("Changes for '/etc/cron tab'")
    end
  end

end
