# s\*todo

<!---
vim: ts=2 sw=2 expandtab
-->
<!---
!!!!to-do: Add info about {none} spec
-->
<!---
A pretty good example of README - headings, format:
https://github.com/Ircam-WAM/Mezzo
-->

## Introduction

s\*todo is a to-do application. It is solely command-line-based[1].
Its current features include:

  * Create entries (called *item*s) for tasks, memos, appointments,
    and projects.
  * Configure time-based notifications/reminders (currently only via email)
    for *item*s.
  * Change the status of an *item*: in-progress, suspended, completed, or
    canceled.
  * List pending *item*s, sorted by due date.
  * Editing of *item*s with an editor or from the command line.
  * Grepping - search for all *item*s that match a keyword or regular
    expression.
  * Version control of *item*s with *git*.
  * Processing of file attachments.
  * *item* hierarchies for organization/classification.
  * *references* to other *item*s.
<!---
!!!!to-do: Get this working again and put the list item back in:
  * Add a google calendar entry (via gcalcli) for an *item* - e.g., date/time
    of an appointment or due-date for a task.
-->

s\*todo currently only runs on Linux systems, although it might be
pretty straightforward to port it to other UNIXes, including macOS.

## Use cases

  * As a *to-do* list tool: Keep track of your planned items - projects, tasks,
    appointments, memoranda, etc. Send yourself reminders (daily, weekly,
    on a specified date/time, etc.) for items you deem important.
    Prioritize your projects and tasks - e.g., send a monthly or even
    yearly reminder for a somewhat unimportant task that you, nevertheless,
    don't want to completely forget about.
  * As a study aid - For example, I use it to organize and keep track of
    different aspects or components of my Mandarin study, such as
    listening, reading, speaking, writing, and grammar. As well, I use its
    "process-attachments" facility to begin a study session - for example, I
    invoke the facility on the attachments (Mandarin text files and audio or
    video files) of a "Mandarin study task" to study a story in my lesson
    plan.
  * To play music, by invoking the "process-attachments" on a music *item*
    whose attachments are audio/music files. Or to watch a movie on an
    *item* with video attachments.
  * To keep track of and/or archive data that one doesn't want to
    lose, such as: past events in one's life; one's family genealogy; tips,
    howtos, and URLs for, for example, software development and technology,
    medicine or any other field; birthdays of family members and
    friends; etc.
  * To plan iterations for a software project and keep track of what was
    done on past iterations.
  * If you want to change an *item* but don't want to lose the original
    content, you can run *stodo gitadd <itemhandle>* to put it under
    git-based version control.
  * Etc.

## Installation and setup

### Required dependencies

#### Ruby dependencies

  * ruby 2.x or ruby 3.x
  * ruby\_contracts
  * activesupport
  * debug
  * byebug
  * awesome\_print
  * git

#### Non-Ruby dependencies

  * perl 5.x
  * Modern::Perl module


### Configuration

Some manual setup is currently required. This may be automated in the
future, depending on how many requests I get for this.

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

#### Configuring your email service

##### Choose an email client and configure it to send emails

If you don't already have an email client configured to send emails to
recipients on the internet, you will need to choose a client (such as
*elm* or *mutt*), make sure it is intalled on your system, and configure
it to send emails from the computer on which you will run *stodo*.

##### config file: *emailtemplate* setting

The *emailtemplate* value needs to be set in the *config* file, according
to the expected command-line format of your chosen email client - e.g.:  
> `emailtemplate = mutt -s <subject> <addrs>`  

This configuration for *mutt* tells *stodo* where to place the *subject*
and email-address arguments when invoking *mutt* to send email. You will
need to adapt this setting to what your email command-line client expects,
if it is different. If you don't want to use email, or want to configure it
at a later time, you can disable email by deleting this setting (or
commenting it out by Inserting a '#' at the beginning of that line) or
simply setting it to no value - i.e.:  
> `emailtemplate =`

#### Manual setup

Create the 'data', 'specs', and 'processed\_specs' directories, based on the
value configured for 'datapath' and 'specpath' in your 'config' file -
For example, if datapath is set to /home/user/.stodo/data then run 'mkdir -p'
to create it and 'processed\_specs':

`  mkdir -p /home/user/.stodo/data/processed_specs`

And, for example, if specpath is set to /home/user/.stodo/specs then do:

`  mkdir /home/user/.stodo/specs`

Make sure that the 'userpath' directory (specified in the 'config' file)
exists - e.g.:

`   mkdir /home/user/.stodo/user`

Finally, copy the ***stodo*** script in the *stodo* *src* directory to
a location that is in your $PATH - for example, $HOME/bin or
/usr/local/bin. For example, if you have set the STODO_PATH variable,
as described above and you want ***stodo*** script to reside in your
home *bin* directory, you can do this:

`   cp $STODO_PATH/stodo ~/bin`

#### Disabling of gcalcli

Until I get gcalcli (python command-line interface to google calendar) working
with s\*todo again, it will need to be disabled. This can be done by
simply commenting out, or deleting, the *calendarcmd* line in the config
file e.g.:  

`   #calendarcmd = /home/user/lib/python2/bin/gcalcli`

#### Run *bundle* to install the dependencies specified in the Gemfile

In the directory where the *Gemfile* resides, execute:  

> `gem install bundler`  
> `bundle install`

#### Install the perl-library dependencies

install *cpan* - e.g.:  
> `sudo dnf install cpan`  
or:  
> `sudo apt-get install cpan`

Then install *Modern::Perl* and *Date::Manip*
> `cpan Modern::Perl`  
> `cpan Date::Manip`

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
      del                delete the specified items
      clear_d <h>...     clear descendants of items with handle specs <h>, ...
      remove_d <h> <dh>  find descendant (handle <dh>) of ancestor (handle <h>)
                         and delete it
      clone <h> <nh>     clone item with handle <h> as a new item with handle <nh>
      stat <x> <h>...    change status of handles <h>, ... to state-change <x>
      temp [<type> ...]  output a to-do item Template (for target type <type>)
      backup [opts]      back up data files
      proca <h>...       process attachments for items with handles <h>...
      git-<cmd>          perform the specified 'git' operation: <cmd>
      version            print Version number and exit

### Attachments

#### Basics

Attachments (the *attachments* field of an item) can be specified (e.g., with
the *-at* option of the *add* or *change* command) for an item.
The attachments for an item, if there are any,
are listed by default with the ***stodo report complete*** command.

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
example config file, *doc/config*, for some example settings.)

When the appropriate executable (i.e., *viewer* or *editor*) is invoked, it
is started as a background process with the environment variable
***STODO_HDL*** set to the handle of the item whose attachment is being
processed in order to make the handle available for use by the invoked
executable.

#### Invoking the *.stodo-shell* file on directories

If, during a *proca* action, an attachment is a directory (an
*attachment-directory*), *stodo* looks for a file in that directory
named *.stodo-shell*. If the file exists and if it is a regular file,
is readable, and is executable, it is invoked as a UNIX/Linux command
(i.e., a script or a binary executable file). The file/executable is invoked
with the paths to the item's attachments as arguments.  Here is an example
.stodo-shell script:

    #!/bin/bash

    attachments=$*
    if [ "$STODO_HDL" ]; then
        tmpfile=/tmp/$STODO_HDL-$$
        stodo rep comp $STODO_HDL >$tmpfile
        gvim -p -geometry +0+0 -c \
            'set lines=65 columns=146 guifont=Monospace\ 26' $tmpfile $attachments
    fi

#### Suppress actions with *.stodo-suppress-actions* file

Like the *.stodo-shell* file, during a *proca* action, *stodo* also looks in
an *attachment-directory* for a file named
*.stodo&#x2011;suppress&#x2011;actions*.
If this file exists, any actions that would otherwise be carried out on
attachments that reside in that directory will be suppressed.
However, invocation of
a *.stodo-shell* file, if it exists and is valid, will not be suppressed.
Thus the purpose of a *.stodo-suppress-actions* file is either to cause
*stodo* to invoke (execute) a valid *.stodo-shell* file while performing no
other actions in that directory, or, if there is no
*.stodo-shell* file, to simply suppress all *proca* actions that would
normally occur on attachment files that reside in that directory.

### .stodo_utilities

The file *scripts/.stodo_utilities* is a bash script file that defines
several aliases and convenience functions. You'll likely find some or many
of these facilities useful. An easy way to use the script is to first copy
it to your $HOME directory and then source it
from your user profile file - for example, for *bash* and other *sh-based*
shells, you can insert this line at an appropriate place in your
profile file (*~/.bash_profile*, in the case of bash):

`. ~/.stodo_utilities`

Unfortunately, there is no separate documentation for *.stodo_utilities*.
You'll need to look through the file, especially the comments for function
headers and aliases, to glean what could be useful for you.

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
[1] Adding a web interface to *stodo* is probably doable, but it would take
a good deal of effort and time, the latter of which I appear not to have
enough of these days.
