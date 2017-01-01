# s\*todo

## Introduction

s\*todo is yet another to-do application (implemented in ruby, for those
who care).  Its current features include, but are not limited to:

  * Create entries for tasks, memos, appointments, and projects.
  * Configure time-based notifications/reminders (currently only via email)
    for items - tasks, appointments, memos, and projects.
  * Add a google calendar entry (via gcalcli) for an item - e.g., date/time
    of an appointment or due-date for a task.
  * Change the status of an item: in-progress, suspended, completed, or
    canceled.
  * List pending items, sorted by due date.
  * Edit items.
  * Delete items.

s\*todo currently only runs on Linux systems, although it would probably be
straightforward to port it to UNIX, including OSX.

## Installation and setup

TBD (To Be Documented)

Note: The more requests I receive about how to install and use s\*todo, the
more I will be motivated to complete this section.  In other words, I don't
want to spend time writing about how to install and use it unless I see
that people will actually be using it, or at least trying it out.

## Usage

Run s\*todo to obtain a basic usage message - i.e.:

```
Usage: stodo <command>

commands:
  help [<x>]         show help (on topic <x>, if provided)
  new|init           look for and process new to-do items
  notify             send pending notifications to-do items
  combined           combine notifications with processing of new items
  report             display a report of existing to-do items
  del <h>...         delete targets with handles <h>, ...
  stat <x> <h>...    change status of handles <h>, ... to state-change <x>
  temp [<type>]      output a to-do item template (for target type <type>)
  backup             back up data files
```

### Suggestion

You might want to take a look at scripts/.stodo_utilities; the aliases and
functions in that file are likely to give you some ideas as to how s\*todo
can be used.  And I also suggest you install .stodo_utilities in your home
directory and configure your login environment to source the file so that
you can take advantage of the shortcuts (aliases and functions) that it
creates - e.g., by inserting into your $HOME/.bashrc file:
. ~/.stodo_utilities

## Name

What does the name s\*todo (or, alternatively, s-todo or \*s\*todo) mean?
Obviously, the "todo" part stands for "to do", as in "to do list" (or
"to-do list").  s (or s\*, or \*s\*, for that matter) can stand for:

  - *s*cut work
  - *s*ervices
  - *s*hit
  - *s*teps
  - *s*tudies
  - *s*tuff
  - *s*weating
  - task*s*
  - thing*s*
  - job*s*

In other words, s\*todo (or s-todo or \*s\*todo) can stand for whatever you
feel needs to be done - i.e., "\<my-important-items\> to do".  These items
can be tasks, projects, jobs, meetings, events scheduled for a particular
time, as well as just pieces of information (in \*s\*todo called "memos" or
"notes") that you don't want to forget and, optionally, want to be reminded
of occasionally.  The flexibility of the name is meant to symbolize the
flexibility and extensibility intended for the application itself.
