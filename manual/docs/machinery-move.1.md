
## move — Move System Description

### SYNOPSIS

`machinery move`
    FROM_NAME TO_NAME

`machinery` help move


### DESCRIPTION

The `move` command renames a stored system description from `FROM_NAME` to `TO_NAME`.


### ARGUMENTS
  * `FROM_NAME` (required):
    Current name of the system description.

  * `TO_NAME` (required):
    New name of the system description.


### EXAMPLES

  * Rename the system description `earth` to `moon`:

    $ `machinery` move earth moon
