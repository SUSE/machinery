# Inspection of yum Repositories

## Use Cases

Inspection of yum repositories is relevant when inspecting Red Hat systems in
several user scenarios.

The primary use case is migration:

* Generating a report of a Red Hat system
* Migrating a Red Hat system to a SUSE system. Generating a report by inspection
  is the first step of a manual work flow to migrate the system.

Secondary use cases, which are relevant as part of the migration:

* Comparing a Red Hat system with a SUSE system

There are more use cases which are out of scope at the moment:

* Deploying Red Hat systems to physical, virtual, or cloud systems
* Building Red Hat images

The focus of the use cases is inspection and display of data from a Red Hat
system, not further processing with Machinery for automatic migration.

When a Red Hat system with yum repositories is inspected we have to consider
two aspects:

* Reading the repository data from the system
* Storing the repository data in the manifest file

## Reading the Repository Data from the System

This section presents different ways of accessing the yum repository data and lists their advantages and disadvantages.

Yum uses variables like `$releasever`, `$basearch` which are expanded by the
yum tools. The yum.conf file (link in the References section) lists the
available variables and explains how they are expanded.

### Parse output of `yum -v repolist all`

Expands yum variables, so the user gets to see the repositories which are
actually used to retrieve packages from.

* Advantages:
  * Lists all repos including the ones from plugins
  * Lists the important repo attributes:
    * Repo-id
    * Repo-name
    * Repo-status
    * Repo-metalink
    * Repo-expire
    * Repo-filename
* Disadvantages:
  * Parsing not trivial (line breaks depend on length of output)
  * Not all repo attributes accessible (e.g. failovermethod, gpgcheck)

### Accessing the python api

Expands variables, so output is similar to using the yum tool, but better
control about how to get data and parse results.

* Advantages:
  * All repos and repo attributes accessible
* Disadvantages:
  * You need to explicitly read attributes. There is no way to get all
    attributes with one API call.

You can find an example script below in the References section.

### Calling `yum-config-manager`

Tool part of yum to see the "raw" configuration data.

* Advantages:
  * Lists all repo attributes (incl. defaults)
* Disadvantages:
  * Hard to parse
  * Disabled repos missing

### Parse yum configuration files

Parse repository list from `/etc/yum.repos.d`, plugin configuration from
`/etc/yum/pluginconf.d/rhnplugin.conf` and `/etc/sysconfig/rhn/up2date` (read by
the yum-rhn-plugin), general configuration from `/etc/yum.conf`.

* Advantages:
  * List all repo attributes stored in configuration files
* Disadvantages:
  * Run-time resolution of configuration is not done, so expansion of variables
    or data retrieved from a server is not captured.


## Storing the repository data in the system description

There are different ways how the repositories can be stored in our data structure. This sections lists
various approaches and their advantages and disadvantages.

### Separate Sub-Sections for zypp and yum

```
"repositories":
 "zypp":
  [
    {
      "alias": "SMT-http_smt_suse_de:SLE11-SDK-SP3-Pool",
      "name": "SMT-http_smt_suse_de:SLE11-SDK-SP3-Pool",
      "type": "rpm-md",
      "url": "http://smt.suse.de/repo/$RCE/SLE11-SDK-SP3-Pool/sle-11-x86_64?credentials=NCCcredentials",
      "enabled": true,
      "autorefresh": false,
      "gpgcheck": true,
      "priority": 99
    },
    {
      "alias": "SMT-http_smt_suse_de:SLE11-SDK-SP3-Updates",
      "name": "SMT-http_smt_suse_de:SLE11-SDK-SP3-Updates",
      "type": "rpm-md",
      "url": "http://smt.suse.de/repo/$RCE/SLE11-SDK-SP3-Updates/sle-11-x86_64?credentials=NCCcredentials",
      "enabled": true,
      "autorefresh": false,
      "gpgcheck": true,
      "priority": 99
    }
  ],
  "yum":
  [
    {
      "repoid": "res6-suse-manager-tools-x86_64",
      "name": "RES6 SUSE-Manager-Tools x86_64",
      "type": "rpm-md",
      "baseurl": "https://manager.suse.de/XMLRPC/GET-REQ/res6-suse-manager-tools-x86_64",
      "enabled": true,
      "gpgcheck": false
    }
  ]
}
```

* Advantages:
  * Keep information which repository is managed by which package manager
  * Captures package manager specific attributes
* Disadvantages:
  * Schema migration needed
  * No common representation, complicates code dealing with repositories in a more abstract way, e.g. for display or comparison


### Flat Data Structure without Schema Change

```
"repositories":
  [
    {
      "alias": "SMT-http_smt_suse_de:SLE11-SDK-SP3-Pool",
      "name": "SMT-http_smt_suse_de:SLE11-SDK-SP3-Pool",
      "type": "rpm-md",
      "url": "http://smt.suse.de/repo/$RCE/SLE11-SDK-SP3-Pool/sle-11-x86_64?credentials=NCCcredentials",
      "enabled": true,
      "autorefresh": false,
      "gpgcheck": true,
      "priority": 99
    },
    {
      "alias": "SMT-http_smt_suse_de:SLE11-SDK-SP3-Updates",
      "name": "SMT-http_smt_suse_de:SLE11-SDK-SP3-Updates",
      "type": "rpm-md",
      "url": "http://smt.suse.de/repo/$RCE/SLE11-SDK-SP3-Updates/sle-11-x86_64?credentials=NCCcredentials",
      "enabled": true,
      "autorefresh": false,
      "gpgcheck": true,
      "priority": 99
    },
    {
      "alias": "res6-suse-manager-tools-x86_64",
      "name": "RES6 SUSE-Manager-Tools x86_64",
      "type": "rpm-md",
      "url": "https://manager.suse.de/XMLRPC/GET-REQ/res6-suse-manager-tools-x86_64",
      "enabled": true
    }
  ]
}
```

This approach uses the existing schema and maps the yum attributes to the
general description also used for zypp.

* Mapping:
  * Repo-id => alias
  * Repo-name => name
  * Repo-status => enabled
  * Repo-metalink => url
  * Repo-expire (ignored)
  * Repo-filename (ignored)


* Advantages:
  * No schema migration needed
* Disadvantages:
  * We lose data which can't be represented in the general schema
  * We lose information about if it's a repository managed by yum. This can only
    indirectly be determined by relying on the os scope or deducing it from
    values of specific attributes (e.g. a repository without a priority is
    likely to be a yum repository).


### Flat Data Structure with Optional Elements

```
"repositories":
  [
    {
      "alias": "SMT-http_smt_suse_de:SLE11-SDK-SP3-Pool",
      "name": "SMT-http_smt_suse_de:SLE11-SDK-SP3-Pool",
      "type": "rpm-md",
      "url": "http://smt.suse.de/repo/$RCE/SLE11-SDK-SP3-Pool/sle-11-x86_64?credentials=NCCcredentials",
      "enabled": true,
      "autorefresh": false,
      "gpgcheck": true,
      "priority": 99
    },
    {
      "alias": "SMT-http_smt_suse_de:SLE11-SDK-SP3-Updates",
      "name": "SMT-http_smt_suse_de:SLE11-SDK-SP3-Updates",
      "type": "rpm-md",
      "url": "http://smt.suse.de/repo/$RCE/SLE11-SDK-SP3-Updates/sle-11-x86_64?credentials=NCCcredentials",
      "enabled": true,
      "autorefresh": false,
      "gpgcheck": true,
      "priority": 99
    },
    {
      "alias": "res6-suse-manager-tools-x86_64",
      "name": "RES6 SUSE-Manager-Tools x86_64",
      "type": "rpm-md",
      "url": "https://manager.suse.de/XMLRPC/GET-REQ/res6-suse-manager-tools-x86_64",
      "enabled": true,
      "packagemanager": "yum"
    }
  ]
}
```

This approach is very similar to the approach of using the existing schema but adds an optional attribute for the package manager. The type of package manager is stored in "packagemanager", it's optional and defaults to "zypp".

* Advantages:
  * Stores the relevant data
  * No schema change
  * Treats the data in a general way
  * No special-case for package managers

* Disadvantages:
  * Optional elements are not enforced (can be done later with a schema change),
    values of missing elements are only implicitly defined by the defaults.
  * Doesn't store additional yum attributes (these could be added as additional option elements, though)


## Considerations

When reading the list of repositories we want to get all repositories, thus
calling `yum-config-manager` or reading `/etc/yum.repos.d` doesn't work for us.
Using the python api is the prefered choice because it provides all repos and
their attributes. Using `yum -v repolist all` gives the relevant subset of the
information, but is harder to access programmatically.

Information about repositories exists on two levels. The high-level information
is about which repositories are used in the system to install packages from. The
lower-level information is about the configuration of the package manager and
how it deals with the repositories.

For inspection the high-level information is more relevant, because it shows
explicitly where the packages are from. For replication of a system the lower
level information is more relevant, because it captures the full state of the
system. It doesn't provide insight into the high-level information without
further processing, though.

Extracting high-level information to the manifest of the description and
extracting low-level information as configuration via the file inspection keeps
both levels. It needs special consideration to keep the data consistent, when
parts of the descriptions are changed, and when building images, and deploying
or exporting a description.


## Conclusion

Main goal is to show the most relevant data in a user-friendly form. For that
we need to extract the high-level information, which mostly can be represented
in the current schema.

Using a common schema for both package managers keeps the code simple as we
don't need to introduce special cases to the code dealing with repository data.
The differences are not too relevant for the use cases we address.

We do want to store the information about which package manager is used. For
that we add a `packagemanager` attribute. We also have to make the attributes
`priority` and `autorefresh` optional as they are not supported by yum.

To have a clean schema we increment the format version and add a migration. We
bundle the schema change with other pending schema changes to minimize the
number of migrations users have to do.

To read the high-level data we use the Python API, because that is the most
reliable way to access the data programmatically. We remotely execute a Python
script which prints the data in a format which can be processed on the
inspecting machine. The preference would be to use a JSON format as close to
the one we use to store the data as possible.

The full yum and repository configuration is stored in the configuration files,
which we extract with the file inspectors. This way users have the complete
information when needed. As manipulating these data and deployment are out of
scope for the current implementation, the duplication of data is not an issue.
This will be addressed in a more generic way in the future.


## References

* http://yum.baseurl.org/api/yum-3.2.26/yum.repos.Repository-class.html
* http://linux.die.net/man/5/yum.conf
* Python script to access repository data:
```
#!/usr/bin/python -tt

import os
import sys
import yum

yb = yum.YumBase()
yb.conf.cache = os.geteuid() != 0

for repo in yb.repos.sort():
          print "repo: %s" % repo
          print "      name: %s" % repo.name
          print "      enabled: %s" % repo.isEnabled()
          print "      url: %s" % repo.getAttribute("metalink")
          print "----------------------------------------"
```
The script can be run without being copied to the host as follows: ssh root@redhathost 'python' < yum.py.

