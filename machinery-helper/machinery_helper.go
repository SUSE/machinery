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
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"unicode/utf8"
)

func getRpms() []string {
	cmd := exec.Command("rpm", "-qlav")
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		log.Fatal(err)
	}

	f := func(c rune) bool {
		return c == '\n'
	}
	packages := strings.FieldsFunc(out.String(), f)
	return packages
}

func parseRpmLine(line string) (fileType string, fileName string, linkTarget string) {
	fileType = line[0:1]

	index := strings.Index(line, "/")
	if index < 0 {
		panic(line)
	}
	file := line[index:]
	fields := strings.Split(file, " -> ")
	if len(fields) == 2 {
		fileName = fields[0]
		linkTarget = fields[1]
	} else {
		fileName = file
	}
	return
}

func addImplicitlyManagedDirs(dirs map[string]bool, files map[string]string) {
	for file, target := range files {
		for i := 1; i < len(file); i++ {
			if file[i] == '/' {
				topdir := file[:i]
				if _, ok := dirs[topdir]; !ok {
					dirs[topdir] = false
				}
			}
		}

		if target != "" {
			if _, ok := dirs[target]; ok {
				dirs[file] = false
			}
		}
	}
	return
}

func getManagedFiles() (map[string]string, map[string]bool) {
	files := make(map[string]string)
	dirs := make(map[string]bool)

	for _, pkg := range getRpms() {
		if pkg != "(contains no files)" {
			fileType, fileName, linkTarget := parseRpmLine(pkg)
			switch fileType {
			case "-":
				files[fileName] = ""
			case "d":
				dirs[fileName] = true
			case "l":
				files[fileName] = linkTarget
			}
		}
	}

	addImplicitlyManagedDirs(dirs, files)

	return files, dirs
}

func assembleJSON(unmanagedFilesMap interface{}) string {
	jsonMap := map[string]interface{}{"extracted": false, "files": unmanagedFilesMap}
	json, _ := json.MarshalIndent(jsonMap, " ", "  ")
	return string(json)
}

var readDir = func(dir string) ([]os.FileInfo, error) {
	return ioutil.ReadDir(dir)
}

func hasManagedDirs(dir string, rpmDirs map[string]bool) bool {
	for rpmDir := range rpmDirs {
		if strings.HasPrefix(rpmDir, dir+"/") {
			return true
		}
	}
	return false
}

func findUnmanagedFiles(dir string, rpmFiles map[string]string, rpmDirs map[string]bool,
	unmanagedFiles map[string]string, ignoreList map[string]bool) {
	files, _ := readDir(dir)
	for _, f := range files {
		fileName := dir + f.Name()
		if !utf8.ValidString(fileName) {
			fmt.Fprintln(os.Stderr, fileName, "contains invalid UTF-8 characters. Skipping.")
		} else {
			if _, ok := ignoreList[fileName]; !ok {
				if f.IsDir() {
					if _, ok := rpmDirs[fileName]; ok {
						findUnmanagedFiles(fileName+"/", rpmFiles, rpmDirs, unmanagedFiles, ignoreList)
					} else {
						if !hasManagedDirs(fileName, rpmDirs) {
							unmanagedFiles[fileName+"/"] = "dir"
						}
					}
				} else {
					if _, ok := rpmFiles[fileName]; !ok {
						if f.Mode()&
							(os.ModeSocket|os.ModeNamedPipe|os.ModeDevice|os.ModeCharDevice) != 0 {
							// Ignore sockets, named pipes and devices
						} else if f.Mode()&os.ModeSymlink == os.ModeSymlink {
							unmanagedFiles[fileName] = "link"
						} else {
							unmanagedFiles[fileName] = "file"
						}
					}
				}
			}
		}
	}
}

func printVersion() {
	fmt.Println("Version:", VERSION)
	os.Exit(0)
}

func main() {
	// check for tar extraction
	if len(os.Args) >= 2 {
		switch os.Args[1] {
		case "tar":
			Tar(os.Args[2:])
			os.Exit(0)
		}
	}

	// parse CLI arguments
	var versionFlag = flag.Bool("version", false, "shows the version number")
	flag.Parse()

	// show version
	if *versionFlag == true {
		printVersion()
	}

	// fetch unmanaged files
	unmanagedFiles := make(map[string]string)
	thisBinary, _ := filepath.Abs(os.Args[0])

	ignoreList := map[string]bool{
		thisBinary: true,
	}
	for _, mount := range RemoteMounts() {
		ignoreList[mount] = true
	}
	for _, mount := range SpecialMounts() {
		ignoreList[mount] = true
	}

	for _, mount := range RemoteMounts() {
		unmanagedFiles[mount+"/"] = "remote_dir"
	}

	rpmFiles, rpmDirs := getManagedFiles()
	findUnmanagedFiles("/", rpmFiles, rpmDirs, unmanagedFiles, ignoreList)

	files := make([]string, len(unmanagedFiles))
	i := 0
	for k := range unmanagedFiles {
		files[i] = k
		i++
	}
	sort.Strings(files)

	unmanagedFilesMap := make([]map[string]string, len(unmanagedFiles))
	for j := range files {
		entry := make(map[string]string)
		entry["name"] = files[j]
		entry["type"] = unmanagedFiles[files[j]]
		unmanagedFilesMap[j] = entry
	}

	json := assembleJSON(unmanagedFilesMap)
	fmt.Println(json)
}
