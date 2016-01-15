
## export-kiwi — Export System Description as KIWI Image Description

### SYNOPSIS

`machinery export-kiwi` -k | --kiwi-dir NAME
   --force

`machinery` help export-kiwi


### DESCRIPTION

The `export-kiwi` subcommand exports a stored system description as a KIWI
image description.


### ARGUMENTS

  * `NAME` (required):
    Name of the system description.


### OPTIONS

  * `-k KIWI_DIR`, `--kiwi-dir=KIWI_DIR` (required):
    Write the KIWI image description to a subdirectory at the specified directory. The directory
    will be created if it does not exist yet.

  * `--force` (optional):
    Overwrite existing system description


### EXAMPLES

 * Export the `myhost` system description to `/tmp/myhost-kiwi`:

   $ `machinery` export-kiwi myhost --kiwi-dir=/tmp
