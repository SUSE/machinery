
## show — Show System Description

### SYNOPSIS

`machinery show` [-s SCOPE | --scope=SCOPE] [-e EXCLUDE-SCOPE | --exclude-scope=EXCLUDE-SCOPE] [--no-pager] [--show-diffs] [--html] [-p PORT | --port=PORT] [-i IP | --ip=IP] NAME

`machinery` help show


### DESCRIPTION

The `show` command displays a stored system description.
Scopes are supported and limit the output to the given scope.
The hostname of the inspected system and the last modification
in local time are shown in the title of each scope section.


### ARGUMENTS

  * `NAME` (required):
    Use specified system description.


### OPTIONS

  * `-s SCOPE`, `--scope=SCOPE` (optional):
    Limit output to the specified scope.
    See the [Scope section](#Scopes) for more information.
    If displaying information related to a scope fails, `show` will print an error message what has failed.
    In case of an error, no content is displayed.

  * `-e EXCLUDE-SCOPE`, `--exclude-scope=EXCLUDE-SCOPE` (optional):
    Skip output of the specified scope.
    See the [Scope section](#Scopes) for more information.

  * `--no-pager` (optional):
    Do not pipe output into a pager.

  * `--show-diffs` (optional):
    Include the generated diffs in the output if available (see `machinery help analyze`
    for more information).

  * `--html` (optional):
    Run a web server and open the system description in HTML format in your web browser using the
    `xdg-open` command.

  * `-p PORT`, `--port=PORT` (optional):
    Specify the port on which the web server will serve the system description: Default: 7585

    Ports can be selected in a range between 2-65535. Ports between 2 and 1023 can only be
    chosen when `machinery` will be executed as `root` user.

  * `-i IP`, `--ip=IP` (optional):
    Specify the IP address on which the web server will be made available. Default: 127.0.0.1

    It's only possible to use an IP address (or hostnames resolving to an IP address) which
    is assigned to a network interface on the local machine.

  * `--verbose` (optional):
    Display the filters which were applied before showing the system description.

### EXAMPLES

  * Show the system description taken from the last inspection, saved as `earth`:

    $ `machinery` show earth

  * Show the system description, but limit the scope to repositories only:

    $ `machinery` show earth -s repositories

  * Show the list of changed managed files:

    $ `machinery` show earth --scope=changed-managed-files