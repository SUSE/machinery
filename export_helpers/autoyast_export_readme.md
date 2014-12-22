# README for AutoYaST export from Machinery

This directory contains an AutoYaST configuration that was exported by
Machinery.

The user is expected to be familiar with using AutoYaST.

## Using the AutoYaST export

The export directory contains both the AutoYaST profile and additional data that
is required during installation. This directory needs to be made available to
the installer via network, e.g. by running:

  cd /path/to/autoyast_export; python -m SimpleHTTPServer

You can then point the installer to the profile by specifying the AutoYaST
option on the kernel command line.

For SLES12 and openSUSE 13.2:

  autoyast2=http://192.168.121.1:8000/autoinst.xml

For SLES11:

  autoyast=http://192.168.121.1:8000/autoinst.xml netsetup=dhcp

## Changing permissions of the AutoYaST export

By default the AutoYaST export is only accessible by the user. This is also the
case for all sub directories.

The installation via for example an HTTP server is only possible if all files
and sub directories are readable by the HTTP server user.
To make the export directory readable for all users run:

  chmod -R a+rX /path/to/autoyast_export
