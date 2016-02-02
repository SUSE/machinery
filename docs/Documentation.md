This page describes our expectations, conventions, and agreements about documentation.

## User documentation

For now our primary user documentation is the [`machinery` documentation](http://machinery-project.org/docs). This is where all information required or helpful for using the tool is collected. Our target audience are system administrators of the data center.

In addition to the documentation there is command line help accessible by `machinery help`. This is the minimal usage information. It should be short and useful for somebody who already knows the concepts and has read the documentation. It's mostly a reference.

We might want to add additional documents describing specific work flows or more high-level descriptions in the future.

Our development work flow includes writing documentation for all user-visible parts of the tool. So the documentation always should be up to date.

We also maintain a [NEWS file](https://github.com/SUSE/machinery/blob/master/NEWS) describing all changes relevant to users of the tool. It serves as a change log.

## Developer documentation

There is some developer documentation in the [docs](https://github.com/SUSE/machinery/tree/master/docs) directory in the machinery git repository.

The most complete reference for developers is the [source code](https://github.com/SUSE/machinery), though. When we will provide APIs meant to be used by third party developers we will add appropriate documentation.
