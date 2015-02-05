# Inspection of yum Repositories

When a Red Hat system is inspected we need to handle yum repositories. There are two aspects we have to consider:
* Reading the repository data from the system
* Storing the repository data in the manifest file

## Reading the Repository Data from the System

This section presents different ways of accessing the yum repository data and lists their advantages and disadvantages.

### Parse output of `yum -v repolist all`
* Advantages:
  * Lists all repos
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

### Parse the repo files in `/etc/yum.repos.d`
* Advantages:
  * list (almost) all repo attributes
* Disadvantages:
  * Repos from plugins missing (e.g. suse manager's repos)
    The yum-rhn-plugin reads the configuration files `/etc/yum/pluginconf.d/rhnplugin.conf` and `/etc/sysconfig/rhn/up2date`.

### Accessing the python api
* Advantages:
  * All repos and repo attributes accessible
* Disadvantages:
  * You need to know the attribute's name

You can find an example script below in the References section.

### Calling `yum-config-manager`
* Advantages:
  * Lists all repo attributes (incl. defaults)
* Disadvantages:
  * Hard to parse
  * Disabled repos missing
  * Variables `$releasever`, `$basearch` in repo files raise questions:
    * What about the variables used in repo files?
    * Should we store them or the expanded value?
    * Where do the values of the variables come from, and should we capture that as well?
  * The yum.conf file (link in the References section) lists the available variables and explains how they are expanded.


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
  * Lists repos separately
  * Different repos type can contain different attributes
* Disadvantages:
  * Schema migration needed
  * No common representation, complicates code dealing with repositories in a more abstract way, e.g. for display or comparison

### Flat Data Structure w/ Schema Change

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
      "priority": 99,
      "packagemanager": "zypp"
    },
    {
      "alias": "SMT-http_smt_suse_de:SLE11-SDK-SP3-Updates",
      "name": "SMT-http_smt_suse_de:SLE11-SDK-SP3-Updates",
      "type": "rpm-md",
      "url": "http://smt.suse.de/repo/$RCE/SLE11-SDK-SP3-Updates/sle-11-x86_64?credentials=NCCcredentials",
      "enabled": true,
      "autorefresh": false,
      "gpgcheck": true,
      "priority": 99,
      "packagemanager": "zypp"
    },
    {
      "repoid": "res6-suse-manager-tools-x86_64",
      "name": "RES6 SUSE-Manager-Tools x86_64",
      "type": "rpm-md",
      "baseurl": "https://manager.suse.de/XMLRPC/GET-REQ/res6-suse-manager-tools-x86_64",
      "enabled": true,
      "gpgcheck": false,
      "packagemanager": "yum"
    }
  ]
}
```
This approach includes storing how the repository is used in the system.
The same repository could be used with both, zypper and yum.

* Advantages:
  * Common representation, which makes it easier to deal with repositories in a more abstract way, e.g. for display or comparison
* Disadvantages:
  * Schema migration needed

### Flat Data Structure w/o Schema Change

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
This approach is similar to the approach above but doesn't include storing the repository type.
Attributes of yum repos are mapped to zypp's attributes.
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
  * Building Red Hat images not straight forward: We can find out that it is a yum repo because it doesn't have priority nor autorefresh


## Use Cases

* Less relevant:
  * building Red Hat images

* More relevant use cases:
  * (manually) migrate a Red Hat system to a SUSE system
  * generate a report of a Red Hat system
  * compare a Red Hat system with a SUSE system


## Remarks

When we only want to use the description as result of an inspection and not for anything else, we might want to think about if we need to flag the description somehow, so the tool can help the user to do the right things with it.


## Considerations

When reading the list of repositories we want to get all repositories, thus
calling `yum-config-manager` or reading `/etc/yum.repos.d` doesn't work for us.
Using the python api is the prefered choice because it provides all repos and
their attributes.

The usecase for storing yum repositories is the inspection of a Red Hat system
and creation of a human readable report. Building Red Hat images is out of scope
for know, thus the 3rd option would do the trick. The advantage is that no
schema change whould be needed.


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

