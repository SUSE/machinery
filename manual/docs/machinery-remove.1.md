
# remove — Remove System Descriptions

## SYNOPSIS

`machinery remove` [--all]
    [NAME[,NAME2[,NAME3]]]

`machinery` help remove


## DESCRIPTION

The `remove` command removes all specified system descriptions.


## OPTIONS

  * `--all` (optional):
    Remove all stored system descriptions.

  * `--verbose` (optional):
    Explain what is being done.


## ARGUMENTS

  * `NAME...` (required):
    Remove specified system descriptions.


## EXAMPLES

  * Remove the system description stored as `earth`:

    $ `machinery` remove earth

  * Remove the system descriptions stored as `earth` and `moon`:

    $ `machinery` remove earth moon

  * Remove all stored system descriptions:

    $ `machinery` remove --all
