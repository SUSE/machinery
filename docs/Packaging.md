# Packaging

For installation on user's machines Machinery is packaged as gem and as RPM. The
RPMs are available for SUSE distributions, the gem should be installable on all
systems, which have Ruby installed.

The gem is published on RubyGems as
[machinery-tool](https://rubygems.org/gems/machinery-tool). It includes the
sources of the machinery helper, which are compiled on installation of the gem
if there is a Go toolchain available.

The RPM is maintained in the Open Build Service in the
[systemsmamnagement:machinery](https://build.opensuse.org/project/show/systemsmanagement:machinery)
project. The RPM bundles the required gems as well as the helper binary, so that
there is one self-contained package, which can be easily installed, and doesn't
expose any dependencies to the user.

## Gem Scopes

When you install machinery as a gem, machinery-tool and all it's dependencies
will be installed together inside the same directory where your other gems are
installed (the exact location will vary depending on your setup).

If you install machinery as an RPM package the encapsulation works a little bit
differently. The gem machinery-tool, as expected, will be installed inside the
same directory where your system's gems are installed but machinery's
dependencies will be bundled under the machinery-tool directory.

In both cases if you have a newer version of one or more of machinery's required
gems while running machinery the newer versions will be used if they meet the
specified criteria in the machinery.gemset file. This is the expected
functionality by Rubygems and should not break any functionality.

Sometimes you might get a warning from a gem like Nokogiri telling you that the
gem was built with a different library version than the one installed in your
system. This warning also should not break any functionality but if you want to
get rid of the message you will have to upgrade/downgrade to the same library
version that machinery is using (the number will be specified in the warning
message).
