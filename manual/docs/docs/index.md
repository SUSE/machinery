# Machinery Documentation

Welcome! The Machinary documentation is a reference aimed at system administrators.
It will give you an overview of Machinery itself, its subcommands, and usage examples.

# What is Machinery?

Machinery is a systems management toolkit for Linux. It supports configuration
discovery, system validation, and service migration. Machinery is based on the
idea of a universal system description. Machinery has a set of commands which
work with this system description. These commands can be combined to form work
flows. Machinery is targeted at the system administrator of the data center.

# Work Flow Examples

## Inspect a System and Show Results
  - `machinery inspect --extract-files --name=NAME HOSTNAME`
  - `machinery show NAME`

## Export System Description as HTML

  - `machinery export-html --html-dir=tmp NAME`

## Inspect Two Systems and Compare Them
  - `machinery inspect HOSTNAME1`
  - `machinery inspect HOSTNAME2`
  - `machinery compare HOSTNAME1 HOSTNAME2`

## Fully Inspect a System and Export a Kiwi Description
  - `machinery inspect --extract-files HOSTNAME`
  - `machinery export-kiwi --kiwi-dir=~/kiwi HOSTNAME`

## Fully Inspect a System and Export an AutoYaST Profile
  - `machinery inspect --extract-files HOSTNAME`
  - `machinery export-autoyast --autoyast-dir=~/autoyast HOSTNAME`

## Fully Inspect a System and Deploy a Replicate to the Cloud
  - `machinery inspect --extract-files HOSTNAME`
  - `machinery deploy --cloud-config=~/openrc.sh HOSTNAME`

## How to upgrade a SLES 11 SP3 system to SLES 12
  - Machinery can help you to upgrade without affecting the original system.
    For more details please read the Wiki Page: [How to upgrade a SLES 11 SP3 system to SLES 12](https://github.com/SUSE/machinery/wiki/How-to-upgrade-a-SLES-11-SP3-system-to-SLES-12).

For a more detailed overview see [General Overview](machinery_main_general.1.md).
