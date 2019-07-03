# upgrade-format — Upgrade System Description

## Synopsis

`machinery upgrade-format` --all

`machinery upgrade-format` NAME

`machinery` help upgrade-format

## Description

The `upgrade-format` command upgrades a system description to the latest format
version.

The `format` in this context is the structure of the internal system description
data. If the format version of a system description does not match the current
`machinery` format version, `machinery` is no longer able to work with the data
until it is upgraded. The current format version can be retrieved using
`machinery --version`. The format version of a system description can be found
in the `meta` section of the according `manifest.json` file.

If the `--all` switch is given all local descriptions will be upgraded.

## Options

  * `--all` (optional):
    Upgrade all stored system descriptions.

## Arguments

  * `NAME` (optional):
    Upgrade specified system description.

## Examples

  * Upgrade the system description stored as `earth`:

    $ `machinery` upgrade-format earth

  * Upgrade all stored system descriptions:

    $ `machinery` upgrade-format --all
