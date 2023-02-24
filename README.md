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

TBC (To Be Completed)

[Note: Although this might be obvious, the more requests I receive about
how to install and use s\*todo, the more I will be motivated to complete
this section.]

### Required dependencies

  * perl 5.x
  * Modern::Perl module

### Configuration

#### 'config' file

Create a file named 'config' and either place it in
$HOME/.config/stodo/ or set the environment variable STODO\_CONFIG\_PATH  
(e.g., by adding:  
`export STODO_CONFIG_PATH=<your-preferred-path>`  
to your $HOME/.bash\_profile file) to the path you'd like to use and
put the 'config' file in that directory.
(There is an example config file in &lt;stodopath&gt;/doc/config, where
&lt;stodopath&gt; is the location in which you installed the stodo source
code tree.)

#### Required (for now) manual setup

Create the 'data', 'specs', and 'processed\_specs' directories, based on the
value configured for 'datapath' and 'specpath' in your 'config' file -
For example, if datapath is set to /home/user/.stodo/data then run 'mkdir -p'
to create it and 'processed\_specs':

`  mkdir -p /home/user/.stodo/data/processed_specs`

And, for example, if specpath is set to /home/user/.stodo/specs then do:

`  mkdir /home/user/.stodo/specs`

#### Required (for now) - stubbing of gcalcli

Until I get gcalcli working with s\*todo again, it will need to be stubbed -
that is, an empty, executable 'gcalcli' file will need to be created and
configured in the 'config' file.  The following steps are needed:

  * Decide on the location of your stubbed gcalcli file and set "calendarcmd"
    to its path in the 'config' file - e.g.:  
  `calendarcmd = /home/user/bin/gcalcli`
  * Create the empty gcalcli file and make it executable:  
  `touch /home/user/bin/gcalcli`  
  `chmod +x /home/user/bin/gcalcli`


## Usage

Run s\*todo to obtain a basic usage message - i.e.:

    Usage: stodo <command>

    commands:
      help [<x>]         show help (on topic <x>, if provided)
      new|init           look for and process new to-do items
      notify             send pending notifications to-do items
      combined           combine notifications with processing of new items
      report             display a report of existing to-do items
      chparent <h> <ph>  change parent of the item with handle <h> to be the
                         item with handle <ph>. If <ph> is '{none}',
                         the item is set as parentless.
      chhandle <h> <nh>  change handle of the item with handle <h> to <nh>
      change <h> ...     change attribute(s) of item with handle <h>
      add                add a new item
      del <h>...         delete items with handles <h>, ...
      clear_d <h>...     clear descendants of items with handle specs <h>, ...
      remove_d <h> <dh>  find descendant (handle <dh>) of ancestor (handle <h>)
                         and delete it
      clone <h> <nh>     clone item with handle <h> as a new item with handle <nh>
      stat <x> <h>...    change status of handles <h>, ... to state-change <x>
      temp [<type> ...]  output a to-do item template (for target type <type>)
      backup             back up data files

### Suggestion

You might want to take a look at scripts/.stodo\_utilities; the aliases and
functions in that file are likely to give you some ideas as to how s\*todo
can be used.  And I also suggest you install .stodo\_utilities in your home
directory and configure your login environment to source the file so that
you can take advantage of the shortcuts (aliases and functions) that it
creates - e.g., by inserting into your $HOME/.bashrc file:  
. ~/.stodo\_utilities

## Name

What does the name s\*todo (or, alternatively, s-todo or \*s\*todo) mean?
Obviously, the "todo" part stands for "to-do", as in "to-do list".  
s (or s\*, or \*s\*, for that matter) can stand for:

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
feel needs to be done - i.e., ***"my-important-items" to do***.  These items
can be tasks, projects, jobs, meetings, events scheduled for a particular
time, as well as just pieces of information (in \*s\*todo called "memos" or
"notes") that you don't want to forget and, optionally, want to be reminded
of occasionally.  The flexibility of the name is meant to symbolize the
flexibility and extensibility intended for the application itself.
