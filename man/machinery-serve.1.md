
## serve — Serve System Descriptions Using A Web Server

### SYNOPSIS

`machinery serve` [-p PORT | --port=PORT] [--public]

`machinery` help serve


### DESCRIPTION

The `serve` command spawns a web server to view system descriptions as an HTML
view.

By default the server is available from http://127.0.0.1:7585 but both the
IP address and the port can be configured using the according options.

Specific descriptions are available from http://127.0.0.1:7585/NAME, where NAME
is the name of the system description. If no name is specified in the URL an
overview of all descriptions is served.


### OPTIONS

  * `-p PORT`, `--port=PORT` (optional):
    Specify the port on which the web server will serve the HTML view: Default: 7585

    Ports can be selected in a range between 2-65535. Ports between 2 and 1023 can only be
    chosen when `machinery` will be executed as `root` user.

  * `--public` (optional):
    Specifying this option, lets the server listen on each configured IP address. By default
    the server will only listen on the localhost IP address 127.0.0.1


### EXAMPLES

  * Start the server with default options:

    $ `machinery` serve

  * Make the server available to other machines on the network on port 3000:

    $ `machinery` serve --public --port 3000
