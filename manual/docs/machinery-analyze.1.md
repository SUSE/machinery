# analyze — Analyze System Description

## SYNOPSIS

`machinery analyze` NAME -o | --operation=OPERATION

`machinery` help analyze


## DESCRIPTION

The `analyze` subcommand analyzes an existing system description and enriches
it with additional information. Supported operations are:

  * `config-file-diffs`:
    Generates the diffs between the extracted changed config files from the
    system and the original versions from the RPM packages.
    The diffs can be shown using `machinery show --show-diffs`


## ARGUMENTS

  * `NAME` (required):
    Name of the system description.


## OPTIONS

  * `-o OPERATION`, `--operation=OPERATION` (required):
    The analyze operation to perform.


## EXAMPLES

 * Analyze the config file diffs for the `myhost` system description:

    $ `machinery` analyze myhost --operation=config-file-diffs
