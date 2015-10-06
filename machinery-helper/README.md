# machinery-helper

A helper binary used by Machinery - http://machinery-project.org

It inspects a system for unmanaged-files (files not tracked by rpm)
and outputs the result in the
[Machinery json format](https://github.com/SUSE/machinery/blob/master/docs/System-Description-Format.md).

## Build

Make sure that the official Go Development environment is installed.

To build the helper binary just run `go build`.
