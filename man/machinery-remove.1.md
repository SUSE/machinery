
## remove — Remove System Description

### SYNOPSIS

`machinery remove` [--all]
    NAME

`machinery` help remove


### DESCRIPTION

The `remove` command removes a stored system description.


### OPTIONS

  * `--all` (optional):
    Remove all stored system descriptions.

  * `--verbose` (optional):
    Explain what is being done.


### ARGUMENTS

  * `NAME` (required):
    Remove specified system description.


### EXAMPLES

  * Remove the system description stored as `earth`:

    $ `machinery` remove earth

  * Remove all stored system descriptions:

    $ `machinery` remove --all
