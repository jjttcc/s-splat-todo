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

### Installation and Configuration

Some manual setup is currently required. This may be automated in the
future, depending on how many requests I get for this.

#### Clone s\*todo and install the main *stodo* script

First, clone the *s\*todo* repository:

`git clone https://github.com/jjttcc/s-splat-todo`

cd to the cloned directory:

`cd ./s-splat-todo/`

Copy the *stodo* script to a directory that is in your $PATH, such as
$HOME/bin:

`cp src/stodo $HOME/bin/`

#### STODO\_PATH environment variable

Set the STODO\_PATH environment variable - in the appropriate place for your
user account - to point to the 'src' directory in which the stodo source
code has been installed on your system. For example, by inserting the line:

export STODO_PATH=$HOME/applications/stodo/src

in:

$HOME/.bash\_profile

in the case in which the main stodo directory is:  
$HOME/applications/stodo

#### 'config' file

Decide where to put the *config* file - You can either place it in
the default location - $HOME/.config/stodo/ - or set the environment
variable STODO\_CONFIG\_PATH
to a location where you intend for the *config* file to reside. Then
copy the sample config file, doc/config, from the main *stodo* directory
($STODO\_PATH/../) to your chosen location.
For example, for the default location, from the main *stodo* directory:

`cp doc/config $HOME/.config/stodo`

(Make sure you create this directory if it doesn't yet exist.)
Next, edit the *config* file to fit your particular environment and
preferences, as described below.

##### *userpath*

Ensure that the 'userpath' setting in the 'config' file is set to your
preferred location - e.g.:

userpath = /home/user/.stodo/user

#### Configuring your email service

##### Choose an email client and configure it to send emails

If you don't already have an email client with a command-line interface
configured to send emails to
recipients on the internet, you will need to choose a client (such as
*elm* or *mutt*), make sure it is installed on your system, and configure
it to send emails from the computer on which you will run *stodo*.

##### config file: *emailtemplate* setting

The *emailtemplate* value needs to be set in the *config* file according
to the expected command-line format of your chosen email client - e.g.:  
> `emailtemplate = mutt -s <subject> <addrs>`  

This configuration for *mutt* tells *stodo* where to place the *subject*
and email-address arguments when invoking *mutt* to send email. You will
need to adapt this setting to what your email client expects,
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

#### Backup directory

Create a backup directory - e.g.:  
`mkdir /home2/user/backups/stodo`  

And set the *backuppath* to that path in the *config* file - e.g.:  
`backuppath = /home2/user/backups/stodo`

<!---
{This section is obsolete: gcalcli is no longer used.}
#### Disabling of gcalcli

Until I get gcalcli (python command-line interface to google calendar) working
with s\*todo again, it will need to be disabled. This can be done by
simply commenting out, or deleting, the *calendarcmd* line in the config
file e.g.:  

`   #calendarcmd = /home/user/lib/python2/bin/gcalcli`
-->

#### Run *bundle* to install the dependencies specified in the Gemfile

In the main *stodo* directory, where the *Gemfile* resides, execute[2]:  

> `rm Gemfile.lock`  
> `gem install bundler  # (if bundler is not already installed)`  
> `bundle install`

#### Install the perl-library dependencies

install *cpan* - e.g.:  
> `sudo dnf install cpan`  
or:  
> `sudo apt-get install cpan`

Then install *Modern::Perl* and *Date::Manip*
> `cpan Modern::Perl`  
> `cpan Date::Manip`

#### Setting up a *crontab* file for notifications and backups

For timely notifications and backups, you'll need to configure a
job-scheduling daemon such as *cron* to run *stodo* periodically.
Here is an example crontab entry that I use to run *stodo*
every 5 minutes to both trigger any pending notifications and look in
the *specpath* for new or modified *stodo* entries to be processed:

`*/5 * * * * . $HOME/.stodo/env; STODO_PATH=/home/development/user/s-todo/src $HOME/bin/stodo combined >/tmp/stodo-outerr.$$ 2>&1`  

And this is an example crontab entry for executing *stodo*'s *backup*
feature four times an hour:

`2,17,32,47 * * * * . $HOME/.stodo/env; STODO_PATH=/home/development/user/s-todo/src $HOME/bin/stodo backup >/tmp/stodo-backup-outerr.$$ 2>&1`

You'll need to add similar lines to your crontab file for notifications and
backups.
If you use a job-scheduling system other than *cron* you will need to
configure equivalent settings in that system.
See the *doc/env* file for an example *env* file (i.e., used in the  
`. $HOME/.stodo/env`  
part of both *crontab* entries). A lot of those
settings, I believe, are obsolete and you won't need; but to save the time
it would take to figure out which ones are not needed,
it's probably safe just to leave them in the file.

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
***STODO\_HDL*** set to the handle of the item whose attachment is being
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

### .stodo\_utilities

The file *scripts/.stodo\_utilities* is a bash script file that defines
several aliases and convenience functions. You'll likely find some or many
of these facilities useful. An easy way to use the script is to first copy
it to your $HOME directory and then source it
from your user profile file - for example, for *bash* and other *sh-based*
shells, you can insert this line at an appropriate place in your
profile file (*~/.bash\_profile*, in the case of bash):

`. ~/.stodo_utilities`

You can find documentation on the *.stodo\_utilities* file in:  
`scripts/README.md`  

Note that currently this document is small and very incomplete, so, if
you're so inclined, you might want to take a look at the
*.stodo\_utilities* file to get a sense of what's available and what
facilities might be useful to you.

## Name

What does *s* in s\*todo (or *stodo*) stand for?
Well, it stands for whatever you want it to stand for, since *stodo* is
open source and is, if you use it, essentially, *your* software.
So you can think of the *s* as meaning any of:

  - ***s***tuff
  - ***s***teps
  - ***s***tudies
  - ***s***hit
  - ***s***weating

And even, if you like:

  - task***s***
  - thing***s***
  - job***s***

Or whatever word you would like to use for work that, whether truly
important or not, needs to be done - either right away, or at some point
before *too much* time has passed.

## Notes
[1] Adding a web interface to *stodo* is probably doable, but it would take
a good deal of effort and time, the latter of which I appear not to have
enough of these days.  
[2] I ran into problems when running these commands on Fedora 38 with the
default 'gem' and 'bundler'. If you run into problems as well on your
distribution and don't want to troubleshoot them, you can do what I did
in my test install and switch to using *rvm*. If you do this, simply
follow the instructions at:  
https://rvm.io/rvm/install  
I had problems using the *--ruby* option while installing the stable version
of *rvm*, so I recommend, as I did, omit that option:  

`\curl -sSL https://get.rvm.io | bash -s stable`  

Then activate the environment set up by the *rvm* install (e.g., by logging
off and then back on). And then you can install ruby (the latest or
whatever version you prefer) to override the system ruby, e.g.:  
`rvm install 3.2.2`  
(See *https://rvm.io/rubies/installing*)

After that you should be able to remove the lock file and run
`bundle install`:  
> `rm Gemfile.lock`  
> `bundle install`  
