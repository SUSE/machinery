
## System Description

The System Description format and file structure is documented in the machinery
wiki: [https://github.com/SUSE/machinery/wiki/System-Description-Format](https://github.com/SUSE/machinery/wiki/System-Description-Format)

Machinery validates descriptions on load. It checks that the JSON structure of
the manifest file, which contains the primary and meta data of a description, is
correct and it adheres to the schema. Validation errors are reported as warnings.
It also checks that the information about extracted files is consistent. Missing
files or extra files without reference in the manifest are treated also as
warnings. All other issues are errors which need to be fixed so that Machinery
can use the description

To manually validate a description use the `machinery validate` command.


## Use Cases

Some of the important use cases of Machinery are:

* Inspecting a System and Collecting Information

  Collecting a variety of information. Limit the gathered
  information with scopes (see section about scopes). Each inspection step
  updates the system description.

* Reviewing System Description

  After a successful inspection, the system description can be displayed on
  the console or the output can be fed into other tools.

* Cloning a System

  An inspected system can be cloned. The inspection step returns a system
  description which is used as the basis for cloning physical or virtual
  instances. Machinery can build a system image from the description, which
  can then for example be deployed to a cloud.


# OPTIONS FOR ALL SUBCOMMANDS
<!--- These are 'global' options of machinery -->

  * `--version`:
    Displays version of `machinery` tool. Exit when done.

  * `--debug`:
    Enable debug mode. Machinery writes additional information into the log
    file which can be useful to track down problems.
