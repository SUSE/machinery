* os

Contains information about the operating system, name, version, and
architecture of the inspected system.

* packages

Contains information on all installed RPM packages installed on the
inspected system.

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

* users

Contains information about the system users including user and group ids,
login information, such as password hashes and - if available - additional
password properties.

* groups

Contains information about the system groups such as group attributes and the
list of group members.

* services

Services are applications running in the background doing continuous work
or waiting for requests to do work.
The scope determines which services are configured to be started in which
runlevel. It uses the `chkconfig` command to obtain that information.
The xinetd services that are also displayed by `chkconfig` are switched
on/off by editing config files and are ignored in this context.

* config_files

Contains all configuration files which have been changed since they were
installed.
Configuration files are all those files which are marked as such in the
package which has installed them. A configuration file change is reported
if its content or its attributes like Linux permission bits or ownership
have changed.

* changed_managed_files

Contains the names and contents of all non-configuration files which have
been changed compared to the files in the package. A file change is reported
if its content or its attributes like Linux permission bits or ownership
have changed.

* unmanaged_files

Contains the names and contents of all files which are not part of any RPM
package. The list of unmanaged files contains only plain files and
directories. Special files like device nodes, named pipes and Unix domain
sockets are ignored. The directories `/tmp`,  `/var/tmp`, `/.snapshots/`,
`/var/run` and special mounts like procfs and sysfs are ignored, too.
If a directory is in this list, no file or directory below it belongs to a
RPM package.

Meta data information of unmanaged files is only available if the files were
extracted during inspection.

Using the `--extract-unmanaged-files` option, the files are transferred from
the system and stored in the system description. Depending on the content of
the inspected system, the amount of data stored may be huge.


