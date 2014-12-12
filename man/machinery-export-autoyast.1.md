
## export-autoyast — Export System Description as AutoYasST profile

### SYNOPSIS

`machinery export-autoyast` -a | --autoyast-dir NAME
   --force

`machinery` help export-autoyast


### DESCRIPTION

The `export-autoyast` subcommand exports a stored system description as a AutoYaST
profile.


### ARGUMENTS

  * `NAME` (required):
    Name of the system description.


### OPTIONS

  * `-a AUTOYAST_DIR`, `--autoyast-dir=AUTOYAST_DIR` (required):
    Write the AutoYaST profile to the specified directory. The directory
    will be created if it does not exist yet.

  * `--force` (optional):
    Overwrite existing system description


### EXAMPLES

 * Export the `myhost` system description to `/tmp/export`:

   $ `machinery` export-autoyast myhost --autoyast-dir=/tmp/export
