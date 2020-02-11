

--  Copyright (c) 2019 Parke Bostrom, parke.nexus at gmail.com
--  See copyright notice in lush.lua.
--  Version 0.0.20200210


lush  =  require  'lush' .import()


function  fn  ( ... )
  local  t, rv  =  { ... },  {}
  for  n = 1,#t  do  rv[n]  =  lush .quote ( tostring ( t[n] ) )  end
  return  table .concat ( rv, '  ' )  end


function  cmp  ( actual, expect )
  if  type(actual) == type(expect)  and
      actual == expect  then  return  end
  local  info  =  debug .getinfo ( 2, 'l' )
  print ()
  print ( 'line      ' .. info .currentline )
  --  print ( ('expect  %s  > %s <') : format ( type(expect), expect ) )
  --  print ( ('actual  %s  > %s <') : format ( type(actual), actual ) )
  print ( ('expect  > %s <') : format ( expect ) )
  print ( ('actual  > %s <') : format ( actual ) )
  os .exit ( 1 )  end


print  '----  begin unit tests  ----'

a  =  'b'
c  =  'd$a$a'
e  =  { '$a', '$c', '$a$c', '$a $c' }
f  =  ''
g  =  false
h  =  { '$a', '$g', '$a', '$a$g$a' }
i  =  'a  b  c'

local  ex  =  lush .expand
local  ec  =  lush .expand_command

cmp(  ec '$a',          'b'                              )
cmp(  ec '$c',          'dbb'                            )
cmp(  ec '$a  $c',      'b  dbb'                         )
cmp(  ec '$a  $c  $e',  "b  dbb  b  dbb  bdbb  'b dbb'"  )
cmp(  ec '$a  $f  $c',  "b  ''  dbb"                     )
cmp(  ec ( i ),         'a  b  c'                        )
cmp(  ec '$i',          "'a  b  c'"                      )
cmp(  ec { i },         'a  b  c'                        )
cmp(  ec { i, i },      "a  b  c  'a  b  c'"             )
cmp(  ec {{ i, i }},    "'a  b  c'  'a  b  c'"           )

--[[  20200207  expand_command now rejects varargs
cmp(  cm ( { 'echo a b', 'c', 'd  e' }, 'f', 'g', 'h  i' ),
      "echo a b  c  'd  e'  f  g  'h  i'"  )
--]]

cmp(  ex  '$$a',     '$$a'       )
cmp(  ex  '$g',      false       )
cmp(  ex  '$a$g$a',  'bb'        )
cmp(  ec  '$h',      'b  b  bb'  )
cmp(  ec  ( h ),     'b  b  bb'  )
cmp(  ec  '$a$g$a',  'bb'        )

cmp(  fn(  sh     '-true'     ),  'true  exit  0'       )
cmp(  fn(  sh     '-false'    ),  'nil  exit  1'        )
cmp(  fn(  sh     '-/nofile'  ),  'nil  exit  127'      )
cmp(  fn(  cap    '-true'     ),  "''  true  exit  0"   )
cmp(  fn(  cap    '-false'    ),  "''  nil  exit  1"    )
cmp(  fn(  cap    '-/nofile'  ),  "''  nil  exit  127"  )
cmp(  fn(  cond   '-true'     ),  'true  exit  0'       )
cmp(  fn(  cond   '-false'    ),  'nil  exit  1'        )
cmp(  fn(  cond   '-/nofile'  ),  'nil  exit  127'      )
cmp(  fn(  trace  '-true'     ),  'true  exit  0'       )
cmp(  fn(  trace  '-false'    ),  'nil  exit  1'        )
cmp(  fn(  trace  '-/nofile'  ),  'nil  exit  127'      )

--[[  20200207  expand_command now rejects varags
cmp(  fn(  cap ( { 'echo  a  b', 'c', 'd  e' }, 'f', 'g', 'h  i' )  ),
      "'a b c d  e f g h  i'  true  exit  0" )
--]]

cmp(  fn(  cond  '[ -d /tmp ]'    ),  'true  exit  0'  )
cmp(  fn(  cond  '[ -f /tmp ]'    ),  'nil  exit  1'   )
cmp(  fn(  cond  '[ ! -d /tmp ]'  ),  'nil  exit  1'   )
cmp(  fn(  cond  '[ ! -f /tmp ]'  ),  'true  exit  0'  )

cmp(  fn(  is '-d /tmp'  ),    'true  exit  0'  )
cmp(  fn(  is '-f /tmp'  ),    'nil  exit  1'  )
cmp(  fn(  is '! -d /tmp'  ),  'nil  exit  1'  )
cmp(  fn(  is '! -f /tmp'  ),  'true  exit  0'  )


function  test_function  ()
  local  g  =  'h'
  cmp(  fn(  sh     '-[ $g = h ]'  ),  'true  exit  0'     )
  cmp(  fn(  sh     '-[ $g = j ]'  ),  'nil  exit  1'      )
  cmp(  fn(  cap    'echo $g'      ),  'h  true  exit  0'  )
  cmp(  fn(  cond   '[ $g = h ]'   ),  'true  exit  0'     )
  cmp(  fn(  cond   '[ $g = j ]'   ),  'nil  exit  1'      )
  cmp(  fn(  trace  '-[ $g = h ]'  ),  'true  exit  0'     )
  cmp(  fn(  trace  '-[ $g = j ]'  ),  'nil  exit  1'      )

  echo ( '$a  $c  $e' )
  print ( 'h?', lush .expand_command ( '$g', 1 ) )
  end

test_function()


cd  '$HOME'


ace_one='bar_one'
ace_two='bar_two'
export 'cub_one=$ace_one'
export 'cub_two=$ace_two'
cmp( cap 'echo $cub_one',  'bar_one' )
cmp( cap 'echo $$cub_two', 'bar_two' )


ace  =  '$$bar'
bar  =  'cub'
cmp(  expand  '$ace',         '$$bar'  )
ace  =  nil
export  'ace=$$bar'
cmp(  expand  '$ace',         '$bar'  )
cmp(  cap     'echo  $ace',   '$bar'  )
cmp(  cap     'echo  $$ace',  '$bar'  )


assert ( not is '-e /tmp/foo' )
cat { '/tmp/foo', write='bar' }
cmp(       cat '/tmp/foo'   , 'bar' )
cmp(  fn ( cat '/tmp/foo' ) , 'bar' )
cat { '/tmp/foo', append=' baz' }
cmp(       cat '/tmp/foo'   , 'bar baz' )
cmp(  fn ( cat '/tmp/foo' ) , "'bar baz'" )
sh 'rm /tmp/foo'


print  '----  end unit tests  ----'
print  ''
print  'unit.lua  success'
