# README for Kiwi export from Machinery

This directory contains a Kiwi configuration that was exported by
Machinery.

The user is expected to be familiar with using Kiwi, otherwise
`machinery build` is recommended.
Details on Kiwi can be found at http://opensuse.github.com/kiwi


## Creating the image

The following command builds the image:

`sudo /usr/sbin/kiwi --build EXPORTED_DIRECTORY --destdir OUTPUT_DIRECTORY`


For example if the exported kiwi description is stored under "/tmp/export"
and the image should be saved under "/tmp/image" the command would look like
this:

`sudo /usr/sbin/kiwi --build  /tmp/export --destdir /tmp/image`
