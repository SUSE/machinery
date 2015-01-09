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

require_relative "integration_spec_helper"

describe "match_machinery_show_scope matcher" do
  it "matches correct show output" do
    expected_output = <<-EOT
# Services [192.168.122.238] (2014-05-02 13:35:46)

  - arpd not active
  - autoyast not active
    EOT

    actual_output = <<-EOT
# Services [192.168.122.238] (2014-05-01 10:36:52)

  - arpd not active
  - autoyast not active
    EOT

    expect(actual_output).to match_machinery_show_scope(expected_output)
  end

  it "matches output with timestamps" do
    expected = <<-EOT
      # Changed configuration files [192.168.0.10] (2014-02-24 16:13:09)

      - /etc/crontab (md5)
        Diff:
        --- -	2014-05-28 11:42:50.785992953 +0200
        +++ /home/vagrant/.machinery/sles11sp3-build/config_files/etc/crontab	2014-05-28 11:42:12.520257287 +0200
        @@ -0,0 +1 @@
        +-*/15 * * * *   root  echo config_files_integration_test
    EOT
    actual = <<-EOT
      # Changed configuration files [192.168.0.10] (2014-02-24 16:13:09)

      - /etc/crontab (md5)
        Diff:
        --- -	2014-04-22 15:03:13.162341623 +0100
        +++ /home/vagrant/.machinery/sles11sp3-build/config_files/etc/crontab	2014-04-22 15:03:13.162341623 +0100
        @@ -0,0 +1 @@
        +-*/15 * * * *   root  echo config_files_integration_test
    EOT

    expect(actual).to match_machinery_show_scope(expected)
  end

  it "matches incorrect show output" do
    expected_output = <<-EOT
# Services [192.168.122.238] (2014-05-02 13:35:46)

  - arpd active in levels: B
  - autoyast not active
    EOT

    actual_output = <<-EOT
# Services [192.168.122.238] (2014-05-01 10:36:52)

  - arpd not active
  - autoyast not active
    EOT

    expect(actual_output).to_not match_machinery_show_scope(expected_output)
  end
end

describe "match_scope matcher" do
  describe "matches scope as array" do
    it "with equal content" do
      expected_description = create_test_description(json: <<-EOT)
      {
        "unmanaged_files": {
          "extracted": true,
          "files": [
            {
              "name": "/boot/backup_mbr",
              "user": "root"
            },
            {
              "name": "/boot/grub/default",
              "user": "root"
            }
          ]
        }
      }
      EOT

      actual_description = create_test_description(json: <<-EOT)
      {
        "unmanaged_files": {
          "extracted": true,
          "files": [
            {
              "name": "/boot/backup_mbr",
              "user": "root"
            },
            {
              "name": "/boot/grub/default",
              "user": "root"
            }
          ]
        },
        "groups": [
          {
            "name": "audio"
          }
        ]
      }
      EOT

      expect(actual_description).to match_scope(expected_description,
        "unmanaged_files")
    end

    it "with unequal content" do
      expected_description = create_test_description(json: <<-EOT)
      {
        "unmanaged_files": {
          "extracted": true,
          "files": [
            {
              "name": "/boot/backup_mbr",
              "user": "nobody"
            },
            {
              "name": "/boot/grub/default",
              "user": "root"
            }
          ]
        }
      }
      EOT

      actual_description = create_test_description(json: <<-EOT)
      {
        "unmanaged_files": {
          "extracted": true,
          "files": [
            {
              "name": "/boot/backup_mbr",
              "user": "root"
            },
            {
              "name": "/boot/grub/default",
              "user": "root"
            }
          ]
        },
        "groups": [
          {
            "name": "audio"
          }
        ]
      }
      EOT

      expect(actual_description).to_not match_scope(expected_description,
        "unmanaged_files")
    end

    it "with content of different length" do
      expected_description = create_test_description(json: <<-EOT)
      {
        "unmanaged_files": {
          "extracted": true,
          "files": [
            {
              "name": "/boot/backup_mbr"
            },
            {
              "name": "/boot/grub/default"
            }
          ]
        }
      }
      EOT

      actual_description = create_test_description(json: <<-EOT)
      {
        "unmanaged_files": {
          "extracted": true,
          "files": [
            {
              "name": "/boot/backup_mbr"
            }
          ]
        },
        "groups": [
          {
            "name": "audio"
          }
        ]
      }
      EOT

      expect(actual_description).to_not match_scope(expected_description,
        "unmanaged_files")
    end
  end

  describe "matches scope as hash" do
    it "with equal content" do
      expected_description = create_test_description(json: <<-EOT)
      {
        "os": {
          "name": "SUSE Linux Enterprise Server 11",
          "version": "11 SP3"
        }
      }
      EOT

      actual_description = create_test_description(json: <<-EOT)
      {
        "os": {
          "name": "SUSE Linux Enterprise Server 11",
          "version": "11 SP3"
        }
      }
      EOT

      expect(actual_description).to match_scope(expected_description, "os")
    end

    it "with unequal content" do
      expected_description = create_test_description(json: <<-EOT)
      {
        "os": {
          "name": "SUSE Linux Enterprise Server 11",
          "version": "11 SP2"
        }
      }
      EOT

      actual_description = create_test_description(json: <<-EOT)
      {
        "os": {
          "name": "SUSE Linux Enterprise Server 11",
          "version": "11 SP3"
        }
      }
      EOT

      expect(actual_description).to_not match_scope(expected_description, "os")
    end
  end
end

describe "include_file_scope matcher" do
  it "matches file scope with included subset of entries" do
    expected_description = create_test_description(json: <<-EOT)
    {
      "unmanaged_files": {
        "extracted": true,
        "files": [
          {
            "name": "/boot/grub/default",
            "user": "root"
          }
        ]
      }
    }
    EOT

    actual_description = create_test_description(json: <<-EOT)
    {
      "unmanaged_files": {
        "extracted": true,
        "files": [
          {
            "name": "/boot/backup_mbr",
            "user": "root"
          },
          {
            "name": "/boot/grub/default",
            "user": "root"
          }
        ]
      }
    }
    EOT

    expect(actual_description).to include_file_scope(expected_description,
      "unmanaged_files")
  end

  it "doesn't match scope with non-included subset of entries" do
    expected_description = create_test_description(json: <<-EOT)
    {
      "unmanaged_files": {
        "extracted": true,
        "files": [
          {
            "name": "/boot/backup_mbr",
            "user": "nobody"
          },
          {
            "name": "/boot/grub/default",
            "user": "root"
          }
        ]
      }
    }
    EOT

    actual_description = create_test_description(json: <<-EOT)
    {
      "unmanaged_files": {
        "extracted": true,
        "files": [
          {
            "name": "/boot/backup_mbr",
            "user": "root"
          },
          {
            "name": "/boot/grub/default",
            "user": "root"
          }
        ]
      }
    }
    EOT

    expect(actual_description).to_not include_file_scope(expected_description,
      "unmanaged_files")
  end
end
