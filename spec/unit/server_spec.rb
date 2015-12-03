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

require_relative "spec_helper"

describe Server do
  initialize_system_description_factory_store
  include Rack::Test::Methods

  let(:description_a) {
    create_test_description(
      name: "description_a",
      store_on_disk: true,
      extracted_scopes: ["config_files"],
      scopes: ["os"]
    )
  }

  let(:description_b) {
    create_test_description(
      name: "description_b",
      store_on_disk: true,
      extracted_scopes: ["unmanaged_files"],
      scopes: ["os"]
    )
  }
  let(:description_c) {
    description = create_test_description(
      name: "description_c",
      store_on_disk: true,
      extracted_scopes: ["config_files"],
      scopes: ["os"]
    )

    file = description.config_files.find { |f| f.name == "/etc/cron tab" }
    File.write(description.config_files.file_path(file), "Other content")

    description
  }

  def app
    Server
  end

  before(:each) do
    Server.set :system_description_store, description_a.store
  end

  describe "show" do
    describe "GET /:id" do
      it "returns the page" do
        get "/#{description_a.name}"

        expect(last_response).to be_ok
        expect(last_response.body).
          to include("#{description_a.name} - Machinery System Description")
      end
    end

    describe "GET /descriptions/:id/files/:scope" do
      it "sends the file" do
        get "/descriptions/#{description_a.name}/files/config_files/etc/cron%20tab"

        expect(last_response).to be_ok
        expect(last_response.headers["Content-Type"]).to include("text/plain")
        expect(last_response.body).to eq("Stub data for /etc/cron tab.")
      end
    end
  end

  describe "compare" do
    describe "GET /compare/:a/:b" do
      it "returns the page" do
        get "/compare/#{description_a.name}/#{description_b.name}"

        expect(last_response).to be_ok
        expect(last_response.body).to include("Machinery System Description Comparison")
      end
    end

    describe "GET /compare/:a/:b/files/:scope" do
      it "sends the diff between the files" do
        get "/compare/#{description_a.name}/#{description_c.name}/files/config_files/etc/cron%20tab"

        expect(last_response).to be_ok
        expect(last_response.body).to eq(<<EOF)
<div class="diff">
  <ul>
    <li class="del"><del><span class="symbol">-</span><strong>Stub data for /etc/cron tab.</strong></del></li>
    <li class="ins"><ins><span class="symbol">+</span><strong>Other content</strong></ins></li>
  </ul>
</div>
EOF
      end
    end
  end

  describe Server::Helpers do
    include Server::Helpers

    describe "#diff_to_object" do
      let(:diff) { <<EOF }
--- a/etc/postfix/TLS_LICENSE
+++ b/etc/postfix/TLS_LICENSE
@@ -1,15 +1,14 @@
 Author:
 =======
 - Postfix/TLS support was originally developed by Lutz Jaenicke of
-  Brandenburg University of Technology, Cottbus, Germany.
+  Brandenburg University of Technology, Cottbus, Germany. Change one

 License:
 ========
 - This software is free. You can do with it whatever you want.
   I would however kindly ask you to acknowledge the use of this
-  package, if you are going use it in your software, which you might
-  be going to distribute. I would also like to receive a note if
   you are a satisfied user :-)
+  Change two

 Acknowledgements:
 =================
@@ -20,6 +19,7 @@
 ===========
 - This software is provided ``as is''. You are using it at your own risk.
   I will take no liability in any case.
+  Change three
 - This software package uses strong cryptography, so even if it is created,
   maintained and distributed from liberal countries in Europe (where it is
   legal to do this), it falls under certain export/import and/or use
EOF

      it "generates the expected diff object" do
        @diff_object = diff_to_object(diff)

        expected = {
          file: "/etc/postfix/TLS_LICENSE",
          additions: 3,
          deletions: 3,
          lines: [
            { type: "header", content: "@@ -1,15 +1,14 @@" },
            { type: "common", new_line_number: 1, original_line_number: 1, content: "Author:" },
            { type: "common", new_line_number: 2, original_line_number: 2, content: "=======" },
            { type: "common", new_line_number: 3, original_line_number: 3,
              content: "- Postfix/TLS support was originally developed by Lutz Jaenicke of" },
            { type: "deletion", original_line_number: 4,
              content: "  Brandenburg University of Technology, Cottbus, Germany." },
            { type: "addition", new_line_number: 4,
              content: "  Brandenburg University of Technology, Cottbus, Germany. Change one" },
            { type: "common", new_line_number: 5, original_line_number: 5, content: nil },
            { type: "common", new_line_number: 6, original_line_number: 6, content: "License:" },
            { type: "common", new_line_number: 7, original_line_number: 7, content: "========" },
            { type: "common", new_line_number: 8, original_line_number: 8,
              content: "- This software is free. You can do with it whatever you want." },
            { type: "common", new_line_number: 9, original_line_number: 9,
              content: "  I would however kindly ask you to acknowledge the use of this" },
            { type: "deletion", original_line_number: 10,
              content: "  package, if you are going use it in your software, which you might" },
            { type: "deletion", original_line_number: 11,
              content: "  be going to distribute. I would also like to receive a note if" },
            { type: "common", new_line_number: 10, original_line_number: 12,
              content: "  you are a satisfied user :-)" },
            { type: "addition", new_line_number: 11, content: "  Change two" },
            { type: "common", new_line_number: 12, original_line_number: 13, content: nil },
            { type: "common", new_line_number: 13, original_line_number: 14,
              content: "Acknowledgements:" },
            { type: "common", new_line_number: 14, original_line_number: 15,
              content: "=================" },
            { type: "header", content: "@@ -20,6 +19,7 @@" },
            { type: "common", new_line_number: 19, original_line_number: 20,
              content: "===========" },
            { type: "common", new_line_number: 20, original_line_number: 21,
              content: "- This software is provided ``as is&#39;&#39;. " \
                "You are using it at your own risk." },
            { type: "common", new_line_number: 21, original_line_number: 22,
              content: "  I will take no liability in any case." },
            { type: "addition", new_line_number: 22, content: "  Change three" },
            { type: "common", new_line_number: 23, original_line_number: 23,
              content: "- This software package uses strong cryptography, " \
                "so even if it is created," },
            { type: "common", new_line_number: 24, original_line_number: 24,
              content: "  maintained and distributed from liberal countries in Europe (where it " \
                "is" },
            { type: "common", new_line_number: 25, original_line_number: 25,
              content: "  legal to do this), it falls under certain export/import and/or use" }
          ]
        }

        expect(@diff_object.keys).to eq(expected.keys)
        expect(@diff_object[:file]).to eq(expected[:file])
        expect(@diff_object[:additions]).to eq(expected[:additions])
        expect(@diff_object[:deletions]).to eq(expected[:deletions])
        expect(@diff_object[:lines]).to eq(expected[:lines])
      end

      it "does not raise an error if the diff contains invalid UTF-8 characters" do
        utf8_diff = <<-EOF
  --- a/file
  +++ b/file
  @@ -1,15 +1,14 @@
  -utf8\255
  +utf8
EOF
        expect {
          diff_to_object(utf8_diff)
        }.to_not raise_error
      end
    end

    describe "#render_attribute" do
      let(:key) { "foo" }
      subject { render_attribute(key, value) }

      context "if hash contains a url" do
        let(:key) { "url" }
        let(:value) { "http://example.com/" }

        it {
          is_expected.to eq(
            "<a href='http://example.com/'>http://example.com/</a>"
          )
        }
      end

      context "if hash contains an array" do
        let(:value) { Machinery::Array.new(["a", "b"]) }

        it { is_expected.to eq("a, b") }
      end

      context "if hash contains anything else" do
        let(:value) { "string" }

        it { is_expected.to eq("string") }
      end
    end

    describe "#human_attribute" do
      let(:file) { UnmanagedFile.new(name: "/tmp/foo", size: 1234567) }

      it "renders file sizes properly" do
        expect(human_readable_attribute(file, "size")).to eq("1.2 MiB")
      end

      it "just returns normal attributes" do
        expect(human_readable_attribute(file, "name")).to eq("/tmp/foo")
      end
    end

    describe "#changed_elements" do
      before(:each) {
        files_comparison = Comparison.new
        files_comparison.changed = [
          [
            UnmanagedFile.new(name: "/tmp/foo", size: 1, type: "file"),
            UnmanagedFile.new(name: "/tmp/foo", size: 2, type: "file")
          ]
        ]
        dirs_comparison = Comparison.new
        dirs_comparison.changed = [
          [
            UnmanagedFile.new(name: "/tmp/foo/", files: 1, type: "dir"),
            UnmanagedFile.new(name: "/tmp/foo/", files: 2, type: "dir")
          ]
        ]
        other_comparison = Comparison.new
        other_comparison.changed = [
          [
            Machinery::Object.new(name: "/tmp/foo", foo: 1),
            Machinery::Object.new(name: "/tmp/foo", foo: 2)
          ]
        ]

        @diff = {
          "files" => files_comparison,
          "dirs"  => dirs_comparison,
          "other" => other_comparison,
        }
      }

      it "processes files" do
        changed_elements = changed_elements("files", key: "name")

        expect(changed_elements).to eq(
          [
            {
              id:       "/tmp/foo",
              change:   "(size: 1 B ↔ 2 B)",
              diffable: true
            }
          ]
        )
      end

      it "processes dirs" do
        changed_elements = changed_elements("dirs", key: "name")

        expect(changed_elements).to eq(
          [
            {
              id:       "/tmp/foo/",
              change:   "(files: 1 ↔ 2)",
              diffable: false
            }
          ]
        )
      end

      it "processes other objects" do
        changed_elements = changed_elements("other", key: "name")

        expect(changed_elements).to eq(
          [
            {
              id:       "/tmp/foo",
              change:   "(foo: 1 ↔ 2)",
              diffable: false
            }
          ]
        )
      end
    end
  end
end
