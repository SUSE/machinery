# export-kiwi — Export System Description as KIWI Image Description

## Synopsis

`machinery export-kiwi` -k | --kiwi-dir NAME
   --force

`machinery` help export-kiwi

## Description

The `export-kiwi` subcommand exports a stored system description as a KIWI
image description.

## Arguments

  * `NAME` (required):
    Name of the system description.

## Options

  * `-k KIWI_DIR`, `--kiwi-dir=KIWI_DIR` (required):
    Write the KIWI image description to a subdirectory at the specified directory. The directory
    will be created if it does not exist yet.

  * `--force` (optional):
    Overwrite existing system description

## Examples

 * Export the `myhost` system description to `/tmp/myhost-kiwi`:

    $ `machinery` export-kiwi myhost --kiwi-dir=/tmp
