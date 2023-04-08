# s\*todo

## Introduction

s\*todo is yet another to-do application (implemented in ruby, for those
who care).  Its current features include, but are not limited to:

  * Create entries (called *item*s) for tasks, memos, appointments, and projects.
  * Configure time-based notifications/reminders (currently only via email)
    for *item*s.
  * Add a google calendar entry (via gcalcli) for an *item* - e.g., date/time
    of an appointment or due-date for a task.
  * Change the status of an *item*: in-progress, suspended, completed, or
    canceled.
  * List pending *item*s, sorted by due date.
  * Edit *item*s.
  * Delete *item*s.

s\*todo currently only runs on Linux systems, although it would probably be
straightforward to port it to UNIX, including macOS.

## Installation and setup

TBC (To Be Completed)

[Note: Although this might be obvious, the more requests I receive about
how to install and use s\*todo, the more I will be motivated to complete
this section.]

### Required dependencies

  * perl 5.x
  * Modern::Perl module
  * ruby\_contracts (e.g.: gem install ruby\_contracts)
  * activesupport   (e.g.: gem install activesupport)
  * debug           (e.g.: gem install debug)
  * byebug          (e.g.: gem install byebug)
  * awesome\_print  (e.g.: gem install awesome\_print)

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
code tree. You can copy this file to the appropriate place and edit it
to fit your requirements and system.)

Ensure that the 'userpath' setting in the 'config' file is set to your
preferred location - e.g.:

userpath = /home/user/.stodo/user

#### STODO\_PATH environment variable

Set the STODO\_PATH environment variable - in the appropriate place for your
user account - to point to the 'src' directory in which the stodo source
code has been installed on your system. For example, by inserting the line:

export STODO_PATH=$HOME/applications/stodo/src

in:

$HOME/.bash\_profile

in the case in which the main stodo directory is:  
$HOME/applications/stodo/src

#### Required (for now) manual setup

Create the 'data', 'specs', and 'processed\_specs' directories, based on the
value configured for 'datapath' and 'specpath' in your 'config' file -
For example, if datapath is set to /home/user/.stodo/data then run 'mkdir -p'
to create it and 'processed\_specs':

`  mkdir -p /home/user/.stodo/data/processed_specs`

And, for example, if specpath is set to /home/user/.stodo/specs then do:

`  mkdir /home/user/.stodo/specs`

Make sure that the 'userpath' directory (specified in the 'config' file)
exists - e.g.:

   mkdir /home/user/.stodo/user

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


## How to use *stodo*

### Usage

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
      change <h>         change attribute(s) of item with handle <h>
      add                add a new item
      del <h>...         delete items with handles <h>, ...
      clear_d <h>...     clear descendants of items with handle specs <h>, ...
      remove_d <h> <dh>  find descendant (handle <dh>) of ancestor (handle <h>)
                         and delete it
      clone <h> <nh>     clone item with handle <h> as a new item with handle <nh>
      stat <x> <h>...    change status of handles <h>, ... to state-change <x>
      temp [<type> ...]  output a to-do item Template (for target type <type>)
      backup [opts]      back up data files
      proca <h>...       Process attachments for items with handles <h>...
      version            print Version number and exit

### Attachments

#### Basics

Attachments (the *attachments* field of an item) can be specified (e.g., with
the *-at* option of the *add* or *change* command [***stodo add ...*** or
***stodo change ...***]) for an item. The attachments for an item, if there are any,
are listed by default with the *stodo report complete* (or
*stodo rep comp <item-handle>*, where *rep* and *comp* are abbreviations for
*report* and *complete*, respectively)

#### Actions on attachments (*proca* option)

Attachments can be "*processed*" via the *proca* command.  i.e.:

    stodo h proca
    Usage: stodo proca <handle> [...] [options]
    Options:
      -v       "view" the attachment (i.e., read-only)
      -e       "edit" (modify) the attachment

*proca* invokes on each attachment of an item the appropriate *viewer*
(-v option) or *editor* (-e option) for the attachment, as specified
according to the file type in the 'config' file. (See the section starting
with the comment "# Paths to executables for various types ..." in the
example config file, *doc/config*, for more info.)

When the appropriate executable (i.e., *viewer* or *editor*) is invoked, it
is started as a background process with the environment variable
***STODO_HDL*** set to the handle of the item whose attachment is being
processed in order to make the handle available for use by the invoked
executable.

#### Invoking the *.stodo-shell* file on directories

If the attachment is a directory, *stodo* looks for a file in that directory
named *.stodo-shell*. If the file exists and if it is a regular file,
is readable, and is executable, it is invoked as a UNIX/Linux command
(i.e., a script or a binary executable file). The file/executable is invoked
with one command-line argument, which is the name of the attachment - i.e.,
the directory that is being processed[1]. Here is an example .stodo-shell
script:

    #!/bin/bash

    attachment=$1
    if [ "$STODO_HDL" ]; then
        tmpfile=/tmp/$STODO_HDL-$$
        stodo rep comp $STODO_HDL >$tmpfile
        gvim -p -geometry +0+0 -c \
            'set lines=65 columns=146 guifont=Monospace\ 26' $tmpfile $attachment
    fi

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


## Notes

[1] This is redundant, of course, since it is easy for the invoked program
to obtain the current directory. However, an obvious enhancement to the
*.stodo-shell* feature is to pass in the entire list of attachments for
the target item as command-line arguments.
