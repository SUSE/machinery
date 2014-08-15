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

require_relative "spec_helper"

describe UnmanagedFilesInspector do
  describe ".inspect" do
    include FakeFS::SpecHelpers

    subject { UnmanagedFilesInspector.new }
    let(:test_file_path) { "spec/data/unmanaged_files" }

    let(:expected_data) {
      UnmanagedFilesScope.new([
        UnmanagedFile.new( name: "/etc/etc_mydir/", type: "dir" ),
        UnmanagedFile.new( name: "/etc/etc_myfile", type: "file" ),
        UnmanagedFile.new( name: "/mydir/", type: "dir" ),
        UnmanagedFile.new( name: "/myfile", type: "file" ),
        UnmanagedFile.new( name: "/myfile_setgid", type: "file" ),
        UnmanagedFile.new( name: "/myfile_setgid_x", type: "file" ),
        UnmanagedFile.new( name: "/myfile_setuid", type: "file" ),
        UnmanagedFile.new( name: "/myfile_setuid_x", type: "file" ),
        UnmanagedFile.new( name: "/myfile_sticky", type: "file" ),
        UnmanagedFile.new( name: "/myfile_sticky_x", type: "file" ),
        UnmanagedFile.new( name: "/my link", type: "link" ),
        UnmanagedFile.new( name: "/other_dir/", type: "dir" ),
        UnmanagedFile.new( name: "/usr/X11R6/x11_mydir/", type: "dir" ),
        UnmanagedFile.new( name: "/usr/X11R6/x11_myfile", type: "file" )
      ])
    }

    let(:expected_data_meta) {
      new = [
        { name: "/etc/etc_mydir/",
          size: 18806, mode: "755", user: "root", group: "lp", files: 16 },
        { name: "/etc/etc_myfile",
          size: 10, mode: "644", user: "emil", group: "users" },
        { name: "/mydir/",
          size: 6204, mode: "755", user: "root", group: "root", files: 17 },
        { name: "/myfile",
          size: 1, mode: "644", user: "root", group: "root" },
        { name: "/myfile_setgid",
          size: 5, mode: "2660", user: "hans", group: "users" },
        { name: "/myfile_setgid_x",
          size: 5, mode: "2670", user: "news", group: "news" },
        { name: "/myfile_setuid",
          size: 5, mode: "4400", user: "anna", group: "users" },
        { name: "/myfile_setuid_x",
          size: 5, mode: "4500", user: "emil", group: "users" },
        { name: "/myfile_sticky",
          size: 5, mode: "1660", user: "fritz", group: "users" },
        { name: "/myfile_sticky_x",
          size: 5, mode: "1661", user: "emil", group: "users" },
        { name: "/my link",
          user: "root", group: "root" },
        { name: "/other_dir/",
          size: 0, mode: "755", user: "root", group: "root", files: 1 },
        { name: "/usr/X11R6/x11_mydir/",
          size: 1000000, mode: "755", user: "root", group: "root", files: 13  },
        { name: "/usr/X11R6/x11_myfile",
          size: 1024, mode: "644", user: "emil", group: "users" },
      ]
      files = expected_data.map do |os|
        idx = new.find_index{ |h| h[:name] == os.name }
        os = UnmanagedFile.new(os.attributes.merge(new[idx])) if idx
      end
      UnmanagedFilesScope.new(files)
    }

    let(:description) {
      SystemDescription.new("systemname", {}, SystemDescriptionStore.new)
    }

    before(:each) do
      FakeFS::FileSystem.clone(test_file_path,test_file_path)
      description.store.save(description)
    end


    def expect_requirements(system)
      expect(system).to receive(:check_requirement).with(
        "rpm", "--version"
      )
      expect(system).to receive(:check_requirement).with(
        "sed", "--version"
      )
      expect(system).to receive(:check_requirement).with(
        "cat", "--version"
      )
      expect(system).to receive(:check_requirement).with(
        "find", "--version"
      )
    end

    def expect_rpm_qa(system)
      expect(system).to receive(:run_command).with(
        [ "rpm", "-qlav" ],
	[ "sed", "s/^\\(.\\)[^/]* /\\1 /" ],
        :stdout => :capture
      ).and_return(File.read(test_file_path+"/rpm_qlav"))
    end

    def expect_cat_mounts(system)
      expect(system).to receive(:run_command).with(
        "cat", "/proc/mounts",
        :stdout => :capture
      ).and_return("/dev/sda1 / ext4 rw,relatime,data=ordered 0 0")
    end

    def expect_find_commands(system,add_files)
      dirs = [
        "/",
        "/etc/ppp/ip 'down.d",
        "/etc/ppp/ip-up.d",
        "/etc/skel/.config",
        "/etc/skel/.fonts",
        "/etc/skel/.local",
        "/etc/skel/bin",
        "/etc/susehelp.d/htdig",
        "/etc/sysconfig/SuSEfirewall2.d",
        "/etc/sysconfig/network",
        "/etc/sysconfig/scripts",
        "/etc/xdg/autostart",
        "/lib/systemd/system",
        "/srv/www/cgi-bin",
        "/srv/www/htdocs",
        "/usr/X11R6/bin",
        "/usr/X11R6/lib",
        "/usr/i586-suse-linux/bin",
        "/usr/i586-suse-linux/include",
        "/usr/i586-suse-linux/lib",
        "/usr/include/X11",
        "/usr/lib/X11",
        "/usr/lib/browser-plugins",
        "/usr/lib/lsb",
        "/usr/lib/news",
        "/usr/lib/pkgconfig",
        "/usr/lib/restricted",
        "/usr/lib/sysctl.d",
        "/usr/lib/systemd",
        "/usr/local/bin",
        "/usr/local/games",
        "/usr/local/include",
        "/usr/local/lib",
        "/usr/local/man",
        "/usr/local/sbin",
        "/usr/local/share",
        "/usr/local/src",
        "/usr/share/applications",
        "/usr/share/dict",
        "/usr/share/doc",
        "/usr/share/fonts",
        "/usr/share/games",
        "/usr/share/help",
        "/usr/share/icons",
        "/usr/share/info",
        "/usr/share/java",
        "/usr/share/locale",
        "/usr/share/man",
        "/usr/share/mime",
        "/usr/share/misc",
        "/usr/share/nls",
        "/usr/share/omc",
        "/usr/share/pixmaps",
        "/usr/share/pkgconfig",
        "/usr/share/sgml",
        "/usr/share/sounds",
        "/usr/share/themes",
        "/usr/share/tmac",
        "/usr/share/xml",
        "/usr/share/xsessions",
        "/usr/src/packages",
        "/var/adm/backup",
        "/var/adm/fillup-templates",
        "/var/adm/perl-modules",
        "/var/adm/update-messages",
        "/var/adm/update-scripts",
        "/var/cache/man",
        "/var/lib/empty",
        "/var/lib/misc",
        "/var/lib/news",
        "/var/lib/nobody",
        "/var/lib/pam_devperm",
        "/var/lib/wwwrun",
        "/var/spool/clientmqueue",
        "/var/spool/lpd",
        "/var/spool/mail",
        "/var/spool/uucp",
        "/usr/lib/coreutils"
      ]

      non_empty_dirs = {
        "/" => "root",
        "/etc/sysconfig/SuSEfirewall2.d" => "firewall",
        "/etc/sysconfig/network"         => "network",
        "/usr/lib/restricted"            => "restricted",
        "/usr/lib/systemd"               => "systemd",
        "/usr/local/man"                 => "lman",
        "/usr/share/doc"                 => "doc",
        "/usr/share/help"                => "help",
        "/usr/share/locale"              => "locale",
        "/usr/share/man"                 => "sman",
        "/usr/share/mime"                => "mime",
        "/usr/share/omc"                 => "omc",
        "/usr/share/sgml"                => "sgml",
        "/usr/share/xml"                 => "xml",
        "/var/adm/backup"                => "backup",
        "/var/spool/uucp"                => "uucp",
        "/usr/lib/coreutils"             => "libcore",
        "/usr/share/info"                => "sinfo"
      }
      dirs.each do |d|
        cmd = "find #{d.shellescape} -xdev -maxdepth 1 -maxdepth 3 -printf \"%y\\0%P\\0%l\\0\""

        # non_empty_dirs maps dirs to extension names where content of dir is stored
        # files with test content is saved in find_#{ext}
        ext = non_empty_dirs[d]
        ret = ""
        if ext
          file_path = test_file_path + "/find_#{ext}"
          ret = File.read(file_path).tr("\n","\0")
          file_path += ".add"
          if add_files && File.exists?(file_path)
            ret += File.read(file_path).tr("\n","\0")
          end
        end
        expect(system).to receive(:run_command).with(
          "/bin/bash",
          { :stdin => cmd, :stdout => :capture, :disable_logging => true }
        ).and_return(ret)
      end
    end

    def expect_inspect_unmanaged(system,add_files,extract)
      allow_any_instance_of(UnmanagedFilesInspector).to receive(:max_depth).and_return(3)
      allow_any_instance_of(UnmanagedFilesInspector).to receive(:start_depth).and_return(3)
      expect_requirements(system)
      if(extract)
        expect(system).to receive(:check_requirement).with(
          "tar", "--version"
        )
        expect(system).to receive(:check_requirement).with(
          "gzip", "--version"
        )
      end
      expect_rpm_qa(system)
      expect_cat_mounts(system)
      expect_find_commands(system,add_files)
      if(extract)
        description.initialize_file_store("unmanaged_files")
        cfdir = description.file_store("unmanaged_files")
        dlist = expected_data.select{ |s| s.type=="dir" }
        dlist.map!{ |s| s.name[0..-2] }
        expect(system).to receive(:create_archive)
        dlist.each do |dir|
          last_dir = File.basename(dir)
          base_dir = File.dirname(dir)
          base_dir = "" if base_dir=="/"
          expect(system).to receive(:create_archive).with(
            dir,
            File.join(cfdir, "trees", base_dir, "#{last_dir}.tgz"),
            []
          )
        end
        arch = File.join(cfdir, "files.tgz")
        expect(Cheetah).to receive(:run).with(
          "tar", "tvf", arch,
          :stdout => :capture
        ).and_return(File.read(test_file_path+"/tar_tvfz_FILES"))
        dlist.each do |d|
          base = File.dirname(d)
          base = "" if base == "/"
          test_file = test_file_path + "/tar_tvfz_" + File.basename(d)
          expect(Cheetah).to receive(:run).with(
            "tar", "tvf",
            File.join(cfdir, "trees", base, File.basename(d) + ".tgz"),
            :stdout => :capture
          ).and_return(File.read(test_file))
        end
      end
    end

    it "returns empty when no unmanaged files are there" do
      system = double
      expect_inspect_unmanaged(system, false, false)

      summary = subject.inspect(system, description)

      expect(description["unmanaged_files"]).to eq(UnmanagedFilesScope.new)
      expect(summary).to include("Found 0 unmanaged files and trees")
    end

    it "returns data about unmanaged files when requirements are fulfilled" do
      system = double

      expect_inspect_unmanaged(system, true, false)

      summary = subject.inspect(system, description)

      expect(description["unmanaged_files"]).to match_array(expected_data)
      expect(summary).to include("Found #{expected_data.size} unmanaged files and trees")
    end

    it "returns sorted data" do
      system = double

      expect_inspect_unmanaged(system, true, false)

      subject.inspect(system, description)
      names = description["unmanaged_files"].map(&:name)

      expect(names).to eq(names.sort)
    end

    it "raise an error when requirements are not fulfilled" do
      system = double
      expect(system).to receive(:check_requirement).with(
        "rpm", "--version"
      ).and_raise(Machinery::Errors::MissingRequirement)

      expect{subject.inspect(system, description)}.to raise_error(
        Machinery::Errors::MissingRequirement)
    end

    it "extracts unmanaged files" do
      system = double
      expect_inspect_unmanaged(system, true, true)

      summary = subject.inspect(
        system, description,
        :extract_unmanaged_files => true
      )

      expect(description["unmanaged_files"]).to match_array(expected_data_meta)
      expect(summary).to include("Extracted #{expected_data.size} unmanaged files and trees")
      cfdir = description.file_store("unmanaged_files")
      expect(File.stat(cfdir).mode.to_s(8)[-3..-1]).to eq("700")
    end
  end

  describe "#get_find_data" do
    it "does not choke on filenames with invalid UTF-8 characters and filters them" do
      system = double
      expect(system).to receive(:run_command).and_return(
        "f\0good_filename\0\0" \
        "f\0broken\255filename\0\0"
      )
      expect(Machinery::Ui).to receive(:warn)

      result = nil
      expect {
        result = subject.get_find_data(system, "/etc", 1)
      }.to_not raise_error

      expect(result).to eq([{"good_filename" => ""}, {},
        ["broken\255filename".force_encoding("binary")]])
    end

    it "reports both link and target if both is broken" do
      system = double
      expect(system).to receive(:run_command).and_return(
        "f\0broken\255Link\0broken\255target\0"
      )
      expect(Machinery::Ui).to receive(:warn).with(/broken\uFFFDLink.*broken\uFFFDtarget/)

      result = subject.get_find_data(system, "/etc", 1)
      expect(result).to eq([
        {},
        {},
        [
          "broken\255Link".force_encoding("binary"),
          "broken\255target".force_encoding("binary")
        ]
      ])
    end
  end
end
