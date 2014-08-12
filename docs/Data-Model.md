# Machinery Data Model

The Machinery data model represents the system configuration as processed by Machinery. It consists of two parts that closely correspond to each other:

  * JSON serialization
  * Internal object model

It is assumed that at the beginning, the JSON serialization will be used only by Machinery, but later other tools may start using it too. It is therefore important to consider compatibility and extensibility from the start. On the other hand, it is assumed that the internal object model will be used only by Machinery and its components/plugins, not by any external code.


## JSON Serialization

JSON serialization is used to store and exchange the system configuration.

### Structure

At the top level, the data consists of a JSON object. Each key in this object corresponds to a configuration scope (e.g. repositories, packages, changed configuration files, etc.). Data under each key is further structured into JSON objects and arrays as needed.

There is one special key `meta`, which is used to collect meta data of the information in the scope sections.

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
      "enabled": true,
      "autorefresh": true,
      "gpgcheck": true,
      "priority": 99
    },
    ...
  ],
  "packages": [
    {
      "name": "kernel-desktop",
      "version": "3.7.10",
      "release": "1.0"
    },
    ...
  ],

  "meta": {
    "repositories": {
      "modified": "2014-02-10T16:10:48Z"
    },
    "packages": {
      "modified": "2014-02-10T16:10:48Z"
    }
  }
}
```

Structure of the data, required and optional parts, etc. will be precisely specified in Machinery documentation and checked by Machinery during deserialization. There are, however, two general rules:

  1. Every JSON object can have a `comment` property containing a string. This compensates for lack of comments in the JSON format, with an additional benefit that the comments are made an explicit part of the data model.

  2. Every JSON object can contain additional properties beside those specified in the documentation (“unknown properties”). Data in such properties is simply ignored and carried through as opaque. This ensures future extensibility.

### Versioning

The question of versioning is kept open for now. It is assumed that at some point before 1.0, the topic will be discussed and some versioning scheme and compatibility policy will be created.


## Internal Object Model

### Basics

The system configuration is internally represented as a tree of Ruby objects. Leaf nodes are simple Ruby values (integers, strings, etc.), the inner nodes are instances of `Machinery::Object`, which provides an `OpenStruct`-like API for setting and getting attributes, and `Machinery::Array`, which provides an `Array`-like API.

The main advantage of using the `Machinery::Object` class to using pure hashes is that the object tree is nicer to navigate. For example, getting the first package from a list can be done using methods:

```ruby
package = config.software.packages.first
```

With Ruby hashes, the code would be uglier:

```ruby
package = config["software"]["packages"].first
```

The root of the tree is a bit special — it is an instance of the `SystemDescription` class (a subclass of `Machinery::Object`). In addition to representing the toplevel JSON object, this class contains JSON serialization, deserialization and validation code.

### Representing Scopes

Each scope is represented by a specific subclass of `Machinery::Scope`. The scopes are defined as a model class in the `plugins/model` directory. The model classes define what data objects the scope contains. There are helpers to define the structure of the data.

See for example the definition of the packages scope:

```ruby
class Package < Machinery::Object
end

class PackageList < Machinery::Array
  has_elements class: Package
end

class PackagesScope < Machinery::Scope
  contains PackageList
end
```

### Serialization into JSON

The object tree is serialized into JSON by the `SystemDescription#to_json` method. It recusively walks the tree and serializes all the nodes.

### Deserialization from JSON

The object tree is deserialized from JSON by the `SystemDescription.from_json` method.

Before deserialization, the JSON is validated using a JSON Schema (there is one for the whole document). If there are any errors, the deserialization will fail.

Because not every constraint can be expressed using JSON Schema, the `SystemDescription` class allows to define a custom validator using the `SystemDescription#add_validator` method:

```ruby
SystemDescription.add_validator "#/software/packages" do |json|
  if json != json.uniq
    raise Machinery::ValidationError,
          "The #{description} contains duplicate packages."
  end
end
```

The method is passed a [JSON Pointer](http://tools.ietf.org/html/rfc6901) and a block. The block will be called for the JSON node specified by the pointer when deserializing. If code inside this method encounters invalid JSON, it can raise the `Machinery::ValidationError` exception and the deserialization will fail.

### File Data

Some scopes contain file data. The files are not serialized to the JSON, but stored into scope-specific subdirectories of the directory where the system description is stored. Depending on the type of files they are either stored as plain files or in a structure of tar archives containing the files.
