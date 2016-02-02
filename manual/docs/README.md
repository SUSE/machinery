# Styleguide for Machinery Documentation

This guide provides answers to writing and style questions commonly arising when editing the
documentation.
The following rules are intentionally kept concise. Refer to our [SUSE Styleguide][1] for more information.


## Audience

Our main audience for the documentation are system administrators. Adjust tone, style, and
technicality of the text based on the intended audience.


## Physical Structure

The documentation is written in Markdown and contains:

* a "main" file `machinery_main_general.1.md` which consists of an overview of the machinery command,
  its global options and a brief description of all subcommands, and

* its subcommands, stored in separate files each named `machinery-SUBCOMMAND.1.md`.

* Scopes are described in the `documentation` attribute in `plugins/SCOPENAME/SCOPENAME.yml`


**Tip:** To create a file for your subcommand, copy the `subcommand-template.1.md` template to
`machinery-SUBCOMMAND.1.md` and edit the latter.


## Logical Structure

The structure of each subcommand contains:

* the title

  Use the following format:

        ## SUBCOMMAND—Short Description

* a section "SYNOPSIS"

  Contains the output of `machinery SUBCOMMAND --help` or `machinery help SUBCOMMAND`.
  Use square brackets for options which are optional.

* a section "DESCRIPTION"

  Summarize the purpose of the subcommand in a short, first paragraph. Leave an
  empty line, and then describe what the command does, what its output is, and
  which interaction may be needed.

* a section "OPTIONS"

  List all options. Use a separate list item for each option and wrap short and
  long option name in back ticks. State if the option is mandatory or optional
  as in this example:

       * `-n`, `--name=NAME` (optional):
         Save system description under the specified name

  Capitalize any placeholders.

* a section "PREREQUISITES"

  List all the necessary topics, items, or other conditions that the user have
  to be fulfilled beforehand the subcommand can be executed.

* a section "DEPENDENCIES"

  List only those dependencies which cannot be expressed as package dependencies.
  Package dependencies are automatically resolved when the `machinery` package is installed.

* a section "EXAMPLES"

  Provide at least two meaningful examples of how to use the subcommand.
  Start with the most common or easy one and explain what it does. Include also a more unusual or difficult
  example. Use the following style:

        * Short description:

          machinery SUBCOMMAND --opt1 ...


## Level of Detail

The Machinery documentation is mainly a reference: an overview of Machinery itself, its
subcommands, and usage examples.

Keep the documentation concise. Avoid describing implementing details. Focus on
what the user can do with a subcommand, what information it gathers, and its results.

For example, it is unimportant whether a subcommand uses `rpm`, `zypper`, or anything else
to retrieve a package list. In that case, it is enough to mention that Machinery gets this list
somehow and focus on what it does with this information.


## Language

For language and spelling rules, refer to our [SUSE Styleguide, section "Language"][1] which covers most of your
questions already.

If you are unsure about spelling, go to the [Merriam Webster][20] homepage or consult our [SUSE Terminology][3].


## Consistency Hints

* Be consistent. For example, if you explain the `--name` option and start your description with a verb,
  do so for the other options as well.

* Distinguish between the Machinery project (with capital 'M', without any markup) and the command line tool
  `machinery` (lower case, written with back ticks and displayed in a monospace font). Always be clear in your
  text what you are referring to.

* Use back ticks for the `machinery` command, its subcommands, options, and placeholders:

      `machinery`

* Write in full sentences, even in lists.

* Capitalize placeholders, for example, `machinery show NAME`.


[1]: http://doc.opensuse.org/products/opensuse/Styleguide/opensuse_documentation_styleguide_sd/#sec.language       "SUSE Styleguide: Language"
[2]: http://doc.opensuse.org/products/opensuse/Styleguide/opensuse_documentation_styleguide_sd/#sec.capitalization "SUSE Styleguide: Capitalization and Title Style"
[3]: http://doc.opensuse.org/products/opensuse/Styleguide/opensuse_documentation_styleguide_sd/#sec.terminology    "SUSE Styleguide: Terminology"

[10]: http://www.chicagomanualofstyle.org "The Chicago Manual of Style, 15th Edition"

[20]: http://www.m-w.com/                 "Merriam Webster"
