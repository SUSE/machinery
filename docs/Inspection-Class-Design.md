Inspection means obtaining data from a local or remote system system concerning a particular area (packages, repositories, services,...) and storing it into our internal JSON format (see [data model](Data-Model)). This document describes structure of classes implementing this functionality.

## Structure

The main entities in the inspection process are **inspected systems** and **inspection code**. Both are reflected in the class design.

## Inspected Systems

Inspected systems are represented by the `System` class and its subclasses:

```ruby
class System
  abstract_method :run_command
  abstract_method :retrieve_files
  # ...

  def for(host)
    host ? RemoteSystem.new(host) : LocalSystem.new
  end
end

class LocalSystem < System
  def run_command(*args)
    Cheetah.run(*args)
  end

  # ...
end

class RemoteSystem < System
  def initialize(host)
    @host = host
  end

  def run_command(*args)
    Cheetah.run("ssh", ...)
  end

  # ...
end

# Example usage

system = System.for("dreadnought.suse.cz")
files = system.run_command("ls", "/etc", :stdout => :capture).split("\n")
```

All systems are capable of running commands, pass them input and capture their output. This is accomplished using the `run_command` method, which has a Cheetah-like interface. In case of remote systems, the method executes commands using `ssh`.

All systems are also capable of extracting files from the system with the `retrieve_files` method for processing on the inspecting machine or storage as part of the system description.


## Inspection Code

### Correspondences

On the data model level, information about the system is structured into *areas* (packages, repositories, services,...). These correspond to the toplevel keys in the JSON document.

For example, a JSON document describing software configuration may look like this:

```json
{
  "repositories": [
    {
      "alias": "YaST:Head",
      "name": "YaST:Head",
      "url": "http://download.opensuse.org/repositories/YaST:/Head/openSUSE_12.3/",
      "type": "rpm-md",
      "priority": 99,
      "keep_packages": false,
      "enabled": true,
      "autorefresh": true
    },
    ...
  ],
  "packages": [
    {
      "name": "kernel-desktop",
      "version": "3.7.10-1.16.1"
    },
    ...
  ]
}
```

Areas in the data model correspond 1:1 to *scopes* used by users in the CLI.

For example, a user who wants to retrieve a list of packages from a system can use the following command:

    $ machinery inspect --scope=packages dreadnought.suse.cz

Finally, areas and scopes correspond 1:1 to *plugins* and *inspectors* (see below).

All these 1:1 correspondences are meant to simplify things and avoid unnecessary layers of indirection. If we find that some of these correspondences cause problems, we'll drop them.

### Plugins

The inspection code is implemented in plugins. This makes the design modular and ensures extensibility.

In general, plugin is a set of classes performing a specific task (inspection, display, installation, ...) in a specific area (packages, repositories, services,...).

One of the plugin classes is the *main* one. In case of inspection, this class is derived from `Inspector` and implements the `inspect` method. Its class and file name correspond to the area the plugin is responsible for. For example, a `packages` plugin contains a `PackagesInspector` class in the `packages_inspector.rb` file.

The main class is automatically found and loaded based on its file location. The other classes need to be loaded by the main class using the `require` statement.

On the file system level, plugins are split along the task they perform and further along the area they cover. The overall directory structure looks like this:

    machinery
    └─ plugins
       ├─ inspect
       │  ├─ packages_inspector.rb
       │  ├─ repositories_inspector.rb
       │  └─ ...
       ├─ show
       │  └─ ...
       └─ ...

For now, plugins are mainly about code modularity. There is no infrastructure for plugin installation, no plugin metadata, etc. It is possible that these things will be added later as the plugin framework matures.

### Inspectors

The inspection itself is performed by inspector classes, derived from a common `Inspector` superclass:

```ruby
# Generic

class Inspector
  abstract_method :inspect

  def self.for(scope)
    Object.const_get("#{scope.capitalize}Inspector")
  end
end

# Inside plugins

class RepositoriesInspector < Inspector
  def inspect(system)
    output = system.run_command("zypper", ..., :stdout => :capture)

    # Parse and convert the output into an array of OpenStructs...
  end
end

class PackagesInspector < Inspector
  def inspect(system)
    output = system.run_command("rpm", ..., :stdout => :capture)

    # Parse and convert the output into an array of OpenStructs...
  end
end
```

The `inspect` method gets passed a `System` instance and a `SystemDescription` instance. It stores the inspected data under the corresponding key in the data model and returns a summary of the inspection.

Code invoking the inspectors could look like this (just a sketch):

```ruby
class InspectTask
  def execute(host, scopes = all_scopes)
    description = SystemDescription.new

    scopes.each do |scope|
      Inspector.for(scope).inspect(system,description)
    end

    description
  end
end
```
