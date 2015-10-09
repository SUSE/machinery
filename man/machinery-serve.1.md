
## serve — Serve A System Description Using A Web Server

### SYNOPSIS

`machinery serve` [-p PORT | --port=PORT] [--public] NAME

`machinery` help serve


### DESCRIPTION

The `serve` command spawns a web server and serves a stored system description on
it.
By default the description is available from http://127.0.0.1:7585 but both the
IP address and the port can be configured using the according options.


### ARGUMENTS

  * `NAME` (required):
    Use specified system description.


### OPTIONS

  * `-p PORT`, `--port=PORT` (optional):
    Specify the port on which the web server will serve the system description: Default: 7585

    Ports can be selected in a range between 2-65535. Ports between 2 and 1023 can only be
    chosen when `machinery` will be executed as `root` user.

  * `--public` (optional):
    Specifying this option, lets the server listen on each configured IP address. By default
    the server will only listen on the localhost IP address 127.0.0.1

### EXAMPLES

  * Serve the system description taken from the last inspection, saved as `earth`:

    $ `machinery` serve earth

  * Make the system description available to other machines on the network on port 3000:

    $ `machinery` serve earth --public --port 3000
