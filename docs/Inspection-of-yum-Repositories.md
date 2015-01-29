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
  * All repos and repo attrributes accessible (you need to know the attribute name, though)
* Disadvantages:
  * Copying script to target needed

### Calling `yum-config-manager`
* Advantages:
  * Lists all repo attributes (incl. defaults)
* Disadvantages:
  * Hard to parse
  * Disabled repos missing


## Storing the repository data in the system description
