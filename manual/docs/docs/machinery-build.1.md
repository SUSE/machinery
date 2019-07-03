# build — Build Image from System Description

## Synopsis

`machinery build` NAME -i IMAGE-DIR | --image-dir=IMAGE-DIR

`machinery` help build

## Description

The `build` command builds an image from a system description. The image is a
system image in the qcow2 format, which can be used with the KVM hypervisor.
It can be run locally or deployed to a cloud environment.

`machinery` uses the image building command line tool
[KIWI](http://opensuse.github.io/kiwi/) to perform the actual build. KIWI
data is stored to a temporary directory and cleaned up after the build. The KIWI
log is shown as output of the `build` command format for showing progress and
diagnosing errors.

When building an image, Machinery filters out some files which would break the
built image. The list of filters is shown at the beginning of the build.

## Arguments

  * `NAME` (required):
    Use specified system description.

## Options

  * `-i IMAGE-DIR`, `--image-dir=IMAGE-DIR` (required):
    Save image file under specified path.

  * `-d`, `--enable-dhcp` (optional):
    Enable DHCP client on first network card of built image

  * `-s`, `--enable-ssh` (optional):
    Enable SSH service in built image

## Prerequisites

  * The `build` command requires the packages `kiwi` and `kiwi-desc-vmxboot`.

  * The necessary vmxboot template for the machinery being built must be
    installed (i.e. if you want to build an openSUSE Leap machine then the
    template `/usr/share/kiwi/image/vmxboot/suse-leap42.1` is required)

  * All repositories in the system description must be accessible from the
    build machine on which `machinery build` is called.

  * Machinery can only build x86_64 images on x86_64 systems at the moment.

## Examples

 * To build an image from the system description named "tux" and to save the
   image under the `/tmp/tux/` directory:

    $ `machinery` build tux -i /tmp/tux/
