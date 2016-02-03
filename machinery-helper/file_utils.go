package main

import (
	"os/exec"
	"log"
	"strings"
	"bytes"
)

var statFile = func(path string) string {
	cmd := exec.Command("stat", "-c", "%U:%G", path)
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		log.Fatal(err)
	}

	return strings.Trim(out.String(), "\n")
}

func getFileOwnerGroup(path string) (user, group string) {
	split := strings.Split(statFile(path), ":")
	user = split[0]
	group = split[1]

	return
}
