# Machinery Contribution Guidelines

Machinery is an open project and welcomes contributions. We have written these
guidelines so you know how the project works, and to make contributions smooth
and fun for everybody involved.

There are two main forms of contribution: reporting bugs and performing code
changes.

## Bug Reports

If you find a problem with Machinery, report it using [GitHub
issues](https://github.com/SUSE/machinery/issues/new). When creating a bug
report, make sure you include:

  1. Steps to reproduce the bug
  2. What you expected to happen
  3. What happened instead

This information will help to determine the cause and prepare a fix as fast as
possible.

## Code Changes

Code contributions come in various forms and sizes, from simple bug fixes to
significant refactorings and implementation of new features. Before making any
non-trivial change, get in touch with Machinery developers first. This can
prevent wasted effort later.

To send your code change, use GitHub pull requests. The workflow is as follows:

  1. Fork the project.

  2. Create a topic branch based on `master`.

  3. Implement your change, including tests and documentation.  Make sure you
     adhere to the [Ruby style
     guide](https://github.com/SUSE/style-guides/blob/master/Ruby.md).

  4. Run tests using `rake spec` to make sure your change didn't break anything.

  5. Publish the branch and create a pull request.

  6. Machinery developers will review your change and possibly point out issues.
     Adapt the code under their guidance until all issues are resolved.

  7. Finally, the pull request will get merged or rejected.

See also [GitHub's guide on
contributing](https://help.github.com/articles/fork-a-repo).

If you want to do multiple unrelated changes, use separate branches and pull
requests.

### Commits

Each commit in the pull request should do only one thing, which is clearly
described by its commit message. Especially avoid mixing formatting changes and
functional changes into one commit. When writing commit messages, adhere to
[widely used
conventions](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

When the commit fixes a bug, put a message in the body of the commit message
pointing to the number of the issue (e.g. "Fixes #123").

### Pull requests and branches

All work happens in branches. The master branch is only used as target for pull
requests.

During code review you often need to update pull requests. Usually you do that
by pushing additional commits.

In some cases where the commit history of a pull request gets too cumbersome to
review or you need bigger changes in the way you approach a problem which needs
changing of commits you already did it's more practical to create a new pull
request. This new pull request often will contain squashed versions of the
previous pull request. Use that to clarify the changes contained in a pull
request and to make review easier.

When you replace a pull request by another one, add a message in the
description of the new pull request on GitHub referencing the pull request it
replaces (e.g. "Supersedes #123").

Never force push commits. This changes history, can lead to data loss, and
causes trouble for people who have checked out the changes which are overwritten
by a force push. Don't waste time with thinking about if the force push in this
one particular case would be ok, just don't do it.

# Additional Information

If you have any question, feel free to open an issue on our
[GitHub page](https://github.com/SUSE/machinery/issues).
