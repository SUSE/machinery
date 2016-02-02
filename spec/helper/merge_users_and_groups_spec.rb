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

require_relative "../unit/spec_helper"

describe "merge_users_and_groups.pl" do
  let(:template) {
    ERB.new(
      File.read(File.join(Machinery::ROOT, "export_helpers", "merge_users_and_groups.pl.erb"))
    )
  }

  before(:each) {
    @passwd_tempfile = Tempfile.new("passwd")
    @passwd_path = @passwd_tempfile.path
    @shadow_tempfile = Tempfile.new("shadow")
    @shadow_path = @shadow_tempfile.path
    @group_tempfile = Tempfile.new("group")
    @group_path = @group_tempfile.path
  }

  after(:each) {
    @passwd_tempfile.unlink
    @shadow_tempfile.unlink
    @group_tempfile.unlink
  }

  def run_helper(passwd_entries, group_entries)
    script = Tempfile.new("merge_users_and_groups.pl")
    script.write(template.result(binding))
    script.close
    FileUtils.touch(@passwd_path)
    FileUtils.touch(@shadow_path)

    Cheetah.run("perl", script.path, @passwd_path, @shadow_path, @group_path, stdout: :capture)
  end

  it "adds new entries" do
    entries = <<-EOF
      ["svn:x:482:476:user for Apache Subversion svnserve:/srv/svn:/sbin/nologin", "svn:!:16058::::::"],
      ["nscd:x:484:478:User for nscd:/var/run/nscd:/sbin/nologin", "nscd:!:16058::::::"]
    EOF
    expected_passwd = <<EOF
svn:x:482:476:user for Apache Subversion svnserve:/srv/svn:/sbin/nologin
nscd:x:484:478:User for nscd:/var/run/nscd:/sbin/nologin
EOF
    expected_shadow = <<EOF
svn:!:16058::::::
nscd:!:16058::::::
EOF

    run_helper(entries, "")

    expect(File.read(@passwd_path)).to eq(expected_passwd)
    expect(File.read(@shadow_path)).to eq(expected_shadow)
  end

  it "preserves attributes on conflicting entries" do
    existing_passwd = <<-EOF
svn:x:482:476:user for Apache:/srv/svn:/sbin/nologin
nscd:x:484:478:User for nscd:/var/run/nscd:/sbin/nologin
EOF
    existing_shadow = <<-EOF
svn:!:16058::::::
nscd:!:16058::::::
EOF
    expected_passwd = <<-EOF
svn:x:482:456:user for Subversion:/srv/svn_new:/bin/bash
nscd:x:484:012:nscd user:/var/run/nscd_new:/bin/bash
EOF
    expected_shadow = <<-EOF
svn:!:1112:1:2:3:4:5:
nscd:!:2223:5:4:3:2:1:
EOF
    entries = <<-EOF
      ["svn:x:123:456:user for Subversion:/srv/svn_new:/bin/bash", "svn:!:1112:1:2:3:4:5:"],
      ["nscd:x:789:012:nscd user:/var/run/nscd_new:/bin/bash", "nscd:!:2223:5:4:3:2:1:"]
    EOF

    File.write(@passwd_path, existing_passwd)
    File.write(@shadow_path, existing_shadow)

    run_helper(entries, "")

    expect(File.read(@passwd_path)).to eq(expected_passwd)
    expect(File.read(@shadow_path)).to eq(expected_shadow)
  end

  it "does not reuse already existing uids and gids" do
    existing_passwd = <<-EOF
svn:x:1:1:user for Apache Subversion svnserve:/srv/svn:/sbin/nologin
nscd:x:2:2:User for nscd:/var/run/nscd:/sbin/nologin
    EOF
    expected_passwd = <<-EOF
svn:x:1:1:user for Apache Subversion svnserve:/srv/svn:/sbin/nologin
nscd:x:2:2:User for nscd:/var/run/nscd:/sbin/nologin
nobody:x:3:13:nobody:/var/lib/nobody:/bin/bash
news:x:4:14:News system:/etc/news:/bin/bash
    EOF
    entries = <<-EOF
      ["nobody:x:1:13:nobody:/var/lib/nobody:/bin/bash"],
      ["news:x:2:14:News system:/etc/news:/bin/bash"]
    EOF

    File.write(@passwd_path, existing_passwd)

    run_helper(entries, "")

    expect(File.read(@passwd_path)).to eq(expected_passwd)
  end

  it "writes groups" do
    group_entries = <<-EOF
      "users:x:100:",
      "uucp:x:14:"
    EOF

    expected_groups = <<EOF
users:x:100:
uucp:x:14:
EOF

    run_helper("", group_entries)

    expect(File.read(@group_path)).to eq(expected_groups)
  end

  it "skips existing groups" do
    group_entries = <<-EOF
      "users:x:100:",
      "uucp:x:14:"
    EOF
    existing_groups = <<EOF
users:x:90:
EOF
    expected_groups = <<EOF
users:x:90:
uucp:x:14:
EOF

    File.write(@group_path, existing_groups)
    run_helper("", group_entries)

    expect(File.read(@group_path)).to eq(expected_groups)
  end

  it "does not reuse already existing gids" do
    existing_group = <<-EOF
users:x:100:
uucp:x:101:
    EOF
    expected_group = <<-EOF
users:x:100:
uucp:x:101:
ntp:x:102:
at:x:103:
    EOF

    entries = <<-EOF
      "ntp:x:100:",
      "at:x:101:"
    EOF

    File.write(@group_path, existing_group)
    run_helper("", entries)

    expect(File.read(@group_path)).to eq(expected_group)
  end

  it "keeps passwd and group in sync when adjusting ids" do
    existing_passwd = <<-EOF
a:x:1:1:existing user a:/home/a:/bin/bash
b:x:2:2:existing user b:/home/b:/bin/bash
c:x:3:100:existing user c:/home/b:/bin/bash
EOF
    existing_group = <<-EOF
a:x:1:
b:x:2:
users:x:100:
common_group_with_different_id:x:200:
common_group_with_different_id2:x:201:
EOF
    entries = <<-EOF
      ["x:x:50:100:new user x:/home/x:/bin/bash"],
      ["y:x:51:201:new user y:/home/y:/bin/bash"],
      ["z:x:52:200:new user z:/home/z:/bin/bash"],
    EOF
    group_entries = <<-EOF
      "users_conflict:x:100:",
      "common_group_with_different_id:x:201:",
      "common_group_with_different_id2:x:200:"
    EOF
    expected_passwd = <<-EOF
a:x:1:1:existing user a:/home/a:/bin/bash
b:x:2:2:existing user b:/home/b:/bin/bash
c:x:3:100:existing user c:/home/b:/bin/bash
x:x:50:101:new user x:/home/x:/bin/bash
y:x:51:200:new user y:/home/y:/bin/bash
z:x:52:201:new user z:/home/z:/bin/bash
    EOF
    expected_group = <<-EOF
a:x:1:
b:x:2:
users:x:100:
common_group_with_different_id:x:200:
common_group_with_different_id2:x:201:
users_conflict:x:101:
    EOF

    File.write(@passwd_path, existing_passwd)
    File.write(@group_path, existing_group)
    run_helper(entries, group_entries)

    expect(File.read(@passwd_path)).to eq(expected_passwd)
    expect(File.read(@group_path)).to eq(expected_group)
  end

  it "merges the user lists of group users" do
    existing_group = <<-EOF
users:x:100:foo,both
    EOF
    expected_group = <<-EOF
users:!:100:bar,both,foo
    EOF

    entries = <<-EOF
      "users:!:200:bar,both",
    EOF
    File.write(@group_path, existing_group)

    run_helper("", entries)
    expect(File.read(@group_path)).to eq(expected_group)
  end
end
