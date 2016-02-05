# SECURITY IMPLICATIONS
This document describes security related issues administrators need to be aware of when using
Machinery.

## Inspection
Machinery inspects several parts of a system which are covered by Machinery's scopes. A list
of the available scopes and information about what they do can be found
[here](machinery_main_scopes.1/index.html).

Users of Machinery who inspect systems need to be aware of the security implications in order
to take the right decisions on how to protect the retrieved data.

## Retrieval of Data
Machinery transfers data from one end point to another via SSH (using public key authentication).

Depending on the scope, Machinery [collects information](machinery_main_scopes.1/index.html)
about files on the system. Additionally, when the `--extract-files` option is given for the
`inspect` command, not only the meta data about the files (e.g. permission bits, owner, group etc
.) but also the file content is extracted. Machinery does not distinguish between sensitive
data (such as private keys or password files). That means that everyone with access to the system
description has automatically access to **all** extracted files and contained sensitive data.

#### root/sudo Privileges
An inspection can only be done, when the user on the inspected system is either root or has
sudo privileges. Information about the required sudo configuration can be found
[here](machinery-inspect.1/index.html#prerequisites).

## Storage of Data
#### Access Restrictions
After an inspection has been completed, the directory where the description is stored is made
readable only for the user. The data is not encrypted by Machinery.

#### Used Permission Bits
When Machinery extracts data, it sets permission bits for files and directories as follows:

| Permission Bits | Used for ...                                     |
| --------------- | ------------------------------------------------ |
| 0700            | ... directories inside the description directory |
| 0600            | ... for files inside the description directory   |

#### Accessing System Descriptions
By default, all system descriptions are stored in the directory `.machinery` in the home directory
of the user running Machinery. The directory can be redefined by the environment variable
`$MACHINERY_DIR`. Each description has its own subdirectory. There is a `manifest.json` file in
each description directory which contains the data of the inspection. Extracted files are stored in
separate subdirectories inside the same description directory.

## Presentation of Data
There are several ways how data can be presented to one or more users. The user has the option to
either start a web server and view descriptions or view the descriptions only in the console.

The following commands are used to present data to users:

* show
* compare
* serve
* list

All of the commands listed above also have a `--html` option. When this option is used, Machinery
starts a web server what will listen on the IP address `127.0.0.1`. The `serve` command
offers also a `--public` option which makes the server listen on all configured IP addresses.

**WARNING:** When making the server reachable from the outside, users can modify the link to
access also other descriptions. There is currently no way to restrict the access to only one
description.

The `serve` command also allows the user to specify a port via the `--port` option. When no port
is specified, the default port which is configured in the machinery config file in
`~/.machinery/machinery.config`) will be taken.

## Export of Data
#### export-autoyast
The `export-autoyast` command creates an AutoYaST profile for an automated installation. The result
are also tar balls containing the extracted files from the system description. These files
potentially contain sensitive data (e.g. passwords). This fact needs to be kept in mind, especially
if these files are copied to a web server for an AutoYaST installation via HTTP.

#### export-kiwi
The program Kiwi allows you to build OS images what you can use for installation. Machinery gives
you the opportunity to build a complete Kiwi configuration from a system description. This
configuration can be used to build an image via Kiwi. The `export-kiwi` command creates a
directory, where it stores the Kiwi configuration and the files of a system description. These
files potentially contain sensitive data (e.g. passwords).

#### build
The created image potentially contains sensitive data (e.g. passwords) from extracted files.

#### deploy
The uploaded image potentially contains sensitive data (e.g. passwords) from extracted files.
