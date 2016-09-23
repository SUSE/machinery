# export-html — Export System Description as HTML

## Synopsis

`machinery export-html` -d | --html-dir=DIRECTORY NAME
   --force

`machinery` help export-html

## Description

The `export-html` subcommand exports a stored system description as HTML.

## Arguments

  * `NAME` (required):
    Name of the system description.

## Options

  * `-d DIRECTORY`, `--html-dir=DIRECTORY` (required):
    Write the HTML page and assets to this directory. The directory will
    be created if it does not exist yet.

  * `--force` (optional):
    Delete the directory if it exists and recreate it.

## Examples

 * Export the `myhost` system description to `/tmp/myhost-html`:

    $ `machinery` export-html --html-dir=/tmp myhost
