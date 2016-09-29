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

describe Server do
  initialize_system_description_factory_store
  include Rack::Test::Methods

  let(:description_a) {
    create_test_description(
      name: "description_a",
      store_on_disk: true,
      extracted_scopes: ["changed_config_files"],
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
      extracted_scopes: ["changed_config_files"],
      scopes: ["os"]
    )

    file = description.changed_config_files.find { |f| f.name == "/etc/cron tab" }
    File.write(description.changed_config_files.file_path(file), "Other content")

    description
  }

  def app
    Server
  end

  before(:each) do
    Server.set :system_description_store, description_a.store
  end

  describe "show" do
    context "description with incompatible format version" do
      describe "GET /:id" do
        let(:old_format_version) {
          create_test_description(
            name: "old_format_version",
            store_on_disk: true,
            scopes: ["os"],
            format_version: 7
          )
        }
        let(:unknown_format_version) {
          create_test_description(
            name: "unknown_format_version",
            store_on_disk: true,
            scopes: ["os"],
            format_version: 12
          )
        }

        it "returns update instructions for lower format versions" do
          get "/#{old_format_version.name}"
          expect(last_response).to be_ok
          expect(last_response.body).
            to include("System Description incompatible!")
        end

        it "returns update instructions for higher format versions" do
          get "/#{unknown_format_version.name}"
          expect(last_response).to be_ok
          expect(last_response.body).
            to include("System Description incompatible!")
        end
      end
    end

    context "compatible format version" do
      describe "GET /:id" do
        it "returns the page" do
          get "/#{description_a.name}"
          expect(last_response).to be_ok
          expect(last_response.body).
            to include("#{description_a.name} - Machinery System Description")
        end
      end
    end

    describe "GET /:id with non-existent id" do
      it "redirects to landing page if description is not found" do
        bad_description = "does_not_exist"

        get "/#{bad_description}"

        expect(last_response).to be_redirect

        follow_redirect!

        expect(last_response.body).
          to include("Couldn't find a system description with the name '#{bad_description}'")
      end
    end

    describe "GET /descriptions/:id/files/:scope" do
      it "sends the file" do
        get "/descriptions/#{description_a.name}/files/changed_config_files/etc/cron%20tab"

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
        get "/compare/#{description_a.name}/#{description_c.name}/files/changed_config_files/etc/cron%20tab"

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

  describe "list" do
    context "good descriptions" do
      describe "GET /" do
        it "returns the page" do
          get "/"

          expect(last_response).to be_ok
          expect(last_response.body).
            to include("System Descriptions")
        end
      end
    end

    context "bad description" do
      before(:each) do
        store_raw_description("abc", <<-EOT
            {
              x
            }
          EOT
        )
      end

      describe "GET /" do
        it "returns the page" do
          get "/"

          expect(last_response).to be_ok
          expect(last_response.body).to include("System Descriptions")
        end
      end
    end

    context "broken description" do
      before(:each) do
        store_raw_description(
          "foo", <<-EOT
            {
              "unmanaged_files": {
                  "_attributes": {
                      "has_metadata": false,
                      "foo": true
                  }
              }
            }
          EOT
        )
      end

      describe "GET /" do
        it "shows a 'description is broken' error message" do
          get "/"

          expect(last_response).to be_ok
          expect(last_response.body).to include("This description is broken.")
        end
      end

      describe "GET /:id" do
        it "returns error message view" do
          get "/foo"
          expect(last_response).to be_ok
          expect(last_response.body).to include("System Description broken!")
        end
      end
    end
  end

  describe Server::Helpers do
    include Server::Helpers

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
        files_comparison.common = UnmanagedFilesScope.new([], extracted: true)
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
