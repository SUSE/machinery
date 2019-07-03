# validate — Validate System Description

## Synopsis

`machinery validate` NAME

`machinery` help validate

## Description

The `validate` subcommand validates an existing system description.
It checks, that the description has the correct structure and the data stored
there conforms to the required schema. It also verifies that all extracted files
are present on disk and that all files have meta information.

In case of issues errors are shown with additional information.

The main purpose of this command is to verify the system description after
manually editing it.

## Arguments

  * `NAME` (required):
    Name of the system description.

## Examples

 * Validate the system description with the name `myhost`:

    $ `machinery` validate myhost
