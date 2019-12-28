

----  ABOUT LUSH  ----

Lush is an experimential pure Lua module for writing POSIX shell script
style programs in Lua.

In the opinion of Lush's author, when compared to POSIX shell, Lua has
at least the following advantages:

  -  Lua's syntax is cleaner
  -  Lua's data structures are more robust
  -  Lua's string manipulation is cleaner and more powerful

However, POSIX shell also has some advantages.  POSIX shell includes
task specific features and capabilities that Lua intentionally lacks.
Additionally, POSIX shell allows many tasks to be written very
compactly and concisely.

Lush grants the Lua programmer convenient and concise access to a
significant portion of POSIX shell's useful features and capabilities.

Lush is currently experimential.  This means future versions of Lush
may include breaking changes.

Lush primarily consists of the following nine functions:

sh()  -  execute a command in a variety of ways

Four convenience wrappers around sh():

cap()    -  capture the entire output of a command
cond()   -  return true if a command exits with a status 0
popen()  -  capture the output of a command, one line at a time
trace()  -  print the command before executing it

Three other convenience functions:

cat()     -  read and return the entire contents of a file
echo()    -  print with expansion of $-varibales
printf()  -  print with formatting

One conveient loader function:

import()  -  a convenient way to load lush and the above functions into _G


----  THE sh() FUNCTION  ----

lush .sh ( o, ... )

The sh() function executes a command.  The command will be executed
(by deafualt) via os .execute() or (optionally) via io .popen.

o can be a string or a table.

If o is a string, then it is a command that will be expanded (see
STRING EXPANSION below).

If o is a table, then o[1] is a string command that will be expanded.
If they exist, o[2] to o[n] will be quoted (escaped), but not
expanded, and then appended to the command.

If any ... varargs exist, they will be quoted (escaped), but not
expanded, and then appended to the command.  Varags are appened after
o[2] to o[n].

By default, if the command terminates abnormally, or if the exit
status of the command is not zero, then sh will raise an error.  (In
the current experimental implementation, sh() also prints a diagnostic
error message prior to raising the error.)

However, if the command begins with the '-' charater, then (similar to
GNU make) the '-' character will be removed from the beginning of the
command and abnormal termination and a non-zero exit status will both
be ignored.  (No error will be raised.  No diagnostic message will be
printed.)

By default, sh() will return the same values returned by os .execute().

Additional options to sh() are passed as key-value pairs in o.

o .capture:  if true, the command will be executed via io .popen() and
the output of the process will be read into a string.  In this case,
sh() will return the four values: output, success, exit_type,
exit_status.

o .ignore:  if true, neither abnormal termination nor a non-zero exit
status will cause sh() to raise an error.

o .popen:  if true, sh() will call and return the result of io
.popen().

o .readlines:  if true, and if o .pope is also true, sh() will call
(and return the result of) the readlines() method of the process
returned by io .popen().  In other words, sh() will return an iterator
over the lines of the output of the command.

o .rstrip:  if true, and if o .capture is also true, the sh() will
remove the final newline character from the captured ouput.

o .trace:  if true, sh() will print the expanded command prior to
executing it.

Various of the above options can be combined.  However, combining
capture with popen is nonsensical.


--  STRING EXPANSION  --

Lush perfroms string expansion on commands prior to executing them.
Lush's expansion is insprired by POSIX shell expansion (i.e. $name
will expand), but there are significant differences.  Hopefully,
Lush's expansions are easier to use and maintain.

Lush will expand $<varname> inside the command string.  Lush will
search for varname:

  -  first in the local variables of the function that called sh()
  -  then in the global variables
  -  finally in the environment variables.

Let's consider some examples:

--  Begin Lua code  --

require 'lush' .import()

src   =  '/tmp/foo'
dest  =  '/tmp/bar'

--  Some simple examples

sh 'date > $src'      --  create /tmp/foo
sh 'cp $src $dest'    --  copy '/tmp/foo' to '/tmp/bar'

--  Unlike POSIX shell, expansions will be automatically quoted if
--  needed.  With expansions, Lush chooses safety over power.  (If you
--  need to do powerful string manipulations, do them in pure Lua.)

dest2  =  '/tmp/bar 2'

sh 'cp $src $dest2'    --  copy '/tmp/foo' to '/tmp/bar 2'

--  Consequently, you cannot expand multiple arguments in a single
--  string.

src  =  '/tmp/foo1'
src  =  src .. '  /tmp/foo2'

sh 'cp $src /tmp/subdin'    --  This will copy the single file at path
                            --  '/tmp/foo1 /tmp/foo2' to
                            --  '/tmp/subdir'.
                            --
                            --  Note:  In the above, '/tmp/foo1  '
                            --  would be a directory!

--  However, you can expand multiple arguments by using a table.

sources = { '/tmp/foo1' }
table .insert ( sources, '/tmp/foo2' )

sh 'cp $sources /tmp/subdir'    --  This will expand to:
                                --  cp /tmp/foo1 /tmp/foo2 /tmp/subdir

--  End Lua code  --

String expansion is performed via the lush .expand_command() function.
You are encourarged to gain experience with how Lush expands commands
by experimenting with expand_command() in Lua's interactive
interpreter.


----  CONVENIENCE WRAPPERS AROUND sh()  ----


lush .cap ( o, ... )

The cap() wraps sh().  if o .capture == nil then cap() will set
o .capture = true before calling sh().

Example usage:  local date  =  cap 'date'


lush .cond ( o, ... )

The cond() function calls sh ( o, ... ).  cond() will return true if
sh() terminates normally and the exit status is zero.

Example usage:  if  cond '[ -d $dir ]'  then  do_something()  end


lush .popen ( o, ... )

If o .popen == nil, then popen() will set both o .popen and
o .readlines to true.  popen() will then call and return sh ( o, ... ).

Example usage:
for  line  in  popen 'egrep ^root /etc/passwd'  do  print ( line )  end


lush .trace ( o, ...)

If o .trace == nil, then popen() will set o .trace to true.  trace()
will then call and return sh ( o, ... ).


----  OTHER FUNCTIONS  ----


lush .cat ( path )

The cat() function will open and read the entire file at path.  cat
will then return the file's contents as a string.


lush .echo ( s, ... )

The echo function will expand the string s and print the result.
(Currently, expansion is done via expand_command(), but this may
change in the future.)

Example usage:  echo 'My home directory is:  $HOME'


lush .printf ( format, ... )

The function printf() is defined as:
return  io .write ( format : format ( ... ) )

Example usage:  printf ( 'Hello, %s!\n', 'world' )


lush .import ()

The import() function loads the lush module and 8 of its functions
into the global table _G.  The 7 function are: cap, cat, cond, echo,
popen, printf, sh, and trace.

Exmaple usage:  require 'lush' .import()


lush .expand_command ( o, level, ... )

Example usage:
local foo  =  'bar'
print ( lush .expand_command ( '$foo', 1 )

The expand_command() function returns a command as a single string.
level is the stack level at which local variables will be looked up.
1 is the level of the function that called expand_command().  2 is the
function that called that function, etc.


----  FEEDBACK  ----

Please report bugs at:  https://github.com/parke/lush
You may contact the author at: parke.nexus at gmail.com
