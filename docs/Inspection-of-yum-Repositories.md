# Inspection of yum Repositories

When a Red Hat system is inspected we need to handle yum repositories. There are two aspects we have to consider:
* Reading the repository data from the system
* Storing the repositroy data in the manifest file

## Reading the Repository Data from the System

This section presents different ways of accessing the yum repository data and lists their advantages and disadvantages.

### Parse output of `yum -v listrepo all`
* Advantages:
  * Lists all repos
* Disadvantages:
  * Parsing not trivial (line breaks depend on length of output)
  * Not all repo attributes accessable

### Parse the repo files in `/etc/yum.repos.d`
* Advantages:
  * list (almost) all repo attributes
* Disadvantages:
  * Repos from plugins missing (e.g. suse manager's repos)

### Accessing the python api
* Advantages:
  * All repos and repo attrributes accessible (you need to know the attribute's name, though)
* Disadvantages:
  * none

### Calling `yum-config-manager`
* Advantages:
  * Lists all repo attributes (incl. defaults)
* Disadvantages:
  * Hard to parse
  * Disabled repos missing

## Storing the repository data in the system description

There are different ways how the repositories can be stored in our data structure. This sections lists
various approaches and their advantages and disadvantages.


### Seperate Sub-Sections for zypp and yum

```
* repositories
  * zypp
    * zypp 1
    * zypp 2
  * yum
    * yum 1
    * yum 2
```

* Advantages:
  * Lists repos seperately
  * Different repos type can contain different attributes
* Disadvantages:
  * Schema migration needed

### Flat Data Structure

```
* repositories
  * zypp 1
  * zypp 2
  * yum 1
  * yum 2
```
This approach includes storing the repository type.


* Advantages:
* Disadvantages:
  * Schema migration needed

### Flat Data Structure

```
* repositories
  * zypp 1
  * zypp 2
  * yum 1
  * yum 2
```
This approach doesn't include storing the repository type.
Attributes of yum repos are mapped to zypp's attributes.

* Advantages:
  * No schema migration needed
* Disadvantages:
  * No easy to build images using the available data



## References
* http://yum.baseurl.org/api/yum-3.2.26/yum.repos.Repository-class.html
* Pyhton script to access repository data:

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
The script can be run without being copied to the host as follows: `ssh root@redhathost 'python' < yum.py`.
