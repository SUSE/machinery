# Overall Class Design

## Current Design

The current design consists of three layers:

  * **The `Cli` class**

    This is the entry point to the whole application. It defines the
    command-line interface (available commands, their options, etc.), does some
    input checking/processing, builds helper objects such as `SystemDescription`
    instances, and delegates the real work to task classes (`BuildTask`,
    `ShowTask`, etc. — each for one command).

  * **Task classes**

    These take processed CLI input and perform the actual commands. In some
    cases they are simple, in some cases relatively complex. Often some part of
    the work is done by more low-level domain objects the task classes create.

  * **Low-level domain classes**

    These deal with some well-defined parts of the tasks, such as generating
    KIWI configuration file (`KiwiConfig`) or HTML output (`Html`).

The `Cli` class is tested using integration tests, the rest using unit tests.

This design has several disadvantages:

  * The responsibility for various concerns are spread out and unclear.

  * There is no clear API boundary.

  * The task classes are hard to test. This is mainly because they do a lot and
    create many helper objects themselves, which makes it hard to use mocks.

  * The task classes have varying size. Sometimes it feels like a task class for
    given command is not be really needed, sometime is contains significant
    amount of domain logic.

  * The task classes generally have just one public method. This is a small code
    smell.

  * The `Cli` class contains duplication and mixes definition of the
    command-line interface with input processing code and object graph building.
