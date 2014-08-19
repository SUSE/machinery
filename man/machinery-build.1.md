
## build — Build Image from System Description

### SYNOPSIS

`machinery build` NAME -i IMAGE-DIR | --image-dir=IMAGE-DIR

`machinery` help build


### DESCRIPTION

The `build` command builds an image from a system description. The image is a
system image in the qcow2 format, which can be used with the KVM hypervisor.
It can be run locally or deployed to a cloud environment.

`machinery` uses the image building command line tool
[KIWI](http://en.opensuse.org/Portal:KIWI) to perform the actual build. KIWI
data is stored to a temporary directory and cleaned up after the build. The KIWI
log is shown as output of the `build` command format for showing progress and
diagnosing errors.

When building an image, Machinery filters out some files which would break the
built image. The list of filters is shown at the beginning of the build.


### ARGUMENTS

  * `NAME` (required):
    Use specified system description.


### OPTIONS

  * `-i IMAGE-DIR`, `--image-dir=IMAGE-DIR` (required):
    Save image file under specified path.

  * `-d`, `--enable-dhcp` (optional):
    Enable DHCP client on first network card of built image

  * `-s`, `--enable-ssh` (optional):
    Enable SSH service in built image


### PREREQUISITES

  * The `build` command requires the packages `kiwi` and `kiwi-desc-vmbxoot`.

  * All repositories in the system description must be accessible from the
    build machine on which `machinery build` is called.

### BUILD SUPPORT MATRIX

The following combinations of build hosts and targets are supported:

  * SUSE Linux Enterprise 12

    Can build SUSE Linux Enterprise 12

  * openSUSE 13.1

    Can build SUSE Linux Enterprise 11 and openSUSE 13.1

### EXAMPLES

 * To build an image from the system description named "tux" and to save the
   image under the `/tmp/tux/` directory:

   $ `machinery` build tux -i /tmp/tux/
