# move — Move System Description

## Synopsis

`machinery move`
    FROM_NAME TO_NAME

`machinery` help move

## Description

The `move` command renames a stored system description from `FROM_NAME` to `TO_NAME`.

## Arguments
  * `FROM_NAME` (required):
    Current name of the system description.

  * `TO_NAME` (required):
    New name of the system description.

## Examples

  * Rename the system description `earth` to `moon`:

    $ `machinery` move earth moon
