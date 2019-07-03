# show — Show System Description

## Synopsis

`machinery show` [-s SCOPE | --scope=SCOPE] [-e IGNORE-SCOPE | --ignore-scope=IGNORE-SCOPE] [--no-pager] [--show-diffs] [--html] NAME

`machinery` help show

## Description

The `show` command displays a stored system description.
Scopes are supported and limit the output to the given scope.
The hostname of the inspected system and the last modification
in local time are shown in the title of each scope section.

## Arguments

  * `NAME` (required):
    Use specified system description.

## Options

  * `-s SCOPE`, `--scope=SCOPE` (optional):
    Limit output to the specified scope.
    See the [Scope section](machinery_main_scopes.1.md) for more information.
    If displaying information related to a scope fails, `show` will print an error message what has failed.
    In case of an error, no content is displayed.

  * `-e IGNORE-SCOPE`, `--ignore-scope=IGNORE-SCOPE` (optional):
    Skip output of the specified scope.
    See the [Scope section](machinery_main_scopes.1.md) for more information.

  * `--no-pager` (optional):
    Do not pipe output into a pager.

  * `--show-diffs` (optional):
    Include the generated diffs in the output if available (see `machinery help analyze`
    for more information).

  * `--html` (optional):
    Run a web server and open the system description in HTML format in your web browser using the
    `xdg-open` command.

  * `--verbose` (optional):
    Display the filters which were applied before showing the system description.

## Examples

  * Show the system description taken from the last inspection, saved as `earth`:

    $ `machinery` show earth

  * Show the system description, but limit the scope to repositories only:

    $ `machinery` show earth -s repositories

  * Show the list of changed managed files:

    $ `machinery` show earth --scope=changed-managed-files
