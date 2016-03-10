
# compare — Compare System Descriptions

## SYNOPSIS

`machinery compare` [-s SCOPE | --scope=SCOPE] [-e ignore-scope | --ignore-scope=ignore-scope] [--no-pager] [--show-all] [--html] NAME1 NAME2

`machinery` help compare


## DESCRIPTION

The `compare` command compares stored system descriptions. The scope option can
be used to limit the output to the given scopes.


## ARGUMENTS

  * `NAME1` (required):
    First system description to compare.

  * `NAME2` (required):
    Second system description to compare.


## OPTIONS

  * `-s SCOPE`, `--scope=SCOPE` (optional):
    Limit output to the specified scope.
    See the [Scope section](#Scopes) for more information.

  * `-e SCOPE`, `--ignore-scope=ignore-scope` (optional):
    Skip output of the specified scope.
    See the [Scope section](#Scopes) for more information.

  * `--no-pager` (optional):
    Do not pipe output into a pager.

  * `--show-all` (optional):
    Show also common properties of the descriptions (not only the differences).

  * `--html` (optional):
    Shows the comparison of two system descriptions in the web browser.


## EXAMPLES

  * Compare system descriptions saved as `earth` and `moon`:

    $ `machinery` compare earth moon

  * Compare system descriptions, but limit the scope to repositories only:

    $ `machinery` compare earth moon -s repositories

  * Compare lists of changed managed files and include the common ones in the
    list:

    $ `machinery` compare earth moon --scope=changed-managed-files --show-all

  * Compares system descriptions and shows the result in HTML format in your web browser:

    $ `machinery` compare --html earth moon
