# Machinery — A Systems Management Toolkit for Linux

# Synopsis

`machinery` SUBCOMMAND \[options\] <br>
`machinery` help [SUBCOMMAND]

# Conceptual Overview

Machinery's core concept is the complete representation of a system by a
universal system description.
System descriptions are managed independently of the described
systems which allows for system state conservation and offline preparation of
modifications.

Machinery's subcommands work on the system description as the connecting
element.
System descriptions are obtained by inspecting systems, importing from other
formats, manual creation or merging existing descriptions.
Machinery can store and modify system descriptions to allow changes to
described state of the system.
System descriptions can be compared to find similarities and differences
between them or analyzed to deepen the knowledge about particular aspects of
the system.
System descriptions may be exported to other formats and can be used to
migrate or replicate systems.

Subcommands can be combined in different ways to accommodate higher-level work
flows and use cases.
These are some implemented and planned use cases:

Migrate a physical system to a virtual environment:

  - Inspect a system to obtain a system description
  - Export the system description to a Kiwi configuration
  - Build a cloud image from the configuration
  - Deploy the image to the cloud

Migrate a system while changing the configuration:

  - Inspect a system to obtain a system description
  - Modify the system description
  - Build image for deployment

Using Machinery as an extension from other formats:

  - Import AutoYaST profile as system description
  - Build image for deployment

Machinery provides an extensible set of tools which can be combined to create
higher-level work flows.
It is designed for environments which focus on automation, integration
of diverse tools and accountable management.
Machinery integrates with existing configuration management solutions to
address use cases currently not covered by them.

## The machinery Command

Machinery is implemented as a command line tool named `machinery`. The
`machinery` command has several subcommands for specific tasks. All
subcommands work with the same system description identified by an optional
name which can be used by all subcommands.

## System Description

The System Description format and file structure is documented in the machinery
wiki: [System Description Format](https://github.com/SUSE/machinery/wiki/System-Description-Format).

Machinery validates descriptions on load. It checks that the JSON structure of
the manifest file, which contains the primary and meta data of a description, is 
correct and it adheres to the schema. Validation errors are reported as warnings.
It also checks that the information about extracted files is consistent. Missing
files or extra files without reference in the manifest are treated also as
warnings. All other issues are errors which need to be fixed so that Machinery
can use the description.
To manually validate a description use the `machinery validate` command.

## Scopes

The system description is structured into "scopes". A scope covers a specific
part of the configuration of the inspected system such as installed packages,
repositories, or changed configuration files.

For example, if you are only interested in the installed packages, limit the
scope to `packages`. This will output only the requested information.

See the [Scopes documentation](machinery_main_scopes.1/) for a list of all supported scopes.

# Options for All Subcommands
<!--- These are 'global' options of machinery -->

  * `--version`:
    Displays version of `machinery` tool. Exit when done.

  * `--debug`:
    Enable debug mode. Machinery writes additional information into the log
    file which can be useful to track down problems.

# Files and Devices

  * `~/.machinery/machinery.config`:

    Configuration file.

  * `~/.machinery/machinery.log`:

    Central log file, in the format date, time, process id, and log message.

  * `em1 (openSUSE 13.2 / openSUSE leap)`, `eth0` (SLE11) and `lan0` (SLE12):

    First network device is used when DHCP in built image is enabled.

# Environment

  * `MACHINERY_LOG_FILE`:

    Location of Machinery's log file (defaults to `~/.machinery/machinery.log`).

# Copyright

Copyright \(c) 2013-2016 [SUSE LLC](http://www.suse.com)
