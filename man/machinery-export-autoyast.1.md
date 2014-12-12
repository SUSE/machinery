
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


### SYSTEM REGISTRATION

  * To register a SLES 12 system automatically with AutoYaST, it is required to
    edit the generated profile. The following example registers the system with
    the SUSE Customer Center.

    ```xml
    <suse_register>
      <do_registration config:type="boolean">true</do_registration>
      <email>tux@example.com</email>
      <reg_code>MY_SECRET_REGCODE</reg_code>
      <install_updates config:type="boolean">true</install_updates>
      <slp_discovery config:type="boolean">false</slp_discovery>
    </suse_register>
    ```
  * More information can be found at the SUSE AutoYaST documentaion.
    https://www.suse.com/documentation/sles-12/singlehtml/book_autoyast/book_autoyast.html


### EXAMPLES

 * Export the `myhost` system description to `/tmp/export`:

   $ `machinery` export-autoyast myhost --autoyast-dir=/tmp/export
