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

Machinery runs on most Linux distributions. Install it by following one of these methods:

* via the one click installer on [Machinery's homepage](http://machinery-project.org) (for openSUSE systems)
* [on the command line](https://github.com/SUSE/machinery/wiki/Installation-on-SUSE-Distributions) with zypper on all SUSE distributions
* [as a Ruby gem](https://github.com/SUSE/machinery/wiki/Installation-on-Other-Distributions) on all distributions which have the gem tool
* [from sources](#development)

## Usage

Machinery is a command-line tool. You can invoke it using the `bin/machinery`
command. It accepts subcommands (similarly to `git` or `bundle`).

To display a short overview of available commands and their descriptions, use
the `help` command:

    $ machinery help

For more information about the commands, see
[Machinery Documentation](http://machinery-project.org/docs).

## Documentation
* [User Documentation](http://machinery-project.org/docs)
* [Developer Documentation](https://github.com/SUSE/machinery/tree/master/docs)

## Development

The following steps are only recommended if you want to build Machinery from
sources, work on the codebase or test the latest development changes. For other
distributions than SUSE look also
[here](https://github.com/SUSE/machinery/wiki/Installation-on-Other-Distributions).

  1. **Install Git**

         $ sudo zypper in git

  2. **Install basic Ruby environment**

         $ sudo zypper in ruby rubygem-bundler

     After the installation, make sure that your ruby version is at least
     `2.0.0.p247-3.11.1`:

         $ ruby -v

     With lower versions, `bundle install` won't work because of a
     [bug](https://bugzilla.novell.com/show_bug.cgi?id=858100).

  3. **Install Machinery's dependencies**

     Install packages needed to compile Gems with native extensions:

         $ sudo zypper in gcc-c++ make patch ruby-devel libxslt-devel libxml2-devel libvirt-devel

     Install Go in order to compile the machinery-helper:

         $ sudo zypper in go

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

If you have any question, feel free to open an issue on our
[GitHub page](https://github.com/SUSE/machinery/issues).
