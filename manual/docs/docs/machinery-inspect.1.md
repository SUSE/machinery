# inspect — Inspect Running System

## Synopsis

`machinery inspect` [OPTIONS] HOSTNAME

`machinery` help inspect

## Description

The `inspect` command inspects a running system and generates a system
description from the gathered data.

The system data is structured into scopes, controlled by the
`--scope` option.

**Note**:
Machinery will always inspect all specified scopes, and skip scopes which
trigger errors.

**Note**:
Tasks on Debian-like systems are treated as patterns.

## Arguments

  * `HOSTNAME` (required):
    The host name of the system to be inspected. The host name will also be
    used as the name of the stored system description unless another name is
    provided with the `--name` option.

## Options

  * `-n NAME`, `--name=NAME` (optional):
    Store the system description under the specified name.

  * `-s SCOPE`, `--scope=SCOPE` (optional):
    Inspect system for specified scope.
    See the [Scope section](machinery_main_scopes.1.md) for more information.

  * `-e SCOPE`, `--ignore-scope=IGNORE-SCOPE` (optional):
    Inspect system for all scopes except the specified scope.
    See the [Scope section](machinery_main_scopes.1.md) for more information.

  * `-r USER`, `--remote-user=USER` (optional):
    Defines the user which is used to access the inspected system via SSH.
    This user needs to be allowed to run certain commands using sudo (see
    Prerequisites for more information).
    To change the default-user use `machinery config remote-user=USER`

  * `-p SSH-PORT`, `--ssh-port SSH-PORT` (optional):
    Specifies the SSH port of the remote SSH server.

  * `-i SSH-IDENTITY-FILE`, `--ssh-identity-file SSH-IDENTITY-FILE` (optional):
    Specifies the SSH private key what should be used to authenticate with the
    remote SSH server. Keys with a passphrase are not allowed here. Use the ssh-agent
    instead.

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

## Prerequisites

  * Inspecting a local system requires running `machinery` as root.

  * Inspecting a remote system requires passwordless SSH login as root on the
    inspected system.
    Use `ssh-agent` or asymmetric keys (you can transfer the current SSH key
    via `ssh-copy-id` to the inspected host, e.g.: `ssh-copy-id root@HOSTNAME`).

  * The system to be inspected needs to have the following commands:

    * `rpm` or `dpkg`
    * `zypper`, `yum`, or `apt-cache`
    * `rsync`
    * `chkconfig`, `initctl`, or `systemctl`
    * `cat`
    * `sed`
    * `find`
    * `tar`

  * When inspecting as non-root the user needs passwordless sudo rights.
    The following entry in the sudoers file would allow the user `machinery`
    to run sudo without password input:

      machinery ALL=(ALL) NOPASSWD: ALL

  * To add a remote `machinery` user run as root:

    \# `useradd` -m machinery -c "remote user for machinery"

    To configure a password for the new user run:

    \# `passwd` machinery

## Examples

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
