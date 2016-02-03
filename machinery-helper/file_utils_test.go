package main

import (
	"testing"
)

func TestGetFileOwnerGroup(t *testing.T) {
	statFile = func(path string) string {
		return "foo:bar"
	}
	path := "/etc/passwd"

	owner, group := getFileOwnerGroup(path)

	if owner != "foo" {
		t.Errorf("GetFileOwner('%v') = '%v', want '%v'", path, owner, "foo")
	}
	if group != "bar" {
		t.Errorf("GetFileOwner('%v') = '%v', want '%v'", path, owner, "bar")
	}
}
