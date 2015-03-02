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

When applied on a scope this filter results in a list of all elements excluding
the ones matching the filter.

When the matched element is a string it is used literally without the quotes to
match against the condiditon, e.g. a JSON such as `"name": "apache"` matches
`name=apache`.

It is possible to match the beginning of a string by adding `*` as a suffix. For
example

    /unmanaged_files/files/name=/etc/ssh/ssh_host_key*

would match all files whose name starts with the given value, such as
`/etc/ssh/ssh_host_key` and `/etc/ssh/ssh_host_key.pub`.

If it is an array, the its string representation is matched against the
condition. e.g. a JSON such as `"changes": ["deleted"]` matches
`changes=deleted`, and a JSON such as `"changes":  ["mode", "user"]` matches
`changes=mode,user`.

As a first step only exact matches are supported, where the
array has to have exactly the elements specified in the condition. Matches of
sub arrays will be defined later.

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
but there are also situations where they need to be stored. There are mainly two
scenarios.

First, when doing an inspection it needs to be stored what filters were used, so
that users can judge if a file is missing from a description or if it has been
filtered in the first place.

Second, when showing a description or using other commands consuming a system
description it is convenient to make filters persistent, so they don't have to
be provided every time the command is run again.

Storing filters is useful on different levels, system-wide, per user, and per
description.

#### General filter storage format

Filters are stored as JSON. Filter criteria are specified per command. An
example would be:

```json
"inspect": [
  "/unmanaged_files/files/name=/home/alfred/",
  "/unmanaged_files/files/name=/var/cache/"
],
"show": [
  "/services/services/state=disabled"
]
```

It might also be useful to have filters which apply to all commands, but this is
not considered for now. The functionality can be achieved by copying filters
to the sections for other commands.

#### Store filters used for an inspection

To preserve the information, what filters were used when inspecting a system,
the filters are stored in the `meta` section of the description. An example
would be:

```json
"meta": {
  "format_version": 2,
  "filters": {
    "inspect": [
      "/unmanaged_files/files/name=/home/alfred/",
      "/unmanaged_files/files/name=/var/cache/"
    ]
  },
  "unmanaged_files": {
    "modified": "2014-11-25T13:42:22Z",
    "hostname": "hal"
  },
  ...
}
```

#### Persistent filters

To make it more convenient to apply the same filters to repeated invocations of
commands filters can be made persistent by storing them to a filter file listing
all matchers used to exclude specific objects from certain commands.

The filter files contain JSON according to the general filter format defined
previously. The file is named `filters.json` and it is stored in the top-level
directory of a system description.

When executing a command the filters defined for the command are applied and the
results are filtered excluding all objects matching any filter conditions.

#### Cascading filters

Filters can be defined on a system-wide level, per user, or per description.
On all levels the filters are stored in the same format in a file called
`filters.json`. The filters of all levels are combined and applied to the
commands executed by the user.

The system-wide filters are installed by the Machinery package to a system-wide
location.

The user-level filters are stored in the directory used to store the system
descriptions, which is `~/.machinery` by default.

Description-level filters are stored in the top-level directory of the system
description.

When executing a command the filters of all levels are concatenated and applied
to the command as a whole.

#### Disabling filters

There are situations where it is needed to disable a filter, for example when a
filter defined by a higher-level filter file should not be applied. This can be
done by specifying the filter condition with a `-` prefix.

For example the user-wide filter

```json
"inspect": [
  "/unmanaged_files/files/name=/home/alfred/",
  "/unmanaged_files/files/name=/var/cache/"
]
```

and the description specific filter

```json
"inspect": [
  "-/unmanaged_files/files/name=/home/alfred/",
]
```

would result in the effective filter:

```json
"inspect": [
  "/unmanaged_files/files/name=/var/cache/"
]
```


## User interface

Filters can be managed on the command line. The details are described in this
section. There are transient filters, which are only applied for one execution
of a command, and there are persistent filters, which are applied on every
execution of a command.

There is a generic interface for applying and managing filters. To make common
use cases more convenient there also are special interfaces which only apply to
these use cases, but are simpler to use.


### Generic usage

Using filters in their generic form is possible with the global
`--exclude=filter_definition` option which is available in all commands.

Multiple filters can be provided as comma-separated list or can be read from
a file by using a `@`-prefixed file name as argument: `--exclude=@FILENAME`.

If filters contain commas the filter has to be quoted in double quotes, when it
is part of a comma-separated list of filters. For example:

    --exclude="/changed_managed_files/files/changes=mode,user",/changed_managed_files/files/changes=md5

#### Example: inspection

Filter `/var/cache` from unmanaged files on inspection of host `NAME`:

    machinery --exclude=/unmanaged_files/files/name=/var/cache/ inspect NAME

The command omits the directory `/var/cache/` from the inspection of
unmanaged files. To preserve the information, which filters have been applied
when creating the description, the filters are written as part of the meta data
of the resulting description.

#### Example: show

Show all enabled services in description NAME:

    machinery --exclude=!/services/services/state=enabled show NAME

The filter removes all services which match the filter criterion from the
output. In this case it is all services which are not enabled. So the result is
all enabled services. Filters are not stored in this case as the system
description is not modified.


### Managing filters

Persistent filters which are stored in `exclude.json` files can either be edited
in the JSON file or managed with the following commands:

#### List filters

The command

    machinery filter list NAME

lists all filters. This includes filters from all levels for all commands.

With

    machinery filter list NAME --command=COMMAND

the output is limited to the filters defined for the given command.

#### Add filter

The command

    machinery filter add NAME FILTER_DEFINITION --command=COMMAND

adds the filter FILTER_DEFINITION to the `filters.json` file of the system
description NAME in the section for command COMMAND.

#### Remove filter

The command

    machinery filter remove NAME FILTER_DEFINITION --command=COMMAND

removes the filter FILTER_DEFINITION from the `filters.json` file of the system
description NAME in the section for command COMMAND. If the filter is not
stored in this file, but in a higher-level filter file, the filter is added
as disabled to the description level file using the `-` prefix syntax described
previously.


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

Filter files from files inspection (for all file scopes) of system NAME which
are defined in a separate file FILTERS listing all file names which should be
filtered:

    machinery inspect --skip-files=@FILTERS NAME


## Implementation

At the moment (2014-12-22) the design is a proposal, and nothing of it is
implemented yet. This is a possible plan how to do it:

* Step 1: Implement core filtering classes and move current filtering to them.
  This includes storing filters used during inspection in the meta data of the
  system description.
* Step 2: Implement generic `--exclude` option to let users add additional
  filters on demand. This option can also be used in our integration tests.
* Step 3: Implement `--skip-files` option for the `inspect` command to make it
  easier for users to add filters.
* Step 4: Implement `filter` command and persistent per-description filters.
* Step 5: Implement user-level persistent filters.
