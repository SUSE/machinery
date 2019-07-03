# remove — Remove System Descriptions

## Synopsis

`machinery remove` [--all]
    [NAME[,NAME2[,NAME3]]]

`machinery` help remove

## Description

The `remove` command removes all specified system descriptions.

## Options

  * `--all` (optional):
    Remove all stored system descriptions.

  * `--verbose` (optional):
    Explain what is being done.

## Arguments

  * `NAME...` (required):
    Remove specified system descriptions.

## Examples

  * Remove the system description stored as `earth`:

    $ `machinery` remove earth

  * Remove the system descriptions stored as `earth` and `moon`:

    $ `machinery` remove earth moon

  * Remove all stored system descriptions:

    $ `machinery` remove --all
