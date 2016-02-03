// Copyright (c) 2015 SUSE LLC
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of version 3 of the GNU General Public License as
// published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, contact SUSE LLC.
//
// To contact SUSE about this file by physical or electronic mail,
// you may find current contact information at www.suse.com

package main

import (
	"github.com/nowk/go-fakefileinfo"
	"os"
	"reflect"
	"testing"
	"time"
)

func doTestParseRpmLine(t *testing.T, line string, expectedFileType string, expectedFileName string, expectedLinkTarget string) {
	fileType, fileName, linkTarget := parseRpmLine(line)

	if fileType != expectedFileType {
		t.Errorf("parseRpmLine('%s') file type = '%s', want '%s'", line, fileType, expectedFileType)
	}
	if fileName != expectedFileName {
		t.Errorf("parseRpmLine('%s') file name = '%s', want '%s'", line, fileName, expectedFileName)
	}
	if linkTarget != expectedLinkTarget {
		t.Errorf("parseRpmLine('%s') file type = '%s', want '%s'", line, linkTarget, expectedLinkTarget)
	}
}

func TestParseRpmLineFile(t *testing.T) {
	line := "-rw-r--r--    1 root    root                 18234080 Mar 31 11:40 /usr/lib64/libruby2.0-static.a"

	expectedFileType := "-"
	expectedFileName := "/usr/lib64/libruby2.0-static.a"
	expectedLinkTarget := ""

	doTestParseRpmLine(t, line, expectedFileType, expectedFileName, expectedLinkTarget)
}

func TestParseRpmLineDir(t *testing.T) {
	line := "drwxr-xr-x    2 root    root                        0 Mar 31 11:45 /usr/include/ruby-2.0.0/x86_64-linux/ruby"

	expectedFileType := "d"
	expectedFileName := "/usr/include/ruby-2.0.0/x86_64-linux/ruby"
	expectedLinkTarget := ""

	doTestParseRpmLine(t, line, expectedFileType, expectedFileName, expectedLinkTarget)
}

func TestParseRpmLineLink(t *testing.T) {
	line := "lrwxrwxrwx    1 root    root                       19 Mar 31 11:45 /usr/lib64/libruby2.0.so -> libruby2.0.so.2.0.0"

	expectedFileType := "l"
	expectedFileName := "/usr/lib64/libruby2.0.so"
	expectedLinkTarget := "libruby2.0.so.2.0.0"

	doTestParseRpmLine(t, line, expectedFileType, expectedFileName, expectedLinkTarget)
}

func TestParseRpmLineFileSpaces(t *testing.T) {
	line := "-rw-r--r--    1 root    root                    61749 Jun 26 01:56 /usr/share/kde4/templates/kipiplugins_photolayoutseditor/data/templates/a4/h/Flipping Tux Black.ple"

	expectedFileType := "-"
	expectedFileName := "/usr/share/kde4/templates/kipiplugins_photolayoutseditor/data/templates/a4/h/Flipping Tux Black.ple"
	expectedLinkTarget := ""

	doTestParseRpmLine(t, line, expectedFileType, expectedFileName, expectedLinkTarget)
}

func TestAddImplicitlyManagedDirs(t *testing.T) {
	filesOriginal := map[string]string{
		"/abc/def/ghf/somefile": "",
		"/zzz":                  "/abc/def",
	}
	dirsOriginal := map[string]bool{
		"/abc/def": true,
	}
	dirsExpected := map[string]bool{
		"/abc":         false,
		"/abc/def":     true,
		"/abc/def/ghf": false,
		"/zzz":         false,
	}

	dirs := dirsOriginal

	addImplicitlyManagedDirs(dirs, filesOriginal)

	if !reflect.DeepEqual(dirs, dirsExpected) {
		t.Errorf("addImplicitlyManagedDirs('%v') = '%v', want '%v'", dirsOriginal, dirs, dirsExpected)
	}
}

func TestAssembleJSON(t *testing.T) {
	unmanagedFilesMap := map[string]string{
		"name": "/usr/share/go_rulez", "type": "file",
	}
	want := `{
   "extracted": false,
   "files": {
     "name": "/usr/share/go_rulez",
     "type": "file"
   }
 }`

	json := assembleJSON(unmanagedFilesMap)
	if !reflect.DeepEqual(json, want) {
		t.Errorf("assembleJSON() = '%v', want '%v'", json, want)
	}
}

func TestRespectManagedDirsInUnmanagedDirs(t *testing.T) {
	unmanagedFiles := make(map[string]string)
	wantUnmanagedFiles := make(map[string]string)

	/*
	  We mock the readDir method and return following directory structure:
	   /
	   /managed_dir/
	   /managed_dir/unmanaged_dir/
	   /managed_dir/unmanaged_dir/managed_dir/
	*/
	readDir = func(dir string) ([]os.FileInfo, error) {
		dirs := make([]os.FileInfo, 0, 1)
		var fi os.FileInfo
		switch dir {
		case "/":
			fi = fakefileinfo.New("managed_dir", int64(123), os.ModeType, time.Now(), true, nil)
		case "/managed_dir/":
			fi = fakefileinfo.New("unmanaged_dir", int64(123), os.ModeType, time.Now(), true, nil)
		case "/managed_dir/unmanaged_dir/":
			fi = fakefileinfo.New("managed_dir", int64(123), os.ModeType, time.Now(), true, nil)
		}
		dirs = append(dirs, fi)
		return dirs, nil
	}

	rpmFiles := make(map[string]string)
	ignoreList := make(map[string]bool)

	rpmDirs := map[string]bool{
		"/managed_dir":                           true,
		"/managed_dir/unmanaged_dir/managed_dir": true,
	}

	findUnmanagedFiles("/", rpmFiles, rpmDirs, unmanagedFiles, ignoreList)

	if !reflect.DeepEqual(unmanagedFiles, wantUnmanagedFiles) {
		t.Errorf("findUnmanagedFiles() = '%v', want '%v'", unmanagedFiles, wantUnmanagedFiles)
	}
}

func TestHasManagedDirs(t *testing.T) {
	rpmDirs := map[string]bool{
		"/managed_dir":                                   true,
		"/managed_dir/unmanaged_dir/sub_dir/managed_dir": true,
	}

	hasDirs := hasManagedDirs("/managed_dir/unmanaged_dir", rpmDirs)
	want := true

	if hasDirs != want {
		t.Errorf("hasManagedDirs() = '%v', want '%v'", hasDirs, want)
	}

}

func TestSubdirIsNotAccidentallyConsideredManaged(t *testing.T) {
	rpmDirs := map[string]bool{
		"/usr":        true,
		"/usr/foobar": true,
	}

	hasDirs := hasManagedDirs("/usr/foo", rpmDirs)
	want := false

	if hasDirs != want {
		t.Errorf("hasManagedDirs() = '%v', want '%v'", hasDirs, want)
	}
}

func TestPermToString(t *testing.T) {
	entry := UnmanagedFile{}

	amendMode(&entry, os.FileMode(0777))
	want := "777"
	if entry.Mode != want {
		t.Errorf("amendMode() = '%v', want '%v", entry.Mode, want)
	}

	amendMode(&entry, os.FileMode(0222))
	want = "222"
	if entry.Mode != want {
		t.Errorf("amendMode() = '%v', want '%v", entry.Mode, want)
	}

	perm := os.FileMode(0222 | os.ModeSticky)
	amendMode(&entry, perm)
	want = "1222"
	if entry.Mode != want {
		t.Errorf("amendMode() = '%v', want '%v", entry.Mode, want)
	}

	perm = os.FileMode(0222 | os.ModeSetuid)
	amendMode(&entry, perm)
	want = "2222"
	if entry.Mode != want {
		t.Errorf("amendMode() = '%v', want '%v", entry.Mode, want)
	}

	perm = os.FileMode(0555 | os.ModeSticky | os.ModeSetgid)
	amendMode(&entry, perm)
	want = "5555"
	if entry.Mode != want {
		t.Errorf("amendMode() = '%v', want '%v", entry.Mode, want)
	}
}

func TestAmendSize(t *testing.T) {
	entry := UnmanagedFile{Type: "link"}

	amendSize(&entry, 0)
	if entry.Size != nil {
		t.Errorf("Link should not get a size")
	}

	entry = UnmanagedFile{Type: "file"}

	amendSize(&entry, 0)
	if *entry.Size != 0 {
		t.Errorf("File should get a size")
	}
}
