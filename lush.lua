

--  Copyright (c) 2019 Parke Bostrom, parke.nexus at gmail.com
--  See the copyright notice at the end of this file.
--  Version 0.0.20191228


do    -----------------------  install a new _ENV that can "see through" to _G
  local  _G, mt  =  _G, {}
  function  mt .__index ( t, k )  return _G [ k ]  end
  _ENV  =  setmetatable ( {}, mt )  end


function  cap  ( o, ... )    --------------------------------------------  cap
  o  =  normalize ( o, 'capture', true )
  if  o .rstrip == nil  then  o .rstrip  =  true  end
  --  note  the tail call of sh() is required to scrape the correct locals
  return  sh ( o, ... )  end


function  cat  ( path )    ----------------------------------------------  cat

  --  todo?  remove the asserts, return an error code instead?
  --  or, alternatively, ignore errors if path starts with '-'  ??

  local  f   =  assert ( io .open ( path, 'r' ) )
  local  rv  =  assert ( f : read 'a' )
  f : close()
  return  rv  end


function  cond  ( o, ... )    ------------------------------------------  cond
  --  note  the tail call of sh() is required to scrape the correct locals
  return  sh ( normalize ( o, 'ignore', true ), ... )  end


function  echo  ( s, ... )    ------------------------------------------  echo
  --  temporary kludge?  perhaps echo should have custom expansion?
  local  command  =  expand_command ( s , 2, ... )
  return  print ( command )  end


function  expand_key  ( k, locals )    ---------------------------  expand_key
  return  expand_value ( expand_lookup ( k, locals ), locals )  end


local  nil_flag  =  {}    --  this empty table represents nil


function  expand_lookup  ( k, locals )    ---------------------  expand_lookup
  --  print ( 'expand_lookup  ' .. k )
  function  decode(v)
    if  v == nil_flag  then  return  nil  else  return  v  end  end
  local  v
  v  =  locals [ k ]      ;  if  v ~= nil  then  return  decode(v)  end
  v  =  _G [ k ]          ;  if  v ~= nil  then  return  v          end
  v  =  os .getenv ( k )  ;  if  v ~= nil  then  return  v          end
  return  ''  end


function  expand_string  ( s, locals )    ---------------------  expand_string
  --  print ( 'expand_string  ' .. s )
  assert ( type(s) == 'string' )
  local function  replace  ( k, c )
    if  c == '$'  then  return  k  end
    local  rv  =  expand_key ( k, locals )
    assert ( type(rv) == 'string' )
    return  rv  end
  return  ( s : gsub ( '%$((.)[%w_]*)', replace ) )  end


function  expand_table  ( t, locals )    -----------------------  expand_table
  assert ( type(t) == 'table' )
  local  rv  =  {}
  for  n, v  in  ipairs ( t )  do  rv[n]  =  expand_value ( v, locals )  end
  return  rv  end


function  expand_value  ( v, locals )    -----------------------  expand_value
  if  type(v) == 'string'  then  return  expand_string ( v, locals )  end
  if  type(v) == 'table'   then  return  expand_table  ( v, locals )  end
  error ( 'expand  bad type  ' .. type(v) )  end


function  expand_command  ( o, level, ... )    ---------------  expand_command

  o  =  normalize ( o )

  local  locals  =  {}
  for  n = 1,999  do    --  scrape locals
    local  k, v  =  debug .getlocal ( (level or 1)+1, n )
    if  k == nil  then  break  end
    locals [ k ]  =  v == nil  and  nil_flag  or  v  end

  local function  command  ( o )  return  o[1] : match '^-?(.*)'  end

  local function  flatten  ( t, rv )
    local  rv  =  rv  or  {}
    for  n, v  in  ipairs ( t )  do
      if  type(v) == 'table'
        then  flatten ( v, rv )
        else  table .insert ( rv, quote ( v ) )  end  end
    return  table .concat ( rv, '  ' )  end

  local function  replace  ( k, c )
    if  c == '$'  then  return  k  end
    local  v  =  expand_key ( k, locals )
    if  type(v) == 'string'  then  return  quote   ( v )  end
    if  type(v) == 'table'   then  return  flatten ( v )  end
    error ( ('command  bad type  %s  %s') : format ( k, type(v) ) )  end

  local function  append  ( t, v )
    if  v == nil  then  return  end
    table .insert ( t, quote ( v ) )  end

  local  rv  =  { ( command(o) : gsub ( '%$((.)[%w_]*)', replace ) ) }
  for  n = 2,#o  do  append ( rv, o[n] )  end
  local  varargs  =  { ... }
  for  n = 1,#varargs  do  append ( rv, varargs [ n ] )  end
  return  table .concat ( rv, '  ' )  end


function  import  ()    ----------------------------------------------  import
  _G. lush  =  _G .package .loaded .lush
  local  s  =  'cap  cat  cond  echo  popen  printf  sh  trace'
  for  k  in  s : gmatch '%S+'  do
    _G [ k ]  =  _ENV [ k ]  end  end


function  normalize  ( o, k, v )    -------------------------------  normalize
  assert ( type(o) == 'table'  or  type(o) == 'string' )
  if  type(o) == 'string'  then  o        =  { o }  end
  if  k                    then  o [ k ]  =  v      end
  return  o  end


function  popen  ( o, ... )    ----------------------------------------  popen
  o  =  normalize ( o, 'popen', true )
  if  o .readlines == nil  then  o .readlines  =  true  end
  --  note  the tail call of sh() is required to scrape the correct locals
  return  sh ( o, ... )  end


function  printf  ( format, ... )    ---------------------------------  printf
  io .write ( format : format ( ... ) )  end


function  quote  ( s )    ---------------------------------------------  quote
  assert ( type(s) == 'string', 'quote  bad type  ' .. type(s) )
  if  s == ''  then  return  "''"  end
  return  s : find '[^-%w_./:]'  and
    ( "'" .. s : gsub ( "'", "'\''" ) .. "'" )  or  s  end


function  sh  ( o, ... )    ----------------------------------------------  sh

  o  =  normalize ( o )

  local  command  =  expand_command ( o, 2, ... )

  if  o .trace  then  print ( command )  end

  local  stdout, success, exit, n

  if  o .capture  then
    local  proc       =  io .popen ( command, 'r' )
    stdout            =  proc : read 'a'
    success, exit, n  =  proc : close()
    if  o .rstrip == true  then  stdout  =  stdout : match '^(.-)\n?$'  end

  elseif  o .popen  then
    local  proc       =  assert ( io .popen ( command, 'r' ) )
    local  next_line  =  proc : lines ()
    function  wrap  ()
      local  rv  =  next_line()
      if  rv == nil  then  assert ( proc : close() )  end
      return  rv  end
    return  wrap

  else
    success, exit, n  =  os .execute ( command )  end

  repeat  --  only once
    if  success == true  and  exit == 'exit'  and  n == 0  then  break  end
    if  o .ignore  or  o[1] : match '^-'  then  break  end
    print()
    printf ( 'sh  error\n' )
    printf ( '  command  %s\n', command )
    printf ( '  exit     %s  %s\n', exit, n )
    print()
    error ( ('sh error %s %s') : format ( exit, n ) )
    until  false

  if  o .capture  then  return  stdout,  success, exit, n
  else                  return  success, exit, n  end  end


function  trace  ( o, ... )    ----------------------------------------  trace
  --  note  the tail call of sh() is required to scrape the correct locals
  return  sh ( normalize ( o, 'trace', true ), ... )  end


do    -----------------------------------------  scrape _ENV into shell_module
  local  shell_module  =  {}
  for  k, v  in  pairs ( _ENV )  do  shell_module [ k ]  =  v  end
  return  shell_module  end




--[[-------------------------------------------------------------------------

MIT License

Copyright (c) 2019 Parke Bostrom, parke.nexus at gmail.com

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

----------------------------------------------------------------------------]]
