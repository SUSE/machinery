# Commit Guidelines
Commits are changes to the codebase, consisting of the code change itself and a message describing it. Creating a good commit is sometimes quite an art. These guidelines should help you master it.

Summary
-------

* Create atomic commits
* Commit messages:
  * Describe what changed and why
  * Format: subject, blank line, body
  * Subject = short description, imperative present tense, capitalized, no period at the end
  * Body = details, regular sentences
  * Include references to bugs, FATE entries, etc.
  * Wrap at 72 characters
  * Read an [article by Tim Pope](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)

Atomic Commits
--------------

One commit should solve one problem. It should be an atomic unit — before and after the commit, the code should be in consistent state. If you can break the problem into more subproblems, it is usually good idea to do it and split the change into more commits. This makes the understanding and reviewing the commits
much easier. The important exceptions are:

  1. You are doing the same or very similar change on many places.

  2. You are rewriting a part of the code completely.

You can label related commits using the commit message (e.g. “Foo refactoring 1/3: Extracting methods”).

Commit Messages
---------------

The purpose of a commit message is:

  1. To describe a change in the code for other people and your own future self.

  2. To explain why it was done.

The first point usually isn't a problem, but the second can be tricky.

Commit messages describing the change well help tremendously when reviewing, debugging, digging through history, etc. — mainly because they allow separating relevant changes from the irrelevant. When you need to look at the diff to actually determine if the commit is relevant for you, the description is bad.

Good description does not need to be long — for trivial changes like formatting, description “Improve formatting” is adequate. But it should be specific and contain relevant keywords so that grep in the commit log works sanely.

*<strong>Example:</strong> When porting test fixes in SUSE Studio from `master` to `onsite_1_1` branch, grepping through the master's log for “fix tests” and similar phrases helped quite a lot to find the fixes. It wouldn't have worked if the descriptions were bad.*

When you are making a change in the code, you are making it for some reason. Sometimes the reason is simple and obvious (e.g. adding new functionality), sometimes it is quite complicated (e.g. result of a lengthy discussion weighting many factors or several hours of bug investigation). Whenever you make a change for non-obvious reason and don't state the reason anywhere, you basically just thrown the effort of coming to it out of the window.

*<strong>Example:</strong> You spend the whole day hunting down a bug and add two lines of code as a	result. But a year after someone will be rewriting that part of the program. If he won't understand from the “git blame” why the change was made, it is quite likely he'll just throw the code out as unnecessary — which will cause a regression and probably another day lost by someone hunting the bug down again. And no, the rewriter will not ask you — because at the time, you may be working on other project or company.*

Code that nobody understands has no value. And the gap in understanding usually isn't because one doesn't see what is happening in the code, but *why*. So, please preserve information about your reasoning when doing a changes. It may be in comments, commit messages, or bugs referenced from them — that does not
matter much. It matters that the information is available. These two minutes spent writing it down are spent well.

To reference bugs at [bugzilla.novell.com](https://bugzilla.novell.com/), use the format *bnc#123456*.

To reference FATE entries at [fate.novell.com](https://fate.suse.com/), use the format *fate#123456*.

Examples of well-written commit messages from non-SUSE projects:

**V8**

    Fix bug in deletion of indexed properties
    
    The delete operator always return true in case of indexed property. It
    should return false if an indexed property can't be deleted (eg.
    DontDelete attribute is set or a string object is the holder).
    
    Contributed by Peter Varga <pvarga@inf.u-szeged.hu>
    
    BUG=none
    TEST=mjsunit/delete-non-configurable
    
    Review URL: https://codereview.chromium.org/11094021
    Patch from Peter Varga <pvarga@inf.u-szeged.hu>.

([Reference](http://code.google.com/p/v8/source/detail?r=12736))

**Chromium**

    Fix wrong truncation of notification popup messages in ash.
    
    views::Label control first calculates the size of the text,
    and then tries to render the text in the exact size of rectangle.
    If < is used instead of <= in the patched line, the control
    flows to the BreakIterator mode, that sometimes computes a
    larger width value and causes truncation.
    
    BUG=155663
    
    Review URL: https://codereview.chromium.org/11150013

([Reference](http://git.chromium.org/gitweb/?p=chromium.git;a=commit;h=c634f464370853978f2770f231e3cf19d03577d5))

**Google Closure Compiler**

    Attach types to literals at scope-creation time instead of at
    inference time.
    
    Scope-creation already attaches types to function literals at
    scope-creation type, so this makes the other literals more consistent
    with function literals.
    
    R=johnlenz
    DELTA=167  (102 added, 53 deleted, 12 changed)
    
    
    Revision created by MOE tool push_codebase.
    MOE_MIGRATION=209649

([Reference](https://code.google.com/p/closure-compiler/source/detail?r=b7b201a08e330c9638f52f5dfe824e426a34f2c5))

**Rails**

    Move two hotspots to use Hash[] rather than Hash#dup
    
    https://bugs.ruby-lang.org/issues/7166

([Reference](https://github.com/rails/rails/commit/02174a3efc6fa8f2e5e6f114e4cf0d8a06305b6a))

Note that the first line usually describes the change, others explain the reasoning. The last example shows that an external reference is sometimes good enough as an explanation.

Git has some specific rules for formatting commit message that other version systems don't have. If you break them, nothing fails, but if you adhere to them, Git will work better for you and for others. They are nicely summarized e.g. in an [article by Tim Pope](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html). Consider these rules part of these guidelines and use them as much as
practically possible.
