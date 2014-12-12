# README for AutoYaST export from Machinery

This directory contains an AutoYaST configuration that was exported by
Machinery.

The user is expected to be familiar with using AutoYaST.

## Using the AutoYaST export

The export directory contains both the AutoYaST profile and additional data that
is required during installation. This directory needs to be made available to
the installer via network, e.g. by running:

  cd /path/to/autoyast_export; python -m SimpleHTTPServer

You can then point the installer to the profile by specifying the "autoyast"
option on the kernel command line:

  autoyast=http://192.168.121.1:8000/autoinst.xml

In the installer you will be prompted to enter the URL to the system
description, which in this case would be

  http://192.168.121.1:8000
