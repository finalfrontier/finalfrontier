Contributions are welcome
=========================

Thank you for taking an interest in contributing to the project, we need all
the help we can get!

This document will breifly explain the layout of the project so you can jump
right in, and also describe some practices we'd like you to follow to ensure
the code is consistent and easy to follow (and I'll try and stick to it too).

Project Layout
==============

The root directory has the standard three subdirectories for a gamemode;
*content*, *entities*, and *gamemode*. The *content* directory contains the
default map(s) and materials, *entities* holds the in-game items (and some
utility entities used when creating a map to designate certain areas), and
*gamemode* has the remaining game code including the Screen GUI (SGUI) system.

> more details here soon...

Contributing Code
=================

For adding or modifying code, here are some guidelines for keeping coding
style consistency:

Whitespace
----------
* Indent with 4 spaces, no tabs
* Avoid trailing whitespace
* Empty lines should contain no whitespace

Function Identifiers
--------------------
* Global functions should be in CamelCase with a leading upper-case letter.
* Local functions should be in camelCase with a leading lower-case letter.
* Functions bound to a table (for example, entity bound functions) that are
  to be called by code external to the table definition (public methods) must
  match the global function naming rule.
* Functions bound to a table that should only be called by other functions
  bound to that table (private methods) must match the local function naming
  rule, but also have a leading underscore.

Variable Identifiers
--------------------
* Constant variable definitions should be in ALL_CAPS with underscores used
  to separate words.
* Local and global variable definitions should both be in camelCase with a
  leading lower-case letter.
* Fields in a table that are only used by functions bound to that table
  (private fields) should be in camelCase with a leading lower-case letter,
  and prefixed with an underscore.
* Get / Set methods are preferable to directly manipulating fields in a table
  from functions outside of functions bound to that table.
  
> more details here soon...
