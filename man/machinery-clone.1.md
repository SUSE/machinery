
## clone — Clone System Description

### SYNOPSIS

`machinery clone`
    FROM_NAME TO_NAME

`machinery` help clone


### DESCRIPTION

The `clone` command clones a stored system description. It creates a new
description named TO_NAME containing the same content as the description
FROM_NAME.


### ARGUMENTS
  * `FROM_NAME` (required):
    Name of the source system description.

  * `TO_NAME` (required):
    Name of the target system description.


### EXAMPLES

  * Create a clone of the system description `earth` under the name `moon`:

    $ `machinery` clone earth moon
