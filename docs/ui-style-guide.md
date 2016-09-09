# Machinery UI Style Guide

Machinery has two user facing interfaces, the command line and the graphical user interface in the form of an HTML view.  
All additions to Machinery should follow the same or at least a similar style to allow a consistent user experience.

## Command Line Interface

### Output

The Markdown syntax is used to format the data when applicable, for example in headlines or listings:

```
# Services [example] (2016-07-05 17:07:38)

  * after-local.service: static
  * auditd.service: enabled
  * auth-rpcgss-module.service: static
  * autovt@.service: disabled

```

Additional attributes of a list are in brackets:
```
* bin (bin, uid: 1, gid: 1, shell: /bin/bash)
```
```
*util-linux-2.25-12.2.x86_64 (openSUSE)
```

If the line would exceed 80 characters the data is formatted as a list entry where the attributes are indented on the same level as the text of the first line:
```
  * /boot/backup_mbr (file)
    User/Group: root:root
    Mode: 644
    Size: 512 B

```

### Command Names

Commands should only be named with one word if possible. If more than one word is needed it must be separated with a dash.

### Documentation

Complete sentences with dots at the end should be used for all documentation and help texts.

The only exceptions are descriptions in one line of a simple parameter in the command line help.

### Errors

Possible user errors should be captured and handled. If not, the default is shown which would provide a backtrace and a message for the user to report the issue.

For error messages use the method `Machinery::Ui.error("Error: <message>")`, which should output regular sentences with a dot at the end.

### Warnings

For warning messages use the method `Machinery::Ui.warn("Warning: <message>")`, which should output regular sentences with a dot at the end.


## Graphical User Interface (HTML View)

Our GUI as well as our HTML man page use the same style as our website http://www.machinery-project.org/.

### CSS

Our CSS is based on [Bootstrap](https://getbootstrap.com/).
