

--  Copyright (c) 2020 Parke Bostrom, parke.nexus at gmail.com
--  See the copyright notice at the end of this file.


do    --------------------------------------------------  module encapsulation
  --  install a new _ENV that can "see through" to _G
  local  _G, mt  =  _G, {}
  function  mt .__index ( t, k )  return _G [ k ]  end
  _ENV  =  setmetatable ( {}, mt )  end


version  =  '0.0.20200521'


function  assert_no_varargs  ( ... )    -------------------  assert_no_varargs
  assert ( select ( '#' , ... ) == 0, select ( '#', ... ) )  end


function  basename  ( path )    ------------------------------------  basename
  path  =  expand ( path, 2 )
  return  path : match '^.*/([^/]*)$'  end


function  cap  ( o, ... )    --------------------------------------------  cap
  return  sh ( normalize ( o, 2, 'capture', true, 'rstrip', true ), ... )  end


function  cat  ( o, ... )    --------------------------------------------  cat

  --  usage:  cat ( path )                 --  read file, return as string
  --          cat { path, append=text }    --  append text to file
  --          cat { path, ignore=true }    --  return nil on file not found
  --          cat { path, write=text }     --  write text to file
  --          cat { path, update=text }    --  on diff, write text to file
  --          cat { read_keys=path }       --  read lines as table keys

  assert_no_varargs ( ... )

  local function  open_write  ( path, mode, text )
    if  type(text) == 'string'  then
      local  f  =  assert ( io .open ( path, mode ) )
      assert ( f : write ( text ) )
      f : close()  ;  return  end
    if  type(text) == 'table'  then
      local  f  =  assert ( io .open ( path, mode ) )
      for  s  in  each ( text )  do
        assert ( type(s) == 'string' )
        assert ( f : write ( s ) )  end
      f : close()  ;  return  end
    error ( 'cat  open_write  bad type  ' .. type(text) )  end

  local function  append  ( path, o )
    --  return   cat_write ( o, expand ( o .append, 3 ), 'ab' )  end
    return  open_write ( path, 'ab', o .append )  end

  local function  plain  ( path, o )
    --  todo?  remove the asserts, return an error code instead?
    --  or, alternatively, ignore errors if path starts with '-'  ??
    local  f, err  =  io .open ( path, 'r' )
    if  f  then
      local  rv  =  assert ( f : read 'a' )
      f : close()  ;  return  rv
    elseif  ( o  and  o .ignore  and
              err == path ..': No such file or directory' )  then
      return  nil
    else  error ( err )  end  end

  local function  read_keys  ( path, o )
    local  f     =  assert ( io .open ( path, 'rb' ) )
    local  rv    =  {}
    for  line  in  f : lines()  do  rv [ line ]  =  line  end
    f : close()
    return  rv  end

  local function  write  ( path, o )
    --  return   cat_write ( o, expand ( o .stdout, 3 ), 'wb' )  end
    return  open_write ( path, 'wb', o .write )  end

  local function  update  ( path, o )
    local  f  =  io .open ( path, 'wb' )
    if  f  then
      local  actual  =  f : read 'a'  ;  f : close()
      if  actual == o.update  then  return  end  end
    open_write ( path, 'wb', o.update )  end

  if  type ( o ) == 'string'  then
    local  path  =  expand ( o, 2 )
    return  plain ( path )  end

  if  type ( o ) == 'table'  then
    assert ( # o == 1, 'cat  error  # o ~= 1  ' .. # o )
    assert ( type(o[1]) == 'string', 'cat  bad type  ' .. type(o[1]) )
    local  path  =  expand ( o[1], 2 )
    if  o .append     then  return  append    ( path, o )  end
    if  o .read_keys  then  return  read_keys ( path, o )  end
    if  o .write      then  return  write     ( path, o )  end
    if  o .update     then  return  update    ( path, o )  end
    if  o .ignore     then  return  plain     ( path, o )  end end

  error  'cat failed'  end


function  cd  ( path, trace )    -----------------------------------------  cd
  path  =  expand ( path, 2 )
  --  local  lfs  =  require 'lfs'
  local  unistd  =  require 'posix.unistd'
  if  trace  then  echo 'cd  $path'  end
  return  assert ( unistd .chdir ( path ) )  end


function  collapse  ( s )    ---------------------------------------  collapse
  return  s : gsub ( '%$%$', '$' )  end


function  cond  ( o, ... )    ------------------------------------------  cond
  return  sh ( normalize ( o, 2, 'ignore', true ), ... )  end


function  count  ( n )    ---------------------------------------------  count
  --  count from n to infinity and beyond
  local function  iter  ( state, n )  return  n + 1  end
  return  iter, nil, n-1  end


function  dirname  ( s )    -----------------------------------------  dirname
  return  s : match '^(.*)/'  end


function  each  ( t )    -----------------------------------------------  each
  if  type(t) == 'function'  then  t  =  t()  end
  assert ( type(t) == 'table', type(t) )
  local function  iter  ( st )
    local  rv  ;  st[2], rv  =  next ( st[1], st[2] )
    return  rv  end
  return  iter, {t,nil}, nil  end


function  echo  ( s, ... )    ------------------------------------------  echo
  --  temporary kludge?  perhaps echo should have custom expansion?
  if  s == nil  then  print()  ;  return  end
  local  command  =  collapse ( expand_command ( s , 2, ... ) )
  return  print ( command )  end


local  nil_flag  =  {}    --  this empty table represents nil


function  expand_check ( o )    --------------------------------  expand_check
  assert ( type(o)        == 'table' )
  assert ( type(o.env)    == 'table' )
  assert ( type(o.locals) == 'table' )  end


function  expand_key  ( k, o )    --------------------------------  expand_key
  expand_check ( o )

  --  print ( 'expand_key  ' .. k )

  function  decode  ( k, v )
    if  v == nil_flag  then
      --  print ( 'expand_key  warning  is nil  ' .. k )
      end
    if  v == nil_flag  then  return  nil  else  return  v  end  end

  local  loc, env, get, ev  =  o.locals, o.env, os.getenv, expand_value
  local  v
  v  =  loc [ k ]  ;  if  v ~= nil  then  return  ( ev(decode(k,v),o) )  end
  v  =  env [ k ]  ;  if  v ~= nil  then  return  ( ev(v,o)           )  end
  v  =  get ( k )  ;  if  v ~= nil  then  return  v                      end
  return  ''  end


function  expand_string  ( s, o )    --------------------------  expand_string
  expand_check ( o )
  --  print ( 'expand_string  ' .. s )
  assert ( type(s) == 'string' )
  local  k  =  s : match '^$([%w_]+)$'
  if  k  then
    local  rv  =  expand_key ( k, o )
    --  print ( 'expand_string', k, rv )
    return  rv end
  local function  replace  ( all, k, c )
    if  c == '$'  then  return  all  end
    local  rv  =  expand_key ( k, o )
    if  rv == false  then  rv  =  ''  end
    if  type(rv) ~= 'string'  then
      print  ''
      print  'expand_string  failed  bad type in expansion'
      print  ( '  s   ' .. s )
      print  ( '  k   ' .. k )
      print  ( '  rv  ' .. tostring ( rv ) )
      print  ''  end
    assert ( type(rv) == 'string', s .. '  ' .. type(rv) )
    return  rv  end
  return  ( s : gsub ( '(%$((.)[%w_]*))', replace ) )  end


function  expand_table  ( t, o )    ----------------------------  expand_table
  expand_check ( o )
  assert ( type(t) == 'table' )
  local  rv  =  {}
  for  n, v  in  ipairs ( t )  do  rv[n]  =  expand_value ( v, o )  end
  return  rv  end


function  expand_value  ( v, o )    ----------------------------  expand_value
  expand_check ( o )
  if  type(v) == 'function'  then  v  =  v()  end
  if  type(v) == 'number'    then  return  ( tostring ( v )           )  end
  if  type(v) == 'string'    then  return  ( expand_string   ( v, o ) )  end
  if  type(v) == 'table'     then  return  ( expand_table    ( v, o ) )  end
  if  v       == false       then  return  false  end
  if  v       == nil         then  return  nil    end
  error ( 'expand  bad type  ' .. type(v) )  end


function  expand  ( s, level, ... )    -------------------------------  expand
  assert ( type(s) == 'string' )
  assert ( type(level) == 'nil'  or  type(level) == 'number', type(level) )
  assert_no_varargs ( ... )
  local  info  =  info_scrape ( ( level or 1 ) + 1 )
  return  expand_string ( s, info )  end


function  expand_template  ( s, info )    -------------------  expand_template

  assert ( type(s) == 'string' )
  expand_check ( info )

  local function  command  ( s )  return  s : match '^-?(.*)$'  end

  local function  flatten  ( t, rv )
    local  rv  =  rv  or  {}
    for  n, v  in  ipairs ( t )  do
      if  v == false  then    --  do nothing
      elseif  type(v) == 'string'  then  table .insert ( rv, quote ( v ) )
      elseif  type(v) == 'table'   then  flatten ( v, rv )
      else  error ( 'bad type  ' .. type(v) )  end  end
    return  table .concat ( rv, '  ' )  end

  local function  replace  ( k, c )
    if  c == '$'  then  return  k  end
    local  v  =  expand_key ( k, info )
    if  v == false           then  return  ''  end
    if  v == nil             then  return  ''  end
    if  type(v) == 'string'  then  return  ( quote   ( v ) )  end
    if  type(v) == 'table'   then  return  ( flatten ( v ) )  end
    error ( ('command  bad type  %s  %s') : format ( k, type(v) ) )  end

  return  ( command(s) : gsub ( '%$((.)[%w_]*)', replace ) )  end


function  expand_command  ( o, level, ... )    ---------------  expand_command

  assert_no_varargs ( ... )

  local  function  flatten_and_quote  ( v, rv )
    rv  =  rv  or  {}
    if  v == false  then  --  do nothing
    elseif  type(v) == 'string'  then  table .insert ( rv, quote ( v ) )
    elseif  type(v) == 'table'   then
      for  n, v  in  ipairs ( v )  do  flatten_and_quote ( v, rv )  end  end
    return  rv  end

  local  o  =  normalize ( o, (level or 1 ) + 1 )

  if  type(o[1]) == 'string'  then
    local  first     =  { ( expand_template ( o[1], o .info_scrape ) ) }
    local  rest      =  table .move ( o, 2, #o, 1, {} )
    local  expanded  =  expand_table ( rest, o .info_scrape )
    local  quoted    =  flatten_and_quote ( expanded, first )
    return  table .concat ( quoted, '  ' )  end

  local  expanded  =  expand_table ( o, o .info_scrape )
  local  quoted    =  flatten_and_quote ( expanded, rv )
  return  table .concat ( quoted, '  ' )  end


function  export  ( s )    -------------------------------------------  export
  --  print ()
  --  print ( 'export', s )
  local  name, value  =  s : match '^([%w_]+)=(.*)$'
  assert ( name )
  --  print ( 'export', name, value )
  value  =  collapse ( expand ( value, 2 ) )
  --  print ( 'export', name, value )
  local  stdlib  =  require 'posix.stdlib'
  stdlib .setenv ( name, value )  end


function  extend  ( t, ... )    --------------------------------------  extend
  --  usage:  extend ( {'a'}, {'b'}, {'c'} )
  for  n, arg  in  ipairs { ... }  do
    if  type(arg) == 'table'  then
      table .move ( arg, 1, #arg, #t+1, t )
    else  error ( 'extend  bad type  ' .. type(arg) )  end  end
  return  t  end


function  getcwd  ()    ----------------------------------------------  getcwd
  local  unistd  =  require 'posix.unistd'
  return  unistd .getcwd()  end


function  glob  ( s )    -----------------------------------------------  glob
  local  glob  =  require  'posix.glob'
  local  t, k, v  =  glob .glob  ( expand ( s, 2 ), 0 ), nil, nil
  assert ( type(t) == 'table' )
  function  glob_next  ()
    k, v  =  next ( t, k )
    return  v  end
  return  glob_next  end


function  has  ( t, v )    ----------------------------------------------  has
  --  usage:  if has ( 'a b c',       'a' )  then  end
  --  usage:  if has ( {'a','b','c'}, 'a' )  then  end
  if  type(t) == 'string'  then
    for  e  in  t : gmatch '%S+'  do  if  e == v  then  return  true  end  end
    return  false  end
  if  type(t) == 'table'  then
    for  k, e  in  pairs ( t )  do  if  e == v  then  return  true  end  end
    return  false  end
  error ( 'lush.has()  bad type  ' .. type(t) )  end


function  in_list  ( k, v )    --------------------------------------  in_list
  error ( 'in_list() is deprecated' )
  if  type(v) == 'string'  then
    for  s  in  v : gmatch '%S+'  do
      if  s == k  then  return  true  end  end
  elseif  type(v) == 'table'  then
    for  n, e  in  pairs ( v )  do
      if  e == k  then  return  true  end  end
  else  error ( 'bad type  ' .. type(v) )  end
  return  false  end


function  info_scrape  ( level )    -----------------------------  info_scrape

  function  assert_no_tail_calls  ( level )
    --  20200320
    --  for  n = 1, level+1  do
    for  n = 1, level  do
      local  info  =  debug .getinfo ( n, 't' )
      assert ( info .istailcall == false, 'detected problematic tail call' )
      end  end

  function  env_scrape_trace  ()
    for  n  in  count ( 1 )  do
      local  info  =  debug .getinfo ( n, 'flnt' )
      if  info == nil  then  break  end
      print  ( info .currentline, info .istailcall, info .name )
      end  end

  function  env_scrape  ( level )
    --  note  20200206
    --    at present, env_scrape does not look for locals named _ENV.
    --    this is a bug.
    --  env_scrape_trace()
    for  level  in  count ( level + 1 )  do
      local  info  =  debug .getinfo ( level, 'flS' )
      --  print ( info, info .func, info .short_src, info .currentline  )
      for  upval  in  count ( 1 )  do
        local  k, v  =  debug .getupvalue ( info .func, upval )
        if  k == nil  then  break  end
        --  print ( upval, k )
        if  k == '_ENV'  then  return  v  end  end
      error 'env_scrape  not found  _ENV'  end  end

      --  20200208
      --  print ( 'env_scrape  _ENV  ' .. tostring ( v ) )
      --  if  k == '_ENV'  then  return  v  end  end  end

  function  locals_scrape  ( level )
    assert ( type(level) == 'number' )
    --  print ( 'locals_scrape  ' .. debug .getinfo ( level + 1, 'n' ) .name )
    local  rv  =  {}
    for  n = 1,999  do
      local  k, v  =  debug .getlocal (  level + 1, n )
      if  k == nil  then  break  end
      --  print ( ('locals_scrape    kv  %s  %s') : format ( k, v ) )
      rv [ k ]  =  v == nil  and  nil_flag  or  v  end
    return  rv  end

  assert_no_tail_calls ( level + 1 )
  local  rv  =  {  env     =  env_scrape    ( level + 1 ),
                   locals  =  locals_scrape ( level + 1 )  }
  expand_check ( rv )
  return  rv  end


function  import  ()    ----------------------------------------------  import
  local  s  =  [[  basename  cap  cat  cd  cond  each  echo  expand  export
    extend  glob  has  is  popen  printf  read  sh  split  trace  ]]
  for  k  in  s : gmatch '%S+'  do  _G[k]  =  _ENV[k]  end
  return  _G .package .loaded .lush  end


function  is  ( s )    ---------------------------------------------------  is
  assert ( s : match '^-%w'  or  s : match '^!%s' )
  return  cond ( normalize ( '[ ' .. s .. ' ]', 2 ) )  end


function  normalize  ( o, level, k, v, k2, v2 )    ----------------  normalize

  assert ( type(level) == 'number', type(level) )

  if  type(o) == 'string'  then  o  =  { o }  end
  assert ( type(o) == 'table' )
  if  type(o[1]) == 'string'  and  o[1] : match '^-'  then
    o .ignore  =  true  end

  if  o .info_scrape == nil  then
    o .info_scrape  =  info_scrape ( level + 1 )  end

  if  k  and  o[k] == nil  then
    o[k]  =  v
    if  k2  and  o[k2] == nil  then  o[k2]  =  v2  end  end

  return  o  end


function  popen  ( o, ... )    ----------------------------------------  popen
  return  sh ( normalize ( o, 2, 'popen', true, 'readlines', true ), ... )  end


function  printf  ( format, ... )    ---------------------------------  printf
  io .write ( format : format ( ... ) )  end


function  quote  ( s )    ---------------------------------------------  quote
  assert ( type(s) == 'string', 'quote  bad type  ' .. type(s) )
  if  s == ''  then  return  "''"  end
  return  s : find '[^-%w_./:]'  and
    ( "'" .. s : gsub ( "'", "'\''" ) .. "'" )  or  s  end


function  read  ( path )    --------------------------------------------  read
  local  f  =  io .open ( path )
  local function  iter  ()
    local  rv  =  f : read()
    if  rv == nil then  f : close()  end
    return  rv  end
  return  iter, f, nil  end


function  sh  ( o, ... )    ----------------------------------------------  sh

  o  =  normalize ( o, 2 )

  o .command  =  expand_command ( o, 2, ... )

  if  o .trace  then  print ( o .command )  end

  local  stdout, success, exit, n

  if  o .capture  then
    local  proc       =  assert ( io .popen ( o .command, 'r' ) )
    stdout            =  assert ( proc : read 'a' )
    success, exit, n  =  proc : close()
    if  o .rstrip == true  then  stdout  =  stdout : match '^(.-)\n?$'  end

  elseif  o .popen  then
    local  proc       =  assert ( io .popen ( o .command, 'r' ) )
    local  next_line  =  proc : lines ()
    function  wrap  ()
      local  rv  =  next_line()
      if  rv == nil  then  assert ( proc : close() )  end
      return  rv  end
    return  wrap

  elseif  o .stdin  then
    local  proc  =  assert ( io .popen ( o .command, 'w' ) )
    assert ( proc : write ( o .stdin ) )
    success, exit, n  =  proc : close()

  else
    success, exit, n  =  os .execute ( o .command )  end

  repeat  --  only once
    if  success == true  and  exit == 'exit'  and  n == 0  then  break  end
    if  o .ignore  then  break  end
    print()
    printf ( 'sh  error\n' )
    printf ( '  command  %s\n', o .command )
    printf ( '  exit     %s  %s\n', exit, n )
    print()
    error ( ('sh error %s %s') : format ( exit, n ) )
    until  true

  if  o .capture  then  return  stdout,  success, exit, n
  else                  return  success, exit, n  end  end


function  split  ( v )    ---------------------------------------------  split
  if  type ( v ) == 'string'  then
    local  rv  =  {}
    for  s  in  v : gmatch '%S+'  do  table .insert ( rv, s )  end
    return  rv  end
  return  v  end


function  trace  ( o, ... )    ----------------------------------------  trace
  return  sh ( normalize ( o, 2, 'trace', true ), ... )  end


do    --------------------------------------------------  module encapsulation
  --  scrape _ENV into shell_module
  local  shell_module  =  {}
  for  k, v  in  pairs ( _ENV )  do  shell_module [ k ]  =  v  end
  return  shell_module  end




--[[--------------------------------------------------------------------------

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
