# Machinery — A Systems Management Toolkit for Linux

# SYNOPSIS

`machinery` SUBCOMMAND \[options\] <br>
`machinery` help [SUBCOMMAND]


# DESCRIPTION

Machinery is a systems management toolkit for Linux. It supports configuration
discovery, system validation, and service migration. Machinery is based on the
idea of an universal system description. Machinery has a set of commands which
work with this system description. These commands can be combined to form work
flows. Machinery is targeted at the system administrator of the data center.


# WORK FLOW EXAMPLES

## Inspect a System and Show Results
  - `machinery inspect --extract-files --name=NAME HOSTNAME`
  - `machinery show NAME`

## Inspect Two Systems and Compare Them
  - `machinery inspect HOSTNAME1`
  - `machinery inspect HOSTNAME2`
  - `machinery compare HOSTNAME1 HOSTNAME2`

## Fully Inspect a System and Export a Kiwi Description
  - `machinery inspect --extract-files HOSTNAME`
  - `machinery export-kiwi --kiwi-dir=~/kiwi HOSTNAME`

## Fully Inspect a System and Export an AutoYaST Profile
  - `machinery inspect --extract-files HOSTNAME`
  - `machinery export-autoyast --autoyast-dir=~/autoyast HOSTNAME`

## Fully Inspect a System and Deploy a Replicate to the Cloud
  - `machinery inspect --extract-files HOSTNAME`
  - `machinery deploy --cloud-config=~/openrc.sh HOSTNAME`

## How to upgrade a SLES 11 SP3 system to SLES 12
  - Machinery can help you to upgrade without affecting the original system.
    For more details please read the Wiki Page: <br>
    https://github.com/SUSE/machinery/wiki/How-to-upgrade-a-SLES-11-SP3-system-to-SLES-12


# CONCEPTUAL OVERVIEW

Machinery's core concept is the complete representation of a system by a
universal system description.
System descriptions are managed independently of the described
systems which allows for system state conservation and offline preparation of
modifications.

Machinery's subcommands work on the system description as the connecting
element.
System descriptions are obtained by inspecting systems, importing from other
formats, manual creation or merging other descriptions.
Machinery can store and modify system descriptions to allow changes to
described state of the system.
System descriptions can be compared to find similarities and differences
between them or analyzed to deepen the knowledge about particular aspects of
the system.
System descriptions may be exported to other formats and can be used to
migrate or replicate systems.

Subcommands can be combined in different ways to accomodate higher-level work
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


## Scopes

The system description is structured into "scopes". A scope covers a specific
part of the configuration of the inspected system such as installed packages,
repositories, or changed configuration files.

For example, if you are only interested in the installed packages, limit the
scope to `packages`. This will output only the requested information.

The the [scopes documentation](machinery_main_scopes.1) for a list of all supported scopes.

# FILES AND DEVICES

  * `~/.machinery/machinery.config`:

    Configuration file.

  * `~/.machinery/machinery.log`:

    Central log file, in the format date, time, process id, and log message.

  * `eth0` (SLE11) and `lan0` (SLE12):

    First network device is used when DHCP in built image is enabled.


# ENVIRONMENT

  * `MACHINERY_LOG_FILE`:

    Location of Machinery's log file (defaults to `~/.machinery/machinery.log`)


# COPYRIGHT

Copyright \(c) 2013-2016 [SUSE LLC](http://www.suse.com)
