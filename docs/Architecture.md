# Machinery Architecture

## Introduction

The goal of Machinery is to provide a framework for consistent management of
Linux systems on the OS level. The target audience is system administrators in
the data center.

There is a plethora of use cases and needs in this area, so we are providing a
flexible and extensible framework to address these needs. It builds on existing
tools, standards, and implementations. The prime goal is to provide a consistent
way to access and integrate these. This way handling Linux systems in the data
center and beyond becomes easy and effective to manage.

## Functional Areas

Machinery covers several functional areas. These are the building blocks
for workflows in the management of Linux systems in the data center.

The diagram shows an overview of the functional areas. The following section
describes them in more detail.

![Functional areas of OS life cycle
management](http://machinery-project.org/img/usecase-default.png)

### Inspect System

The inspection is the key function to analyze the actual state of a system. It
extracts configuration information from a running system. The result is a full
description of the system. The inspection is a pure read-only operation, which
doesn't modify the system in any way. The description is stored in a
machine-readable way for further processing. The user can also view it in a
human-readable way.

### Show System Description

For display to the user stored or obtained descriptions are shown in a
human-readable form. There needs to be tooling to select, show, and format data
according to the needs of the user.

### Validate System

Systems have a desired and an actual state, which ideally are identical. To
check that this is the case, it needs to be possible to validate systems against
descriptions of the desired state. This can be done against concrete
descriptions or more abstract system templates.

### Parameterize System Description

Inspections result in descriptions of a concrete full system. This description
is specific to the inspected running system. It can be useful to turn such a
specific description in a more general description which can be used as a
template for classes of systems. A specific description is turned into a
template by parametrization. This operation defines which aspects of a system
can or need to be changed and which are immutable.

### Modify System Description

Various use cases require to modify a system description. This can be necessary
for adapting a description to a different environment. It can be a change of the
functionality of the system. Or it is tailoring a template to a more concrete
system. There needs to be tooling to support the user in doing these
modification in a robust and transparent way.

### Build Image

One representation of a system is a system image. A system image is a file
containing the complete file system of an image in a way that it can be
instantiated as a running system. There are different types of images depending
on the target environment where the image is run. This can be physical or
virtual environments.

### Apply System Description

To set a system into a state which is consistent with a given description, the
description needs to be applied to the system. This is the equivalent of
configuring the system in the way defined by the description. This operation is
applied to running systems.

### Run System

To inspect and test a system description or an equivalent image needs to be run
as an actual system. This is done by instantiating the system in a virtual
environment.

### Deploy System

For production usage systems need to run in the desired target environment. For
running it in a virtual environment, such as a cloud, there needs to be a way to
deploy a system to the target. The deployed system should reflect the given
system description. When the deployment uses images, an image is built from the
description. Target-specific tools then use this image to do the actual
deployment.

### Export System Description

There also needs to be a way to install a system according to a description in a
physical environment. This can be done by a scripted or partly interactive
installation. Doing the installation is out of scope of Machinery. But there
needs to be a way to export system descriptions in a format understandable by
installation tools.

### Import Description

There are existing descriptions of systems. These are for example AutoYaST or
Kiwi profiles, or SUSE Studio image descriptions. It has to be possible to
import these descriptions for further processing. Then they can be used in other
functional areas like deployment, parametrization, or installation.


## Objects

There are some key objects, which are used in the functional areas described in
the previous section. The primary object is a Linux system, which is represented
on different levels and in different ways. This section gives an overview about
these objects. It also shows how they relate to the functional areas in the
context of project Machinery.

### Running System

The trivial but ultimate representation of a system is a running system. By
definition it includes everything required to define the system. But the
information often can't be accessed in a structured way. The goal and result of
system configuration and management is having running systems in the desired
state. So they fulfill the needs of the business.

### System Description

A system description is a structured and accessible representation of a system.
It describes a concrete running system. It contains all the required information
to replicate the running system. This representation is meant to be suitable for
processing. Operations like analyzing, modifying, or instantiating the system
can be performed on the description. This is done in a well-defined, repeatable,
and tracked way. They don't need to work on the running system.

### System Template

A system template is a more abstract description of a system, which defines a
class of systems, not a concrete running system. It has parameters, which are
substituted by concrete values.  Profiles of the concrete target systems define
the values for the substitution. A template can define some aspects of a system
as immutable and others to be adaptable. It also can provide default values for
adaptable parts of the system.

### Images

Images are concrete representations of systems in the form of a deployable file.
They contain the full file system of the system. This can come with extra
tooling and configuration to adapt to target environments in a defined way. An
example would be making use of provided storage space in a way specific to the
deployed running system not the image.

### Exchange formats

There are some existing formats to describe systems. These formats can be used
to exchange information between tools. To make full use of the functionality
provided by Machinery, it needs a way to make use of these exchange formats.
Import of data from and export of data to the exchange formats serves this
purpose.


## Work flow

User work flows usually consist of a combination of elements of the basic
functional areas.

One example would be disaster recovery. This consists of inspecting a system,
storing its description, and installing the system from this description again.

Another example would be OS version migration. This consists of inspecting a
system, modifying the obtained description to upgrade the OS, and then deploying
the description to a new target.

A third example would be scaling out a system. It would start with inspecting
one machine. The next step would be to parameterize the resulting description.
The result is a template for several different machines. As a final step the
parameterized template is adapted to concrete running systems, and each concrete
version is deployed to a running system.

This way complex work flows can be built from the functional areas as building
blocks. As a consequence these building blocks have to be available in a form,
which makes it easy to integrate them in higher-level work flows. This also has
to cover the needs of integration with other tools or integration in larger
infrastructure.

It also means that what is happening in these building blocks needs to be
transparent and customizable, so that the tools can match a variety of business
needs.


## Components

Each component of the Machinery framework corresponds to one of the functional
areas. The component is covering the functional requirements of a specific
functional area. It provides input and output facilities to interact with
components of the other functional areas. The most prominent object used for
interaction is the representation of a system.

The components are encapsulating specific functionality. This can be implemented
as internal or external tools. The goal of the encapsulation is to provide a
uniform interface for composing work flows. As secondary goal is to allow to
substitute specific implementations by others with minimal impact on
user-visible parts. Finally it makes it easy to test components to guarantee
interfaces and prevent regressions.

Each component needs to deal with a broad variation of data and options. This
includes for example:

* different configuration domains of a system
* different operating base systems
* various parts of various software stacks
* rich set of target systems for running systems

To accommodate these variations there needs to be a flexible and extensible
approach to cover them in a structured way. Some kind of plugin system will
address this. It allows to add support for variations of data and options in a
structured and well-isolated way.


## Command line tool

The primary user interface to the components is a command line tool. With
this tool users can orchestrate work flows from the elements of the functional
areas. Common and consistent objects are used to transport information and data
between components, the tool, and the user. These objects can for example be
system descriptions, templates, or images.

The command line tool uses a sub-command based interface. Each sub-command
represents one functional area.


## System description

The central element of the tooling is the description of a system. It's used for
storing and transporting information. It's also used for processing as
templates, for validation, define system changes, or other purposes.

The description is stored in a documented format, which is accessed through the
components and the command line tool.

There can be partial descriptions of a system extracting certain areas of
information. There also can be super-descriptions spanning across multiple
systems, covering inter-systems dependencies. The focus for the tooling is on
the single system description, which is used as building block for
higher-level tools and procedures.


## API

APIs give programmatic access to the functionality of the Machinery tools and
the information they deal with. The main API is the command line tool. The
components provide library APIs, which are exposed for external use as needed.


## Design principles

### Networked access via SSH

In general system configuration needs to be accessed not only on a local system,
but also on remote ones. For remote access we use SSH as a general
mechanism to get access to remote machines. This leverages all the
infrastructure, knowledge, and tooling which is available around that. We make
use of existing services, and don't require additional agents permanently
running on target machines.

### Activity logging

For being able to follow changes we provide central logging of
user-relevant activities in the framework. There needs to be a structured and
well-defined way of writing these logs, making sure that all relevant activities
are captured.

### Tool transparency

Machinery relies mainly on existing external tools to do the actual work. The
framework should make it possible for the user to get information about which
tools are called and how. This makes the use of tools transparent. It provides
flexibility as users can fall back to direct use of external tools. It also
makes diagnostics of problems easier.

### Explicitness of customizations

Work flows will need customization on various levels. We will provide hooks and
structure to make it possible to customize behavior in an explicit way. The goal
is to capture the intent of the customization. One example would be to require a
description line, when adding a custom script to an action. This description
line would then capture the purpose of the script for later users.

### Test driven design

It is important to prevent regressions. This is hard because of the broad range
of use cases, scenarios, and potential setups. Automated tests providing full
coverage of the functionality ease this problem. To assist with this we
follow a test driven design approach, which makes sure that the design is
well-testable.

### Native APIs

When providing APIs we will do this in the most native way possible. Tools and
components can naturally and easily be integrated in other systems, respecting
the expectations of the users.

### Minimal root access

It needs root privileges to read some system configuration data. For writing it
needs root privileges in most cases. To keep the code as robust and secure as
possible, we will minimize the need for root privileges. We will limit code
which needs to run as root to an as small as possible amount. As much
functionality as possible should be accessible with normal user privileges.
