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
	"reflect"
	"testing"
)

func TestParseMounts(t *testing.T) {
	ProcMountsPath = "fixtures/proc_mounts"

	expectedMounts := map[string]string{
		"/dev":              "devtmpfs",
		"/homes/tux":        "nfs",
		"/data":             "ext4",
		"/":                 "ext4",
		"/var/lib/ntp/proc": "proc",
		"/var/lib/tmpfs":    "tmpfs",
	}

	actualMounts := parseMounts()
	if !reflect.DeepEqual(actualMounts, expectedMounts) {
		t.Errorf("Expected: ", expectedMounts, " Got: ", actualMounts)
	}
}

func TestSpecialMounts(t *testing.T) {
	ProcMountsPath = "fixtures/proc_mounts"

	expectedMounts := []string{"/dev", "/var/lib/ntp/proc", "/var/lib/tmpfs"}
	actualMounts := SpecialMounts()

	if !reflect.DeepEqual(actualMounts, expectedMounts) {
		t.Errorf("Expected: ", expectedMounts, " Got: ", actualMounts)
	}
}

func TestLocalMounts(t *testing.T) {
	ProcMountsPath = "fixtures/proc_mounts"

	expectedMounts := []string{"/", "/data"}
	actualMounts := LocalMounts()

	if !reflect.DeepEqual(actualMounts, expectedMounts) {
		t.Errorf("Expected: ", expectedMounts, " Got: ", actualMounts)
	}
}

func TestRemoteMounts(t *testing.T) {
	ProcMountsPath = "fixtures/proc_mounts"

	expectedMounts := []string{"/homes/tux"}
	actualMounts := RemoteMounts()

	if !reflect.DeepEqual(actualMounts, expectedMounts) {
		t.Errorf("Expected: ", expectedMounts, " Got: ", actualMounts)
	}
}
