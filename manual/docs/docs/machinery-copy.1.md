# copy — Copy System Description

## Synopsis

`machinery copy` FROM_NAME TO_NAME

`machinery` help copy

## Description

The `copy` command copies a stored system description. It creates a new
description named TO_NAME containing the same content as the description
FROM_NAME.

## Arguments
  * `FROM_NAME` (required):
    Name of the source system description.

  * `TO_NAME` (required):
    Name of the target system description.

## Examples

  * Create a copy of the system description `earth` under the name `moon`:

    $ `machinery` copy earth moon
