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
project. The RPM bundles the gems it needs as well as the helper binary, so that
there is one self-contained package, which can be easily installed, and doesn't
expose any dependencies to the user.
