# Integration Test Setup

To allow testing as close to the user environment as possible we are building an rpm package of the current git tree and use that as a base for the integration tests.

The actual tests are run in virtual machines which are set up by [Pennyworth](https://github.com/SUSE/pennyworth/).

## Requirements

### Pennyworth

Pennyworth is set up as described in its [README](https://github.com/SUSE/pennyworth/blob/master/README.md#installation).

After setting up Pennyworth the vms need to be built by running `<pennyworth-git-tree/bin/pennyworth build-base --definitions-dir=<machinery-git-tree>/spec/definitions/`.

This step takes quite some time since the openSUSE 13.1 DVD is downloaded and vms are installed.

### Machinery

All gems are installed by running `bundle` in the machinery git tree.

### OBS

Our packages are build and published via the [openSUSE Build Service](https://build.opensuse.org/). To run integration tests an openSUSE Build Service account and the openSUSE Build Service Commander package `osc` are needed.

The osc configuration is stored in the file `~/.oscrc`. It is created the first time osc is used to build a package. The minimal configuration to allow building packages for integration tests is as follow:

```
[general]
apiurl = https://api.opensuse.org

[https://api.opensuse.org]
user = <obs-username>
pass = <obs-password>
trusted_prj=openSUSE:13.1
```

If osc was already used before the only important part is the addition of `openSUSE:13.1` to `trusted_prj`. Each time osc builds packages against an unknown repository it asks if it should trust this project.

Since this question can't be confirmed in the build script `openSUSE:13.1` needs to be added manually if the repository wasn't used before. The separation char for `trusted_prj` is a space.

The configuration can be tested by running `rake rpm:build` in the git tree.

## Start

The actual integration tests can be run by calling `rspec spec/integration` in the machinery git tree.

## Links

[Pennyworth](https://github.com/SUSE/pennyworth/)

[openSUSE Build Service](https://build.opensuse.org/)

[Packing Tasks Gem](https://github.com/openSUSE/packaging_tasks/)
