//  Copyright (c) 2015 SUSE LLC
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of version 3 of the GNU General Public License as
//  published by the Free Software Foundation.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, contact SUSE LLC.
//
//  To contact SUSE about this file by physical or electronic mail,
//  you may find current contact information at www.suse.com

package main

import (
  "io/ioutil"
  "strings"
  "sort"
)

// this specifies the path of the process mounts. This needs to be
// exported for the test cases
var ProcMountsPath = "/proc/mounts"

var remoteFileSystems = []string{"autofs", "cifs", "nfs", "nfs4"}
var specialFileSystems = []string{"proc", "sysfs", "devtmpfs", "tmpfs", "rpc_pipefs", "fuse.gvfs-fuse-daemon"}
var localFileSystems  = []string{"ext2", "ext3", "ext4", "reiserfs", "btrfs", "vfat", "xfs", "jfs"}

func parseMounts() map[string]string {
  mount, _ := ioutil.ReadFile(ProcMountsPath)
  mounts := make(map[string]string)

  lines := strings.Split(string(mount), "\n")

  for _, line := range(lines) {
    elements := strings.Split(line, " ")

    if len(elements) >= 3 {
      mounts[elements[1]] = elements[2]
    }
  }

  return mounts
}

func selectFileSystems(allMounts map[string]string, fileSystems[]string) []string {
  mounts := []string{}

  for path, fs := range(allMounts) {
    for _, specialFs := range fileSystems {
      if specialFs == fs {
        mounts = append(mounts, path)
      }
    }
  }
  sort.Strings(mounts)

  return mounts
}

// SpecialMounts returns an array of all special mount paths like
// proc or sysfs
func SpecialMounts() []string {
  return selectFileSystems(parseMounts(), specialFileSystems)
}

// LocalMounts returns an array of all local mount paths
func LocalMounts() []string {
  return selectFileSystems(parseMounts(), localFileSystems)
}

// RemoteMounts returns an array of all remote mount paths
// (for example NFS mount points)
func RemoteMounts() []string {
  return selectFileSystems(parseMounts(), remoteFileSystems)
}
