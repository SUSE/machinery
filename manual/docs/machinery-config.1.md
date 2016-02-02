
# config — Configure Machinery

## SYNOPSIS

`machinery config`

`machinery config` KEY

`machinery config` KEY=VALUE

`machinery` help config


## DESCRIPTION

The `config` command shows or changes machinery's configuration.

If no arguments are passed the `config` command lists all configuration
entries and their values. If only the key is provided its value is shown.
If key and value are specified this configuration entry is set accordingly.

The configuration is stored in `~/.machinery/machinery.config`.

## ARGUMENTS
  * `KEY`:
    Name of the configuration entry.

  * `VALUE`:
    Value of the configuration entry.


## EXAMPLES

  * Turn off hints:

    $ `machinery` config hints=off

  * Show current configuration of hints:

    $ `machinery` config hints

  * List all configuration entries and their values:

    $ `machinery` config
