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

For these reasons we decided to do redesign.

## New Design

The new design also consists of three layers:

  * **The `Cli` Class**

    This is the entry point to the whole application. The responsibility of the
    `Cli` class is solely to define the command-line interface (available
    commands, their options, etc.). Any processing is deferred to methods of the
    `CliController` class. In practice, it means the `action` blocks consist of
    only one method call.

    The class can be thought of as an analogue of Rails router. It is tested
    using integration tests.

  * **The `CliController` class**

    The responsibility of the `CliController` class is to:

      * Check/process input and possibly produce output.
      * Construct the object graph. This means:
        * Building helper objects such as `SystemDescription` instances.
        * Serving as the place where global objects such as `UI` (which should
          be a class, not module) and `SystemDescriptionStore` instances live.
        * Building the domain objects.
      * Use domain objects to perform Machinery commands, passing them helper
        objects as needed.

    The class has methods corresponding to Machinery commands, which take raw
    CLI options as arguments (as provided by GLI):

    ```ruby
    CliController#build(global_options, options, args)
    CliController#show(global_options, options, args)
    ```

    The class can be thought of as an analogue of Rails controller. It is tested
    using integration tests (mainly because it constructs the object graph,
    which makes mocking hard).

    It's possible that we decide to split the `CliController` class into
    separate classes, each for one commands. This wouldn't change the
    responsibilities nor the overall architecture.

  * **Domain classes**

    The responsibility of the domain classes is to perform the actual work
    required to implement Machinery commands, or some parts of it. These classes
    form the *API boundary* — they provide a clean API that can be possibly
    offered to clients using Machinery from Ruby. They should not assume they
    are called from a command-line interface. All dependencies they need should
    be explicitly injected, which means the classes and their methods are should
    be easily testable.

    The classes can be thought of as an analogue of Rails models. They are
    tested using unit tests.

## Moving from the Current Design to the New Design

Moving from the current design to the new one will involve roughly the following
steps:

  1. Moving all code from the `action` blocks in `Cli` to `CliController`
     methods named by the commands. `CliController`. This will ensure the `Cli`
     class only deals with definition of the command-line interface, not
     processing of the input.

  2. Inlining all task classes code into `CliController` methods.

  3. At this point, the `CliController` class will be big, ugly, and full of
     duplication. Gradual refactoring will be performed to extract most of code
     which previsouly lived in the task classes into specialized domain classes.
     At the end, `CliController` should be small, DRY, and beautiful (and so
     should be the domain classes).

     Note that initial shape and size of the `CliController` class will force us
     to lean towards extacting more (rather than less) from it. This is a good
     thing.
