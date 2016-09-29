# frozen_string_literal: true
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

describe DiffWidget do
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

  describe "#widget" do
    it "generates the expected diff object" do
      diff_object = DiffWidget.new(diff).widget

      expected = {
        file: "/etc/postfix/TLS_LICENSE",
        additions: 3,
        deletions: 3,
        lines: [
          {
            type: "header",
            content: "@@ -1,15 +1,14 @@"
          },
          {
            type: "common",
            new_line_number: 1,
            original_line_number: 1,
            content: "Author:"
          },
          {
            type: "common",
            new_line_number: 2,
            original_line_number: 2,
            content: "======="
          },
          {
            type: "common",
            new_line_number: 3,
            original_line_number: 3,
            content: "- Postfix/TLS support was originally developed by Lutz Jaenicke of"
          },
          {
            type: "deletion",
            original_line_number: 4,
            content: "  Brandenburg University of Technology, Cottbus, Germany."
          },
          {
            type: "addition",
            new_line_number: 4,
            content: "  Brandenburg University of Technology, Cottbus, Germany. Change one"
          },
          {
            type: "common",
            new_line_number: 5,
            original_line_number: 5,
            content: nil
          },
          {
            type: "common",
            new_line_number: 6,
            original_line_number: 6,
            content: "License:"
          },
          {
            type: "common",
            new_line_number: 7,
            original_line_number: 7,
            content: "========"
          },
          {
            type: "common",
            new_line_number: 8,
            original_line_number: 8,
            content: "- This software is free. You can do with it whatever you want."
          },
          {
            type: "common",
            new_line_number: 9,
            original_line_number: 9,
            content: "  I would however kindly ask you to acknowledge the use of this"
          },
          {
            type: "deletion",
            original_line_number: 10,
            content: "  package, if you are going use it in your software, which you might"
          },
          {
            type: "deletion",
            original_line_number: 11,
            content: "  be going to distribute. I would also like to receive a note if"
          },
          {
            type: "common",
            new_line_number: 10,
            original_line_number: 12,
            content: "  you are a satisfied user :-)"
          },
          {
            type: "addition",
            new_line_number: 11,
            content: "  Change two"
          },
          {
            type: "common",
            new_line_number: 12,
            original_line_number: 13,
            content: nil
          },
          {
            type: "common",
            new_line_number: 13,
            original_line_number: 14,
            content: "Acknowledgements:"
          },
          {
            type: "common",
            new_line_number: 14,
            original_line_number: 15,
            content: "================="
          },
          {
            type: "header",
            content: "@@ -20,6 +19,7 @@"
          },
          {
            type: "common",
            new_line_number: 19,
            original_line_number: 20,
            content: "==========="
          },
          {
            type: "common",
            new_line_number: 20,
            original_line_number: 21,
            content: "- This software is provided ``as is&#39;&#39;. " \
              "You are using it at your own risk."
          },
          {
            type: "common",
            new_line_number: 21,
            original_line_number: 22,
            content: "  I will take no liability in any case."
          },
          {
            type: "addition",
            new_line_number: 22,
            content: "  Change three"
          },
          {
            type: "common",
            new_line_number: 23,
            original_line_number: 23,
            content: "- This software package uses strong cryptography, " \
              "so even if it is created,"
          },
          {
            type: "common",
            new_line_number: 24,
            original_line_number: 24,
            content: "  maintained and distributed from liberal countries in Europe (where it " \
              "is"
          },
          {
            type: "common",
            new_line_number: 25,
            original_line_number: 25,
            content: "  legal to do this), it falls under certain export/import and/or use"
          }
        ]
      }

      expect(diff_object.keys).to eq(expected.keys)
      expect(diff_object[:file]).to eq(expected[:file])
      expect(diff_object[:additions]).to eq(expected[:additions])
      expect(diff_object[:deletions]).to eq(expected[:deletions])
      expect(diff_object[:lines]).to eq(expected[:lines])
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
        DiffWidget.new(utf8_diff).widget
      }.to_not raise_error
    end
  end
end
