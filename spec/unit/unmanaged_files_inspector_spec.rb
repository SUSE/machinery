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

describe UnmanagedFilesInspector do
  capture_machinery_output

  let(:system) { double(arch: "x86_64") }
  let(:description) {
    SystemDescription.new("systemname", SystemDescriptionStore.new)
  }
  subject { UnmanagedFilesInspector.new(system, description) }

  before(:each) do
    allow_any_instance_of(MachineryHelper).to receive(:can_help?).
      and_return(false)
  end

  describe ".inspect" do
    include FakeFS::SpecHelpers

    let(:test_file_path) { "spec/data/unmanaged_files" }
    let(:default_filter) {
      Filter.from_default_definition("inspect")
    }

    let(:expected_data) {
      UnmanagedFilesScope.new(
        extracted: false,
        files: UnmanagedFileList.new([
          UnmanagedFile.new( name: "/etc/etc_mydir/", type: "dir" ),
          UnmanagedFile.new( name: "/etc/etc_myfile", type: "file" ),
          UnmanagedFile.new( name: "/homes/tux/", type: "remote_dir" ),
          UnmanagedFile.new( name: "/my link", type: "link" ),
          UnmanagedFile.new( name: "/mydir/", type: "dir" ),
          UnmanagedFile.new( name: "/myfile", type: "file" ),
          UnmanagedFile.new( name: "/myfile_setgid", type: "file" ),
          UnmanagedFile.new( name: "/myfile_setgid_x", type: "file" ),
          UnmanagedFile.new( name: "/myfile_setuid", type: "file" ),
          UnmanagedFile.new( name: "/myfile_setuid_x", type: "file" ),
          UnmanagedFile.new( name: "/myfile_sticky", type: "file" ),
          UnmanagedFile.new( name: "/myfile_sticky_x", type: "file" ),
          UnmanagedFile.new( name: "/other_dir/", type: "dir" ),
          UnmanagedFile.new( name: "/usr/X11R6/x11_mydir/", type: "dir" ),
          UnmanagedFile.new( name: "/usr/X11R6/x11_myfile", type: "file" )
        ])
      )
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
          size: 1024, mode: "6644", user: "emil", group: "users" },
        { name: "/homes/tux/" },
      ]
      files = expected_data.files.map do |os|
        idx = new.find_index{ |h| h[:name] == os.name }
        os = UnmanagedFile.new(os.attributes.merge(new[idx])) if idx
      end
      UnmanagedFilesScope.new(
        extracted: true,
        files: UnmanagedFileList.new(files)
      )
    }

    before(:each) do
      allow(JsonValidator).to receive(:new).and_return(double(validate: []))
      FakeFS::FileSystem.clone(test_file_path,test_file_path)
      FakeFS::FileSystem.clone("inspect_helpers/")
      FakeFS::FileSystem.clone("filters/")
      description.save
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
        stdout: :capture
      ).and_return(File.read(test_file_path+"/rpm_qlav"))
    end

    def expect_cat_mounts(system, add_files)
      ret_val="/dev/sda1 / ext4 rw,relatime,data=ordered 0 0"
      ret_val+="\nhost:/real-homes/tux /homes/tux nfs4 rw,relatime,vers=4.0 0 0" if add_files

      expect(system).to receive(:read_file).and_return(ret_val)
    end

    def expect_find_commands(system,add_files, filtered_paths)
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
        "/usr/lib/coreutils",
        "/opt"
      ]
      if filtered_paths
        dirs.delete_if { |d| filtered_paths.any? { |f| d.start_with?(f) } }
      end

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
          "find", d, "-xdev", "-maxdepth", "1", "-maxdepth", "3", "-printf", "%y\\0%P\\0%l\\0",
          stdout: :capture, disable_logging: true, privileged: true
        ).and_return(ret)
      end
    end

    def expect_inspect_unmanaged(system, add_files, extract, filtered_paths = nil)
      allow_any_instance_of(UnmanagedFilesInspector).to receive(:max_depth).and_return(3)
      allow_any_instance_of(UnmanagedFilesInspector).to receive(:start_depth).and_return(3)
      expect_requirements(system)

      allow_any_instance_of(UnmanagedFilesInspector).to receive(:btrfs_subvolumes).
        and_return(["opt"])

      if(extract)
        expect(system).to receive(:check_create_archive_dependencies)
      end
      expect_rpm_qa(system)
      expect_cat_mounts(system, add_files)
      expect_find_commands(system, add_files, filtered_paths)
      if(extract)
        file_store = description.scope_file_store("unmanaged_files.tmp")
        file_store.create
        cfdir = file_store.path
        dlist = expected_data.files.select{ |s| s.type=="dir" }
        dlist.map!{ |s| s.name[0..-2] }
        expect(system).to receive(:create_archive)

        dlist.each do |dir|
          last_dir = File.basename(dir)
          base_dir = File.dirname(dir)
          base_dir = "" if base_dir=="/"
          expect(system).to receive(:create_archive).with(
            dir,
            File.join(cfdir, "trees", base_dir, "#{last_dir}.tgz"),
            ["/homes/tux"]
          )
        end
        arch = File.join(cfdir, "files.tgz")
        expect(Cheetah).to receive(:run).with(
          "tar", "tvf", arch, "--quoting-style=literal",
          stdout: :capture
        ).and_return(File.read(test_file_path+"/tar_tvfz_FILES"))
        dlist.each do |d|
          base = File.dirname(d)
          base = "" if base == "/"
          test_file = test_file_path + "/tar_tvfz_" + File.basename(d)
          expect(Cheetah).to receive(:run).with(
            "tar", "tvf",
            File.join(cfdir, "trees", base, File.basename(d) + ".tgz"),
            "--quoting-style=literal", stdout: :capture
          ).and_return(File.read(test_file))
        end
      end
    end

    it "returns empty when no unmanaged files are there" do
      expect_inspect_unmanaged(system, false, false)

      subject.inspect(default_filter)

      expected = UnmanagedFilesScope.new(
        extracted: false,
        files: UnmanagedFileList.new
      )
      expect(description["unmanaged_files"]).to eq(expected)
      expect(subject.summary).to include("Found 0 unmanaged files and trees")
    end

    it "returns data about unmanaged files when requirements are fulfilled" do
      expect_inspect_unmanaged(system, true, false)

      subject.inspect(default_filter)

      expect(description["unmanaged_files"]).to eq(expected_data)
      expect(subject.summary).
        to include("Found #{expected_data.files.size} unmanaged files and trees")
    end

    it "returns sorted data" do
      expect_inspect_unmanaged(system, true, false)

      subject.inspect(default_filter)
      names = description["unmanaged_files"].files.map(&:name)

      expect(names).to eq(names.sort)
    end

    it "adheres to simple filters" do
      expect_inspect_unmanaged(system, true, false, ["/usr/local"])

      default_filter.add_element_filter_from_definition("/unmanaged_files/files/name=/usr/local/*")
      subject.inspect(default_filter)
      names = description["unmanaged_files"].files.map(&:name)

      expect(names).to eq(names.sort)
    end

    it "adheres to more complex filters" do
      expect_inspect_unmanaged(system, true, false, ["/usr/local", "/etc/skel/.config"])

      default_filter.add_element_filter_from_definition("/unmanaged_files/files/name=/usr/local/")
      default_filter.add_element_filter_from_definition(
        "/unmanaged_files/files/name=/etc/skel/.config")
      subject.inspect(default_filter)
      names = description["unmanaged_files"].files.map(&:name)

      expect(names).to eq(names.sort)
    end

    it "raise an error when requirements are not fulfilled" do
      expect(system).to receive(:check_requirement).with(
        "rpm", "--version"
      ).and_raise(Machinery::Errors::MissingRequirement)

      expect { subject.inspect(default_filter) }.to raise_error(
        Machinery::Errors::MissingRequirement)
    end

    it "extracts unmanaged files" do
      expect_inspect_unmanaged(system, true, true)

      subject.inspect(default_filter, extract_unmanaged_files: true)

      expect(description["unmanaged_files"]).to eq(expected_data_meta)
      expect(subject.summary).
        to include("Extracted #{expected_data.files.size} unmanaged files and trees")
      cfdir = description.scope_file_store("unmanaged_files").path
      expect(File.stat(cfdir).mode.to_s(8)[-3..-1]).to eq("700")
    end

    it "returns schema compliant data" do
      expect_inspect_unmanaged(system, true, true)
      subject.inspect(default_filter, extract_unmanaged_files: true)

      json_hash = JSON.parse(description.to_json)
      expect {
        JsonValidator.new(json_hash).validate
      }.to_not raise_error
    end

    it "handles interrupts when extracting files" do
      expect_inspect_unmanaged(system, true, true)
      expect_any_instance_of(ScopeFileStore).to receive(:rename).
        and_raise(SignalException.new("SIGTERM"))
      expect {
        subject.inspect(default_filter, extract_unmanaged_files: true)
      }.to raise_error(SignalException)
    end
  end

  describe "#get_find_data" do
    it "does not choke on filenames with invalid UTF-8 characters and filters them" do
      expect(system).to receive(:run_command).and_return(
        "f\0good_filename\0\0" \
        "f\0broken\255filename\0\0"
      )
      expect(Machinery::Ui).to receive(:warn)

      result = nil
      expect {
        result = subject.get_find_data("/etc", 1)
      }.to_not raise_error

      expect(result).to eq([{ "good_filename" => "" }, {}])
    end
  end

  describe "#helper_usable?" do
    context "when helper is there" do
      let(:system) { double(arch: "x86_64") }
      let(:description) { SystemDescription.new("systemname", SystemDescriptionStore.new) }
      let(:helper) { MachineryHelper.new(description) }

      it "doesn't use the helper when a remote user != roote is used" do
        expect(system).to receive(:remote_user).and_return("machinery)")
        expected = "Using traditional inspection because only 'root' is supported as remote user"
        allow_any_instance_of(MachineryHelper).to receive(:can_help?).and_return(true)

        subject.helper_usable?(helper)

        expect(captured_machinery_output).to include(expected)
      end
    end
  end

  it "runs helper" do
    system = double(arch: "x86_64")
    allow(system).to receive(:check_requirement)

    description = SystemDescription.new("systemname", SystemDescriptionStore.new)
    inspector = UnmanagedFilesInspector.new(system, description)

    allow_any_instance_of(MachineryHelper).to receive(:can_help?).and_return(true)
    expect_any_instance_of(MachineryHelper).to receive(:inject_helper)
    expect_any_instance_of(MachineryHelper).to receive(:remove_helper)
    expect_any_instance_of(MachineryHelper).to receive(:has_compatible_version?).and_return(true)
    expect_any_instance_of(MachineryHelper).to receive(:run_helper) do |_instance, scope|
      scope.files = UnmanagedFileList.new
    end

    inspector.inspect(Filter.from_default_definition("inspect"))
  end
end
