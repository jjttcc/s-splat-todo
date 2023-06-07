# .stodo\_utilities

<!---
vim: ts=2 sw=2 expandtab
-->

## Introduction

You can use the *.stodo\_utilities* script (which you'll find in the
*scripts* directory) as an initialization script by sourcing it in
your terminal session. This will create several aliases and convenience
functions that provide some *shortcuts* (so to speak) for using *stodo*.
The most convenient way to do this is to copy the file to your home
directory - e.g.:

`cp scripts/.stodo_utilities ~/`

and then insert a line to source the file in the startup file
for your shell or terminal session. For example, for *bash*, you can add
this line to your *~/.bash\_profile* file:

`. ~/.stodo_utilities`

## Useful facilities

Some of the facilities provided by the .stodo\_utilities file that you may
find useful are described below.

### *swconf*

The *swconf* function will change your *stodo* environment to use a
different *config* file. You can use this facility to keep different
*stodo* databases in different locations and switch between them with
one command. For example, you might keep a separate *stodo* database
for your favorite hobby - say, for example, *stamp collecting*. You
could create a *config* file for your hobby, put it in
*$HOME/hobbies/stamp\_collecting*, and then run:

`swconf $HOME/hobbies/stamp_collecting`

to switch to your *stamp collecting* database. You'll need to edit the
*config* file, of course, for the setup you're using for this *stodo*
database; and you'll need to create the *specs*, *data*, etc. directories
that are defined in that file.

### your personal configuration file: ~/.stodo\_user\_rc

When .stodo\_utilities is sourced it in turn sources the file
*~/.stodo\_user\_rc*, if it exists. You can edit this file to configure
individual settings and preferences, such as email address and preferred
editor.
