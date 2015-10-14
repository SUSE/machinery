# Machinery inspection concept

This document describes the concept of inspecting systems in Machinery. System
inspection is one of the central features of Machinery. It gathers all data
about a given system and stores it in a description. The description can then be
used for a variety of use cases, including display, archive, export to other
formats, and more. Inspection is implemented as the `machinery inspect` command.

## Access to inspected system

To gather data Machinery executes a number of commands on the inspected system,
collects and processes the results, and stores them in the format of a system
description on the local system, where Machinery is executed.

Usually the inspected system will be different from the system where Machinery
is running. Machinery will use ssh to access the remote system. For the special
case where the inspected system is the local system where Machinery is run, the
same commands will be executed locally, not via ssh.

## Privileges

Machinery is usually run by a regular user. A remote inspection does not
require root rights on the system where Machinery is run.

On the inspected system root rights are required for some commands which access
data, which is not accessible by a regular user.

Machinery supports two modes how to execute commands on a remote system with
root privileges. The default mode is to log in as root via ssh. So the root
account needs to be configured to be accessed by the user who runs Machinery.
This is done by copying the public ssh key of the Machinery user to the root
account of the inspected system. Machinery requires a password-less login to the
remote machine, which can be achieved by using ssh-agent.

The other mode uses a non-root user on the remote machine, which is configured
to be able to execute specific commands with root privileges via sudo. The
exact sudo configuration is documented in the Machinery man page. Which user is
used to log in to the remote system is specified by a command line option in
Machinery.

For the case of inspecting the local system Machinery requires to be run as
root.

The system description stored on the local system where Machinery is run
contains all files of the inspected system, which are not part of RPMs. This
does include files, which only are accessible to root on the inspected system,
which might include sensitive data. So the permission of the local system
description are set in a way that only the user running Machinery can access
them.

## Inspection using system commands

The traditional way how Machinery does inspections is only using basic system
commands, which are present on even minimal systems, such as `find`, `cat`,
`tar`, `rpm`. The output is processed and turned into a system description.

## Inspection using the Machinery helper

For some parts of the inspection Machinery now uses a new method of gathering
the inspected data. It uses a helper binary, which is temporarily copied to the
target system for the duration of the inspection. This helper is a
self-contained binary without external dependencies. It does the gathering of
information and most of the processing on the inspected machine and then returns
the result to Machinery.

There is a helper binary which is bundled with the Machinery package and is installed
to `<machinery-installation-path>/machinery-helper/machinery-helper`.
`<machinery-installation-path>` is the directory where all the Machinery gem files
are installed.
On the target system it is copied to the home directory of the root user. It is
removed when the inspection is done.

The helper is only used, when Machinery logs into the inspected machine as root
user. For the mode, where it logs in as a non-root user Machinery falls back to
the traditional inspection.

In the future we might support installation of the helper binary as RPM on the
target machine by the system administrator. Then the temporary copying of the
binary is not necessary anymore. It also would allow to let the non-root mode
use the binary with a simplified sudo configuration, which only would require
root privileges for the binary and no system tools anymore.
