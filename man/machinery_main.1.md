# Machinery — A Systems Management Toolkit for Linux
<!--

General procedure:

1. Add the short description of a new command into the COMMANDS section
2. Copy the subcommand-template.1.md to machinery-SUBCOMMAND.1.md
3. Insert your description in your machinery-SUBCOMMAND.1.md file

-->


## SYNOPSIS

`machinery` SUBCOMMAND \[options\] <br>
`machinery` help [SUBCOMMAND]


## DESCRIPTION

Machinery is a systems management toolkit for Linux. It supports configuration
discovery, system validation, and service migration. Machinery is based on the
idea of an universal system description. Machinery has a set of commands which
work with this system description. These commands can be combined to form work
flows. Machinery is targeted at the system administrator of the data center.


## WORK FLOW EXAMPLES

### GET DESCRIPTIONS
* Inspect a system completely: `machinery inspect --extract-files HOSTNAME`
* Inspect and don't use HOSTNAME as name: `machinery inspect --extract-files --name DESCRIPTION HOSTNAME
* Inspect only the packages of a system: `machinery inspect --scope=packages HOSTNAME`

### SHOW DESCRIPTIONS
* Show the description in console: `machinery show DESCRIPTION`
* Show only the packages: `machinery show --scope packages DESCRIPTION`
* Show the description as HTML in webbrowser: `machinery show --html DESCRIPTION`
* Compare descriptions: `machinery compare DESCRIPTION1 DESCRIPTION2`

### MANAGE DESCRIPTIONS
* Create a description copy: `machinery copy DESCRIPTION1 DESCRIPTION2`
* List all descriptions: `machinery list`
* Remove description: `machinery remove DESCRIPTION`

### EXTEND DESCRIPTIONS

* Create diffs of changed config files: `machinery analyze --operation=config-file-diffs DESCRIPTION`
* Show diffs of changed config files: `machinery show --show-diffs DESCRIPTION`

### CREATE IMAGES
* Export description for KIWI: `machinery export-kiwi --kiwi-dir=~/kiwi`
* Build image: `machinery build --image-dir=~/ DESCRIPTION`
* Build and deploy image: `machinery deploy --cloud-config=~/openrc.sh DESCRIPTION`


## CONCEPTUAL OVERVIEW

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

### The machinery Command

Machinery is implemented as a command line tool named `machinery`. The
`machinery` command has several subcommands for specific tasks. All
subcommands work with the same system description identified by an optional
name which can be used by all subcommands.


### Scopes

The system description is structured into "scopes". A scope covers a specific
part of the configuration of the inspected system such as installed packages,
repositories, or configuration files.

For example, if you are only interested in the installed packages, limit the
scope to `packages`. This will output only the requested information.

Machinery supports the following scopes:

* os

  Contains information about the operating system, name, version, and
  architecture of the inspected system.

* packages

  Contains information on all installed RPM packages installed on the
  inspected system.

* config-files

  Contains all configuration files which have been changed since they were
  installed.
  Configuration files are all those files which are marked as such in the
  package which has installed them. A configuration file is considered changed
  if either its content or its Linux permission bits have changed.

* unmanaged-files

  Contains the names and contents of all files which are not part of any RPM
  package. The list of unmanaged files contains only plain files and
  directories. Special files like device nodes, named pipes and Unix domain
  sockets are ignored. The directories `/tmp`,  `/var/tmp`, `/sys`, `/dev`,
  `/.snapshots/`, and `/var/run` are ignored, too. Content of directories
  mounted from remote file systems like nfs or cifs are also ignored.

  Meta data information of unmanaged files is only available if the files were
  extracted during inspection.

  Using the `--extract-unmanaged-files` option, the files are transferred from
  the system and stored in the system description. Depending on the content of
  the inspected system, the amount of data stored may be huge.

* changed-managed-files

  Contains the names and contents of all non-configuration files which have
  been changed compared to the files in the package.

* patterns

  Contains all patterns installed on the inspected system. A pattern is a
  collection of software packages.
  The meaning of software patterns depends on the package manager of the
  distribution. Therefore, the pattern scope on SUSE based systems uses the
  `zypper` command to obtain the information about installed pattern names.

* repositories

  Contains all information about software repositories configured on the
  inspected system. The information about repositories depends on the package
  manager of the distribution. Thus on SUSE-based systems the `zypper` command
  is used. Machinery collects the following information from each configured repository:

  - The alias name of the repository.

  - The repository type, rpm-md and YaST types that are used on SUSE systems.

  - The path to the repository. This could be a local path, a remote location,
    a device, or a file.

  - A boolean flag that indicates if this repository is in use or not.

  - A boolean flag that indicates if this repository should update the locally
    stored metadata files with metadata files from the origin automatically or
    not.

  - A boolean flag that indicates if packages which would be installed from
    this repository should be checked by their gpg key or not.

  - A numeric value for a priority. The priority of a repository is compared
    to the priorities of all other activated repositories. Values can
    range from 1 (highest) to 99 (lowest, default).

* services

  Services are applications running in the background doing continuous work
  or waiting for requests to do work.
  The scope determines which services are configured to be started in which
  runlevel. It uses the `chkconfig` command to obtain that information.
  The xinetd services that are also displayed by `chkconfig` are switched
  on/off by editing config files and are ignored in this context.

* users

  Contains information about the system users including user and group ids,
  login information, such as password hashes and - if available - additional
  password properties.

* groups

  Contains information about the system groups such as group attributes and the
  list of group members.

### System Description

The System Description format and file structure is documented in the machinery wiki: [https://github.com/SUSE/machinery/wiki/System-Description-Format](https://github.com/SUSE/machinery/wiki/System-Description-Format)



### Use Cases

Some of the important use cases of Machinery are:

* Inspecting a System and Collecting Information

  Collecting a variety of information. Limit the gathered
  information with scopes (see section about scopes). Each inspection step
  updates the system description.

* Reviewing System Description

  After a successful inspection, the system description can be displayed on
  the console or the output can be fed into other tools.

* Cloning a System

  An inspected system can be cloned. The inspection step returns a system
  description which is used as the basis for cloning physical or virtual
  instances. Machinery can build a system image from the description, which
  can then for example be deployed to a cloud.


## OPTIONS FOR ALL SUBCOMMANDS
<!--- These are 'global' options of machinery -->

  * `--version`:
    Displays version of `machinery` tool. Exit when done.

  * `--debug`:
    Enable debug mode. Machinery writes additional information into the log
    file which can be useful to track down problems.
