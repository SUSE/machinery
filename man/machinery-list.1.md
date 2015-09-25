
## list — List System Descriptions

### SYNOPSIS

`machinery list`
    [NAME[,NAME2[,NAME3]]]

`machinery` help list


### DESCRIPTION

List the specified system descriptions if parameter name is given.
List all available system descriptions in the internal database if no name parameter is given.
The list is sorted alphabetically and contains a name and the
scopes for each system.


### OPTIONS

  * `--verbose` (optional):
    Print additional information about the origin of scopes.
    Currently displays [HOSTNAME] and (DATE).
  * `--short` (optional):
    List only descripton names.


### EXAMPLES

  * Lists the two specified system descriptions `a` and `b`:

    $ `machinery` list a b

  * Lists all available system descriptions:

    $ `machinery` list

  * Same as previous command, but additionally prints the date of each scope:

    $ `machinery` list --verbose

  * Lists all available system description names without any additional details:

    $ `machinery` list --short
