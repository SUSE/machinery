# Machinery

[![Code Climate](https://codeclimate.com/github/SUSE/machinery/badges/gpa.svg)](https://codeclimate.com/github/SUSE/machinery)
[![Test Coverage](https://codeclimate.com/github/SUSE/machinery/badges/coverage.svg)](https://codeclimate.com/github/SUSE/machinery/coverage)
[![Gem Version](https://badge.fury.io/rb/machinery-tool.svg)](http://badge.fury.io/rb/machinery-tool)

Machinery is a systems management toolkit for Linux. It supports configuration
discovery, system validation, and service migration. It's based on the idea of a
universal system description.

A spin-off project of Machinery is
[Pennyworth](https://github.com/SUSE/pennyworth), which is used to manage the
integration test environment.

For more information, [visit our website](http://machinery-project.org/).

## Contents

  * [Installation](#installation)
  * [Usage](#usage)
  * [Documentation](#documentation)
  * [Development](#development)
  * [Contact](#contact)

## Installation

Machinery is tested and supported on [openSUSE13.1](http://en.opensuse.org/Portal:13.1)
and SLES 12. It is also supported on [openSUSE13.2](http://en.opensuse.org/Portal:13.2).
It will not run on other openSUSE versions. Machinery can also be installed on other
Linux Distributions. Please refer to our
[Quick Start Guide](https://github.com/SUSE/machinery/wiki/Quick-Start-Guide) if you want
to know, how you can install Machinery on SUSE or Non-SUSE Distributions.

The easiest way to install Machinery is as an RPM from our
[homepage](http://machinery-project.org) with
the one-click-installer.

## Usage

Machinery is a command-line tool. You can invoke it using the `bin/machinery`
command. It accepts subcommands (similarly to `git` or `bundle`).

To display a short overview of available commands and their descriptions, use
the `help` command:

    $ machinery help

For more information about the commands, see
[Machinery man page](http://machinery-project.org/manual.html).

## Documentation
* [User Documentation](http://machinery-project.org/manual.html)
* [Developer Documentation](https://github.com/SUSE/machinery/tree/master/docs)

## Development

The following steps are only recommended if you want to work on the Machinery
codebase or test the latest development changes.

  1. **Install Git**

         $ sudo zypper in git

  2. **Install basic Ruby environment**

         $ sudo zypper in ruby rubygem-bundler

     After the installation, make sure that your `ruby20` version is at least
     `2.0.0.p247-3.11.1`:

         $ rpm -q ruby20

     With lower versions, `bundle install` won't work because of a
     [bug](https://bugzilla.novell.com/show_bug.cgi?id=858100).

  3. **Install Machinery's dependencies**

     Install packages needed to compile Gems with native extensions:

         $ sudo zypper in gcc-c++ make ruby-devel libxslt-devel libxml2-devel

  4. **Clone Machinery repository and install Gem dependencies**

         $ git clone git@github.com:SUSE/machinery.git
         $ cd machinery
         $ bundle config build.nokogiri --use-system-libraries
         $ bundle install

  5. **Done!**

     You can now start using Machinery by running `bin/machinery`.
     
  6. **Contribute**
 
     Now that you have Machinery running from git on your machine you are ready to hack. If you would like to get some overview of architecture and design of Machinery have a look at our [Developer Documentation](https://github.com/SUSE/machinery/tree/master/docs).

     We are happy if you share your changes with us as pull requests. Read the [Contribution Guidelines](https://github.com/SUSE/machinery/blob/master/CONTRIBUTING.md#machinery-contribution-guidelines) for details how to do that.

## Contact

You can subscribe to our
[mailing list](http://lists.suse.com/mailman/listinfo/machinery)
([archive](http://lists.suse.com/pipermail/machinery/)) if you would like to
discuss using or contributing to Machinery. If you have any questions or
feedback please feel free to
[send them to the mailing list](mailto:machinery@lists.suse.com) as well.
