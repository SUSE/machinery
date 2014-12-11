# Filtering system descriptions

This draft describes a filtering mechanism for Machinery, which could be used
to filter out elements from scopes when running commands.


## Goal

When running commands such as `inspect` or `show` or `build` it is often
desirable to not cover a scope in its completeness, but leave out certain parts.

For example when inspecting, it might be helpful to skip a directory tree, where
the user knows that there are unmanaged files, but that they don't matter. When
building it might be helpful to skip some files, which are part of a system
description, but shouldn't end up in the specific build the user is doing. When
showing a description, it could be useful to hide parts of a scope to make the
output more easy to read, e.g. hide not-running services to see only the running
services.

Machinery should provide a mechanism to allow the user to do this filtering. The
goal of the design described in this document is to provide such a mechanism in
a way which is generally usable across scopes and commands.

It has two parts. The first is the general mechanism, which gives the full power
of filtering for a big number of use cases, but does require the user to have
a thorough understanding of the mechanism in its generality. The second part is
a user interface layer, which makes it more easy to use the filters for the most
common use cases.


## General mechanism

### Concept

Each scope contains elements either as a list or as a map, and each command is
operating on a list of scopes. The general idea is to make it possible to
define a set of filters, which is applied, when executing a command, and filters
out all elements of the scopes, which match the filter criteria.

Filters are defined in a generic way, which is independent of scope and command,
so that the same way of defining filters can be used everywhere, and filters can
be reused and shared between scopes and commands.


### Filter definitions

Each filter defines a matcher for elements of a system description. The element
is specified by its path within the JSON manifest, and the matching condition
is specified by a condition attached to the element specification.

The generic format for a filter definition is

    /scope/element=condition

where `scope` is the name of the scope, which should be filtered, `element` is
the path to the element, which is used to check the matching condition, and `=`
and `condition` are the operator and value used to match.

When applied on a scope this filter results in a list of all elements but the
ones matching the filter.

When the matched element is a string it is used literally without the quotes to
match against the condiditon, e.g. a JSON such as `"name": "apache"` matches
`name=apache`.

If it is an array, the its string representation is matched against the
condition. e.g. a JSON such as `"changes": ["deleted"]` matches
`changes=deleted`, and a JSON such as `"changes":  ["mode", "user"]` matches
`changes=mode,user`.

Filters can be inverted by prefixing them with a `!`:

    !/scope/element=condition

When applied on a scope this filter results in a list of only the elements
which match the condition.

The first step is basic filtering, which only supports simple matches for
equalness and don't allow for wild cards or any other more complex regular
expressions.

#### Examples

Match the apache package:

    /packages/name=apache

Match all services which are not enabled:

    !/services/services/state=enabled

Match the home directory of user alfred in unmanaged files:

    /unmanaged_files/files/name=/home/alfred/

Match the global cache directory in changed managed files:

    /changed_managed_files/file/name=/var/cache/

Match all deleted config files:

    /config_files/files/changes=deleted


### Storing filter definitions

Filters can be provided on the command line as described in the next section,
but there are also situations where they need to be stored. When doing an
inspection it needs to be stored what filters were used, so that users can judge
if a file is missing from a description or if it has been filtered in the first
place. When showing a description or using other commands consuming a system
description it is convenient to make filters persistent, so they don't have to
be provided every time the command is run again.

Storing filters is useful on different levels, system-wide, per user, and per
description. As starting point only per description filters are considered.

The filters are stored in the `meta` section of a description. An example would
be:

```json
"meta": {
  "format_version": 2,
  "filters": {
    "inspect": [
      "/unmanaged_files/files/name=/home/alfred/",
      "/unmanaged_files/files/name=/var/cache/"
    ],
    "show": [
      "/services/services/state=disabled"
    ]
  },
  "unmanaged_files": {
    "modified": "2014-11-25T13:42:22Z",
    "hostname": "hal"
  },
  "services": {
    "modified": "2014-11-25T13:42:22Z",
    "hostname": "hal"
  }
}
```

It might also be useful to have filters which apply to all scopes, but this is
not considered for now. The functionality can be achieved by copying filters
to other scopes.


## User interface

Filters can be managed on the command line. The details are described in this
section. In addition they can be manipulated as they are stored in the
description. This is up to the user and not considered further here.


### Generic usage

Using filters in their generic form is possible with the global
`--filter=filter_definition` option which is available in all commands.

#### Example: inspection

Filter `/var/cache` from unmanaged files on inspection of host `NAME`:

    machinery --filter=/unmanaged_files/files/name=/var/cache/ inspect NAME

The command ommits the directory `/var/cache/` from the inspection of
unmanaged files and writes the filter as part of the meta data of the resulting
description.

#### Example: show

Show all enabled services in description NAME:

    machinery --filter=!/services/services/state=enabled show NAME

The filter removes all services which match the filter criterion from the
output. In this case it is all services which are not enabled. So the result is
all enabled services.


### Managing filters

Persistent filters which are stored in a description can either be edited in the
JSON file or managed with the following commands:

List all filters:

    machinery filter list NAME

Add a filter:

    machinery filter add NAME FILTER_DEFINITION

Remove a filter:

    machinery filter remove NAME FILTER_DEFINITION


### Special interface for common use cases

The generic filter option is powerful and covers all use cases which the
implementation is capable to handle. But it is not the most convenient way to
use Machinery. For this reason we add more convenient alternative ways of
specifying filters for specific common use cases.

#### Skip files during inspection

Filter file from files inspection (for all file scopes) of system NAME:

    machinery inspect --skip-files=FILENAME NAME

Filter multiple files from files inspection (for all file scopes) of system
NAME:

    machinery inspect --skip-files=FILENAME1,FILENAME2 NAME

Filter files from files inspection (for all file scopes) of system NME which are
defined in a separate file FILTERS listing all file names which should be
filtered:

    machinery inspect --skip-files=@FILTERS NAME
