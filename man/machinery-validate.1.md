
## validate — Validate System Description

### SYNOPSIS

`machinery validate` NAME

`machinery` help validate


### DESCRIPTION

The `validate` subcommand validates an existing system description.
It checks, that the description has the correct structure and the data stored
there conforms to the required schema.

In case of issues errors are shown with additional information.

The main purpose of this command is to verify the system description after
manually editing it.


### ARGUMENTS

  * `NAME` (required):
    Name of the system description.


### EXAMPLES

 * Validate the system description with the name `myhost`:

   $ `machinery` validate myhost
