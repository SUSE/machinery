
## inspect — Inspect Running System

### SYNOPSIS

`machinery inspect` [OPTIONS] HOSTNAME

`machinery` help inspect


### DESCRIPTION

The `inspect` command inspects a running system and generates a system
description from the gathered data.

The system data is structured into scopes, controlled by the
`--scope` option.

**Note**:
Machinery will always inspect all specified scopes, and skip scopes which
trigger errors.


### ARGUMENTS

  * `HOSTNAME` (required):
    The host name of the system to be inspected. The host name will also be
    used as the name of the stored system description unless another name is
    provided with the `--name` option.


### OPTIONS

  * `-n NAME`, `--name=NAME` (optional):
    Store the system description under the specified name.

  * `-s SCOPE`, `--scope=SCOPE` (optional):
    Inspect system for specified scope.
    See the [Scope section](#Scopes) for more information.

  * `-e SCOPE`, `--exclude-scope=EXCLUDE-SCOPE` (optional):
    Inspect system for all scopes except the specified scope.
    See the [Scope section](#Scopes) for more information.

  * `-r USER`, `--remote-user=USER` (optional):
    Defines the user which is used to access the inspected system via SSH.
    This user needs to be allowed to run certain commands using sudo (see
    PREREQUISITES for more information).
    To change the default-user use `machinery config remote-user=USER`

  * `-x`, `--extract-files` (optional):
    Extract changed configuration and unmanaged files from the inspected system.
    Shortcut for the combination of `--extract-changed-config-files`,
    `--extract-unmanaged-files`, and `--extract-changed-managed-files`

  * `--extract-changed-config-files` (optional):
    Extract changed configuration files from the inspected system.

  * `--extract-unmanaged-files` (optional):
    Extract unmanaged files from the inspected system.

  * `--extract-changed-managed-files` (optional):
    Extract changed managed files from inspected system.

  * `--skip-files` (optional):
    Do not consider given files or directories during inspection. Either provide
    one file or directory name or a list of names separated by commas. You can
    also point to a file which contains a list of files to filter (one per line)
    by adding an '@' before the path, e.g.

      $ `machinery` inspect --skip-files=@/path/to/filter_file myhost

    If a filename contains a comma it needs to be escaped, e.g.

      $ `machinery` inspect --skip-files=/file\\,with_comma myhost

    **Note**: File or directory names are not expanded, e.g. '../path' is taken
      literally and not expanded.

  * `--verbose` (optional):
    Display the filters which are used during inspection.


### PREREQUISITES

  * Inspecting a local system requires running `machinery` as root.

  * Inspecting a remote system requires passwordless SSH login as root on the
    inspected system.
    Use `ssh-agent` or asymmetric keys (you can transfer the current SSH key
    via `ssh-copy-id` to the inspected host, e.g.: `ssh-copy-id root@HOSTNAME`)

  * The system to be inspected needs to have the following commands:

    * `rpm`
    * `zypper` or `yum`
    * `rsync`
    * `chkconfig`
    * `cat`
    * `sed`
    * `find`
    * `tar`

  * When inspecting as non-root the user has to have the following command
    whitelist given in the sudoers file:

    machinery ALL=(ALL) NOPASSWD: /usr/bin/find,/usr/bin/cat,/bin/cat,/usr/bin/rsync,/bin/rpm -Va *,/bin/tar --create *,/usr/bin/stat

  * To add a remote `machinery` user run as root:

    # `useradd -m machinery -c "remote user for machinery"`

    To configure a password for the new user run:

    # `passwd machinery`

### EXAMPLES

  * Inspect remote system `myhost` and save system description under name
    'MySystem':

    $ `machinery` inspect --name=MySystem myhost

  * Inspect the installed packages of your local system and save system description
    under the name 'localhost' (you need to become root):

    \# `machinery` inspect --scope="packages" localhost

  * Extracts changed managed files and saves them in the same way as changed
    configuration files are saved:

    $ `machinery` inspect --scope=changed-managed-files --extract-files myhost

  * To inspect the remote system `myhost` with the user `machinery`:

    $ `machinery` inspect --remote-user machinery myhost
