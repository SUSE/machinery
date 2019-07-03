# analyze — Analyze System Description

## Synopsis

`machinery analyze` NAME -o | --operation=OPERATION

`machinery` help analyze

## Description

The `analyze` subcommand analyzes an existing system description and enriches
it with additional information. Supported operations are:

  * `changed-config-files-diffs`:
    Generates the diffs between the extracted changed configuration files from the
    system and the original versions from the packages.
    The diffs can be shown using `machinery show --show-diffs`

## Arguments

  * `NAME` (required):
    Name of the system description.

## Options

  * `-o OPERATION`, `--operation=OPERATION` (required):
    The analyze operation to perform.

## Examples

 * Analyze the config file diffs for the `myhost` system description:

    $ `machinery` analyze myhost --operation=changed-config-files-diffs
