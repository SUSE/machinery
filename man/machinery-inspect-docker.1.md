
## inspect-container — Inspect Container

### SYNOPSIS

`machinery inspect-container` [OPTIONS] IMAGENAME

`machinery inspect-container` [OPTIONS] IMAGEID

`machinery` help inspect-container


### DESCRIPTION

The `inspect-container` command inspects a container image. It creates and starts the container from the provided image before inspection
and generates a system description from the gathered data. After the inspection the container will be killed and removed again.
This approach ensures that no containers and images are affected by the inspection.

Right now the container inspection only supports Docker images.

The system data is structured into scopes, controlled by the
`--scope` option.

**Note**:
Machinery will always inspect all specified scopes, and skip scopes which
trigger errors.


### ARGUMENTS

  * `IMAGENAME / IMAGEID` (required):
    The name or id of the image to be inspected. The provided name or id will also be
    used as the name of the stored system description unless another name is
    provided with the `--name` option.


### OPTIONS

  * `-n NAME`, `--name=NAME` (optional):
    Store the system description under the specified name.

  * `-s SCOPE`, `--scope=SCOPE` (optional):
    Inspect image for specified scope.
    See the [Scope section](#Scopes) for more information.

  * `-e SCOPE`, `--exclude-scope=EXCLUDE-SCOPE` (optional):
    Inspect image for all scopes except the specified scope.
    See the [Scope section](#Scopes) for more information.

  * `-x`, `--extract-files` (optional):
    Extract changed configuration and unmanaged files from the inspected container.
    Shortcut for the combination of `--extract-changed-config-files`,
    `--extract-unmanaged-files`, and `--extract-changed-managed-files`

  * `--extract-changed-config-files` (optional):
    Extract changed configuration files from the inspected image.

  * `--extract-unmanaged-files` (optional):
    Extract unmanaged files from the inspected image.

  * `--extract-changed-managed-files` (optional):
    Extract changed managed files from inspected image.

  * `--skip-files` (optional):
    Do not consider given files or directories during inspection. Either provide
    one file or directory name or a list of names separated by commas. You can
    also point to a file which contains a list of files to filter (one per line)
    by adding an '@' before the path, e.g.

      $ `machinery` inspect-container --skip-files=@/path/to/filter_file myimage

    If a filename contains a comma it needs to be escaped, e.g.

      $ `machinery` inspect-container --skip-files=/file\\,with_comma myimage

    **Note**: File or directory names are not expanded, e.g. '../path' is taken
      literally and not expanded.

  * `--verbose` (optional):
    Display the filters which are used during inspection.


### PREREQUISITES

  * Inspecting a container requires an image specified by the name or id.

  * The image to be inspected needs to have the following commands:

    * `rpm` or `dpkg`
    * `zypper`, `yum` or `apt-cache`
    * `rsync`
    * `cat`
    * `sed`
    * `find`

### EXAMPLES

  * Inspect Docker container `myimage` and save system description under name 'MyContainer':

    $ `machinery` inspect-container --name=MyContainer myimage

  * Inspect Docker container `076f46c1bef1` and save system description under name 'MySecondContainer':

    $ `machinery` inspect-container --name=MySecondContainer 076f46c1bef1

  * Extract changed managed files and save them:

    $ `machinery` inspect-container --scope=changed-managed-files --extract-files myimage
