
## list — List System Descriptions

### SYNOPSIS

`machinery list`

`machinery` help list


### DESCRIPTION

List all available system descriptions in the internal database.
The list is sorted alphabetically and contains a name and the
scopes for each system.


### OPTIONS

  * `--verbose` (optional):
    Print additional information about the origin of scopes.
    Currently displays [HOSTNAME] and (DATE).
  * `--short` (optional):
    List only descripton names.


### EXAMPLES

  * Lists all available system descriptions:

    $ `machinery` list

  * Same as previous command, but additionally prints the date of each scope:

    $ `machinery` list --verbose

  * Lists all available system description names without any additional details:

    $ `machinery` list --short
