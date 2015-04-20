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
