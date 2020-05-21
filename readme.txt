
----  ABOUT LUSH  ----

Lush is a pure Lua module for writing POSIX shell script style
programs in Lua.  (A small number of Lush functions depend on
luaposix.)

The primary features of Lush are:

  automatic shell-style string and variable expansion

  the lush.sh() function for creating and interacting with
  subprocesses

  convenience wrappers around the sh() function

Lush is currently experimential.  This means future versions of Lush
may include breaking changes.

[Version 20200521]


----  STRING EXPANSION  ----

Similar to POSIX Shell, Lush supports the expansion of variables
inside of strings.  Variables are prefixed with the dollar sign
character ("$").  For example:

sh 'mkdir $HOME/foo'

In Lush variables are expanded lazily (when a string is used, similar
to GNU Make).  This differs from POSIX Shell where string expansion
occurs immediately (when a string is assigned a value).  Consider the
following Lush example:

local  path  =  '$HOME/foo'    -- path now has the value '$HOME/foo'.
sh 'mkdir $path'               -- The sh() function will expand '$path'
                               --   prior to executing mkdir.

If needed, you can manually force immediate expansion as follows:

local  path  =  expand '$HOME/foo'

Expansion will look for each variable name in the following three
locations:

First, in the local variables of the "parent function".
Second, in the _ENV of the "parent function".
Finally, in the environment variables of the process.

The "parent function" is the function that calls sh() or expand().

During expansion, if a name matches either a local variable or a key
in _ENV, then the corresponding value will itself be expanded.  If a
name matches an environment variable, then the value of that
environment variable will not be expanded.  (It is assumed that
environment variables are already fully expanded.)

Internally, string expansion is performed via the following three
functions:

expand ( v, level, ... )
expand_command ( o, level, ... )
expand_template ( s, level, ... )

In most cases, you do not need to manually call these functions as
sh() and the other functions in Lush will handle expansion for you.

level specfies the level on the stack where the expand functions will
look for local variables and for _ENV.  This is similar to the Lua
debug.getinfo() function.  At present, vararg parameters are not used,
but they may be used in a future version of Lush.

level defaults to 1, signifying the function that called expand().

'$$' expands to itself.  Therefore, expand() can be recalled
repeatedly on the same string without ill effect.  In other words:
expand ( s ) == expand ( expand ( s ) ).

When lush.sh() executes a subprocess, '$$' will be collapsed to '$'
immediately prior to execution of the command.  This collapse only
happens once, and it happens automatically.

Note that an error will be raised if you tail call a function that
expands one or more of its arguments.  A tail call removes the parent
function from the stack.  This makes it impossible for expand() to
find the required locals and _ENV.  (Thankfully, Lua does remember
that a tail call occurred.  Therefore, expand() can at least detect
that a tail call occured and consequently raise an error.  If tail
calls were undetectable, the tail call would silently cause an
incorrect expansion.)


----  FUNCTIONS  ----

basename ( path )

  Expand path, then return its final directory or filename.

cap ( command, ... )

  A convenient way to call sh() with both
    .capture = true and .rstrip = true.
  In other words, expand command, run the expanded command and capture
  its output.  Return the output as a string.  See sh() for details.
  Example usage:  local  ls  =  cap 'ls $path'

cat ( path )

  Expand path, open the file at path, read the file's contents, and
  return the contents as a string.

cat { path, append=text }

  Expand path, open the file at path, append text to the end of the
  file, close the file.  Text can be a string or list of strings.

cat { path, ignore=true }

  Same as cat(path), except will return nil if the file does not
  exist.

cat { path, write=text }

  Expand path, open the file at path, write text to the file, close
  the file.  Text can be a string or a list of strings.

cat { read_keys=path }

  Expand path, open the file at path, read each line, store the lines
  as keys in a table.  Return the table.

cd ( path, trace )

  chdir() to path.  If trace is true, echo 'cd  $path' before calling
  chdir().  cd() depends on the posix.unistd module.

cond ( command, ... )

  A convenient way to call sh() with ignore = true.
  Use with if to test if a program exited normally.
  See sh() for details.
  Example usage:  if cond '[ -f $path ]' then end

count ( n )

  Use with for to loop from n to infinity.
  Expamle usage:  for n in count (20) do end    -- will start counting at 20

dirname ( path )

  Return path after removing the final '/' and all characters after
  it.

each ( t )

  Use with for to loop over each value in a list.
  Example usage:  for n in each { 1, 3, 5 } do end

echo ( s )

  Expand s as a template and print the expansion.  See
  expand_template() for details.
  (Note: In the future, echo()'s implementation may change such that
  expansions will not be quoted.)

expand ( s )
expand ( s, level, ... )

  Expand string s against locals and _ENV from level on the call
  stack.  Return the expanded string.
  level is optional and defaults to 1 (the function that called expand()).
  The vararg ... is not used at present.
  Example usage:  local  path  =  expand '$HOME/foo'

expand_command ( command, level, ... ).

  Expand command against locals and _ENV from level on the call stack.
  Return the expanded command as single string.

  Note: Typically, you do not directly call expand_command().
  Instead, expand_command() is called for you by sh().  However,
  understaing expand_command() will help you reason about command
  expansion.

  Command can be a string.  If command is a string, then command is
  expanded by expand_template().

  Command can be a table (typically, a list).  If the first value in
  the list is a string, that string is expanded by expand_template().
  All other values in the list will be expanded by expand and quoted
  as separate arguments.

expand_template ( template, info )

  Note: Typically, you do not directly call expand_template().
  Typically, expand_command() will call expand_teplate().  However,
  understanding expand_template() can help you reason about command
  expansion.

  template is a string.
  info contains two tables:  The _ENV and a table of scraped locals.

  expand_template() will expand the template against the variables
  contained in info.

  Template expansion is different from normal string expansion as
  follows:

  1) If a string is expanded inside a template, the string will be
  quoted/escaped, if needed, so that the child process will receive
  the entire string as a single argument.

  2) If a table is expanded inside a template, the table will be
  interpreted as a list.  Each elemment of the list will be expanded
  and quoted as a separated argument.

  The table can be a hierarchical tree of lists.  The tree will be
  flattened into a list of strings.  Each string will be expanded and
  quoted as a separate argument.

  Note: You never need to quote the variables in a template.  Lush
  quotes all templte expansions automatically, if needed.  In fact,
  puting your own quote characters in the template is very likely to
  cause the command to execute incorrectly, as your quotes may
  conflict with the automatically generated quotes.

  Example usage:
  local  b  =  'B'
  local  c  =  'C C'
  expand_template 'a $b $c'  --  will return "a B 'C C'"

export ( s )

  export a value to the environment.
  s is a string of the form 'name=value'.
  Example usage:  export 'foo=$bar'
  export() depends on the posix.stdlib module.

getcwd ()

  Return the current working directory.  Depends on posix.unistd.

glob ( pattern )

  Use with for to iterate over paths that match pattern.
  Exapmle usage:  for path in glob '/tmp/*.txt' do end
  Depends on posix.glob.

has  ( t, s )

  If t is a string: has() iterates over patterns in t that match
  '%S+'.  If one of these matches equals s, then has() returns true.
  Otherwise, has() returns false.

  If t is a table: has() returns true if s equals the value of any
  field in t.  Otherwise, has() returns false.

in_list ( k, s )

  in_list() is deprecated.  Please use has() instead.

import ()

  Import common Lush functions into _G.  Return a table of all Lush
  functions (both common and uncommon).
  Example usage:  local lush  =  require 'lush' .import()

is ( s )

  Access the POSIX shell's builtin test command.  This can be used,
  for example, to determine if a file or directory exists.
  Example usage: if is '-f $path' then end

popen ( command, ... )

  A convenient way to call sh() with
    .popen = true and .readlines = true.
  Use with for to iterate over the lines of output of a command.
  See sh() for details.
  Example usage:  for path in popen 'ls' do end

printf ( format, ... )

  io .write ( format : format ( ... ) )

quote ( s )

  Quote string s, allowing it to be passed to a subprocess as a single
  command line argument to that subprocess.  You may never need to
  call quote() directly,, as sh() automatically quotes all expansions
  for you.

sh ( command, ... )
sh { command, [arg ... ] [<option>=true ... ] }

  Execute command as a subprocess.

  command can be a string or a list.

  command will be turned into a single string by expand_command()

  The expanded command will then be executed via os.execute(), or
  when approriate, via io.popen().

  At present, the vararg ... is not used.  This may change in the
  future.  Instead of varag, you can call sh() with a table:
    sh { command, arg1, arg2, arg3 }

  If command is a table, the following six keys are optional:

  If .capture == true, then sh() will capture the child process's
    output and return it as a string.
  If .capture == true and .rstrip == true, then remove the trailing
    newline character from the command's output before returning the
    command's output.
  If .ignore == true, ignore the exit code of the command.
  If .popen == true, return the result of io.popen().
  If .popen == true and .readlines == true, then return an iterator
    over the lines of command's output.
  If .trace == true, print the command before executing it.

  If command starts with the '-' character, then .ignore will be set
  to true.  For example:  sh '-false'

  Unless .ignore == true, sh() will raise an error if the command
  exits with a non-zero exit status.

  By default sh() will return the values returned by os .execute().
  Meaning, sh() will return one of:
    true, 'exit',   exit_status
    nil,  'exit',   exit_status
    nil,  'signal', signal_number

trace ( command, ... )

  A convenient way to call sh() with .trace = true.


----  COMPATIBILITY  ----

Lush is designed to work with Lua 5.3 and may also work with Lua 5.2.
Lush expects os .execute() to call a POSIX shell (that is, a shell
that will interpret quoted arguments in the same way that a POSIX
shell does).

As documented above, several of Lush's functions depend on the
luaposix module.

Several parts of Lush would need to be modified to work with Lua 5.1.
In Lua 5.1, the results of os .execete() may vary by system.  This
could break Lush's ability to detect whether or not commands executed
successfully.  In Lua 5.1, file:close() does not return the exit
status of a process that was created by io.popen.

Regarding using Lush on Windwos, or on other systems with a non-POSIX
shell, this may work if the quote function is adjusted to properly
quote each argument.  Other unknown adjustments migth also be
required.


----  FEEDBACK  ----

Please report bugs at:  https://github.com/parke/lush
You may contact the author at: parke.nexus at gmail.com
