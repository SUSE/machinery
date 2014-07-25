
## list — List System Descriptions

### SYNOPSIS

`machinery list`

`machinery` help list


### DESCRIPTION

List all available system descriptions in the internal database.
The list is sorted alphabetically and contains a name and the
scopes for each system.

The option `--verbose` additionally prints the inspection dates
of each scope.


### EXAMPLES

  * Lists all available system descriptions:

    $ `machinery` list

  * Same as previous command, but additionally prints the date of each scope:

    $ `machinery` list --verbose
