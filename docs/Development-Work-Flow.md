# Machinery Development Work Flow

Machinery is an open source project, so we follow a typical open source
development work flow. We welcome contributions and usually follow the rule
that those who do the work decide. We do have some fundamental rules and
expectations about how development works. This document outlines these as a base
for collaboration on Machinery.

## Contributions

Contributions are everything which goes into the
[Machinery Git repository](http://github.com/SUSE/machinery). This
is primarily code, but we also keep documentation there and some supplemental
material such as the web site.

## Maintainers

Machinery is maintained by a team at [SUSE](http://suse.com). This is the group
which has commit access to the Git repository and which has the final say about
what goes in there. We take the role of maintainers with responsibility. It
includes deciding about contributions, but it's just as well about contributing
and helping others to contribute.

## Code Review

We follow a strict code review model. Everything which goes into the master
branch has to be reviewed first. We use
[GitHub pull requests](https://github.com/SUSE/machinery/pulls) for doing this.
One maintainer has to approve a pull request before it gets merged. If the pull
request is written by a maintainer, another maintainer has to approve.

## Expectations

We follow an agile model, which means we release continuously in short iterations
and deliver value as soon as we can. The master branch is supposed to always
have production quality. This means code going in needs to be fully implemented,
tested, and documented. There are a number of documents, which describe
expectations on contributions in more detail:

* [Code Style Guide](https://github.com/SUSE/style-guides/blob/master/Ruby.md)
* [Commit Guidelines](https://github.com/SUSE/machinery/wiki/Commit-Guidelines)
* [Contribution Guidelines](https://github.com/SUSE/machinery/blob/master/CONTRIBUTING.md)

## Releases

Machinery is released early and often. Releases come as tag in Git,
corresponding tarball on the [release page](https://github.com/SUSE/machinery/releases),
and a package in the
[openSUSE Build Service](https://build.opensuse.org/project/show/systemsmanagement:machinery).

The version of our release is [defined in the sources](https://github.com/SUSE/machinery/blob/master/lib/version.rb).
It follows the [Semantic Versioning Scheme](http://semver.org/). The version has
the format MAJOR.MINOR.PATCH.

The MAJOR version is increased, when we make incompatible changes to the API. We
consider the command line interface and the ability to read data which has been
written by a version of Machinery as our API. While we are at MAJOR version 0 we
don't make any guarantees.

The MINOR version is increased, when we add features while keeping the API
compatible.

The PATCH version is increased, if the release only contains bug fixes, which
keep backward compatibility.

## Changelog

All releases come with a [changelog](https://github.com/SUSE/machinery/blob/master/NEWS)
which is part of the code. We try to keep track of major changes in the log.

## Bug Reports

Bugs are tracked in the [Machinery Issue Tracker](https://github.com/SUSE/machinery/issues).
If you are using Machinery and find a bug, please report it there. If you have
feature request, plese report them there as well.

We try to keep references in the commits to bugs closed and features
implemented, so it's clear when things are done and released.

## SUSE Internal Work

There is a team at SUSE which is working on Machinery. We try to do as much as
possible in the open. All code goes through the
[public patch review workflow](https://github.com/SUSE/machinery/pulls)
into the [public repository](http://github.com/SUSE/machinery). We have a
[public mailing list](machinery@lists.suse.com) to discuss everything
Machinery.

That said, we do use the privilege of sitting together in the same office and
sometimes there are things we can't discuss publicly. But we try hard to not let
this get in the way of developing in the open. The results of all the work we do
at SUSE should be visible and reasonable to those of you who are not part of the
internal team.

The team internally uses Scrum. We have some internal board to track the work
the team does. What goes on this board as backlog depends on input from many
sources. Contributions and issues reported on the Machinery project are part of
that. When we track something internally, we add a label on GitHub "tracked by
SUSE" to make it transparent that the SUSE team is having a special eye on it.

We also have an internal bug tracker where issues found by customers are
tracked. Sometimes we refer to them in commits. These references show up as
something like `bnc#123456`. All information, which is relevant to the code
will be in the commit message, so just ignore these references, if you don't
have access to them.

If you have the feeling that something is not transparent enough or is getting
in the way of contributing, please let us know, and we'll try to find a good
solution.
