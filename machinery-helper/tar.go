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
  "flag"
  "os"
  "io"
  "bufio"
  "strings"
  "archive/tar"
  "compress/gzip"
  "fmt"
  "path/filepath"
  "os/user"
  "strconv"
  "os/exec"
)

type stringArrayFlag []string
func (i *stringArrayFlag) String() string {
  return "exclude"
}
func (i *stringArrayFlag) Set(value string) error {
  *i = append(*i, value)
  return nil
}

var excludeList = make(map[string]bool)
var gzipWriter = gzip.NewWriter(os.Stdout)
var tarWriter = tar.NewWriter(gzipWriter)

func addPath(path string, info os.FileInfo, err error) error {
  if err != nil {
    return err
  }

  if stat, err := os.Lstat(path); err == nil {
    if _, ok := excludeList[strings.TrimRight(path, "/")]; ok {
      return nil
    }

    linkTarget := ""
    if(stat.Mode() & os.ModeSymlink != 0) {
      if linkTarget, err= os.Readlink(path); err != nil {
        return err
      }
    }
    header, err := tar.FileInfoHeader(stat, linkTarget)
    header.Name = strings.TrimLeft(path, "/")
    if err != nil {
      return err
    }

    username, err := user.LookupId(strconv.Itoa(header.Uid))
    if err != nil {
      return err
    }
    header.Uname = username.Username

    groupname, err := exec.Command("bash", "-c",
      fmt.Sprintf("getent group %d | cut -d: -f1", header.Gid)).Output()
    if err != nil {
      return err
    }
    header.Gname = strings.TrimSpace(string(groupname))

    if err := tarWriter.WriteHeader(header); err != nil {
      return err
    }

    if stat.Mode().IsRegular() {
      file, err := os.Open(path)
      if err != nil {
        return err
      }
      defer file.Close()

      if _, err := io.Copy(tarWriter, file); err != nil {
        return err
      }
    }
  }
  return nil
}

// Tar represents the "tar" command for the machinery-helper
func Tar(args []string) {
  var files []string
  tarCommand := flag.NewFlagSet("tar", flag.ExitOnError)
  tarCommand.Bool("create", true, "Create an tar archive")
  tarCommand.Bool("gzip", true, "Compress archive using GZip")
  tarCommand.Bool("null", true, "Read null-terminated names")
  filesFromFlag := tarCommand.String("files-from", "", "Where to take the file list from")

  var excludeFlag stringArrayFlag
  tarCommand.Var(&excludeFlag, "exclude", "Read null-terminated names")

  tarCommand.Parse(args)
  for _, path := range(excludeFlag) {
    excludeList[path] = true
  }

  if(*filesFromFlag == "-") {
    reader := bufio.NewReader(os.Stdin)

    for {
      s, err := reader.ReadString('\x00')

      files = append(files, strings.TrimRight(strings.TrimSpace(s), "\x00"))

      if err == io.EOF {
        break
      }
    }
  } else {
    files = tarCommand.Args()
  }

  for i := range files {
    if err := filepath.Walk(files[i], addPath); err != nil {
      fmt.Fprintln(os.Stderr, "Error:", err)
    }
  }
  defer gzipWriter.Close()
  defer tarWriter.Close()
}
