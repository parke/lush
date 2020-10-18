

--  Copyright (c) 2020 Parke Bostrom, parke.nexus at gmail.com
--  See copyright notice in lush.lua.
--  Version 0.0.20200816


package .path  =  './?.lua;' .. package .path
lush  =  require  'lush' .import()


function  fn  ( ... )
  local  t, rv  =  { ... },  {}
  for  n = 1,#t  do  rv[n]  =  lush .quote ( tostring ( t[n] ) )  end
  return  table .concat ( rv, '  ' )  end


function  cmp  ( actual, expect )

  local function  tables_equal  ( a, b )
    for  k,v in pairs ( a )  do  if  b[k] ~= v  then  return  false  end  end
    for  k,v in pairs ( b )  do  if  a[k] ~= v  then  return  false  end  end
    return  true  end

  if  type(actual) == type(expect)  then
    if  type(actual) == 'table'  and  tables_equal ( actual, expect )  then
      return  end
    if  actual == expect  then  return  end  end

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
j  =  5

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
cmp(  ex  '$j',      '5'         )
cmp(  ec  '$a$g$a',  'bb'        )

cmp(  ec  '$h',       'b  b  bb'                 )
cmp(  ec  ( ex(h) ),  'b  b  bb'                 )
cmp(  ec  { h },      'b  b  bb'                 )
cmp(  ec  ( h ),      'b  b  bb'                 )

cmp(  ec  { '$a',    '$g', '$a', '$a$g$a' },  'b  b  bb'  )
cmp(  ec  ( '$a', 1, '$g', '$a', '$a$g$a' ),  'b  b  bb'  )


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

cmp(  fn(  cap 'echo foo\necho bar' ), "'foo\nbar'  true  exit  0" )

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
cmp(  expand  '$ace',         '$$bar'  )
cmp(  cap     'echo  $ace',   '$bar'  )
cmp(  cap     'echo  $$ace',  '$bar'  )

assert ( not is '-e /tmp/unit_lua_test' )
cat { '/tmp/unit_lua_foo', write='bar' }
cmp(       cat '/tmp/unit_lua_foo'   , 'bar' )
cmp(  fn ( cat '/tmp/unit_lua_foo' ) , 'bar' )
cat { '/tmp/unit_lua_foo', append=' baz' }
cmp(       cat '/tmp/unit_lua_foo'   , 'bar baz' )
cmp(  fn ( cat '/tmp/unit_lua_foo' ) , "'bar baz'" )
sh 'rm /tmp/unit_lua_foo'
cmp(  cat { '/tmp/unit_lua_foo', ignore=true }, nil )

function  a  ()  return  expand  ''  end
function  b  ()  return  expand  '', nil  end
function  c  ()  return  b()  end
cmp(  (pcall(a)),  false  )
cmp(  (pcall(b)),  true   )
cmp(  (pcall(c)),  true   )

cmp(  has  (  'a b c',        'b'  ),  true   )
cmp(  has  (  'a b c',        'f'  ),  false  )
cmp(  has  (  {'a','b','c'},  'b'  ),  true   )
cmp(  has  (  {'a','b','c'},  'f'  ),  false  )

cmp(  table .concat ( extend  ( {'a'}, {'b'}, {'c','d','e'} ) ), 'abcde' )

a  =  'b'
c  =  { d = 'e' }
cmp(  expand '$a',      'b'    )
cmp(  expand '$a.f',    'b.f'  )
cmp(  expand '${a}',    'b'    )
cmp(  expand '${a}_f',  'b_f'  )
cmp(  expand '${c.d}',  'e'    )
cmp(  expand '$a.d',    'b.d'  )

c  =  { d = 'e e e' }
cmp(  ec 'rm  ${c.d}',  "rm  'e e e'"  )


--  test each()
a  =  { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h' }
b  =  {}
for  s  in  each ( a, 2, 5 )  do  table .insert ( b, s )  end
c  =  table .concat ( b )
cmp(  c,  'bcde' )


cmp( cap { 'echo a; echo b; echo c', to_list={} }, {'a','b','c'} )
cmp( cap { 'echo a; echo b; echo c', to_list={} }, {'a','b','c'} )

a  =  'c'
b  =  'd'
cmp(  cap ( { 'echo', '$a'     } ),  'c'     )
cmp(  cap (   'echo', '$a'       ),  'c'     )
cmp(  cap (   'echo', '$a $b'    ),  'c d'   )
cmp(  cap (   'echo', '$a  $b'   ),  'c  d'  )


a  =  'a1'
b  =  'b1'
c  =  '$a $b'
d  =  { a, b }
e  =  { '$a', '$b' }

f  =  'f1 f2'
g  =  'g1 g2'
h  =  '$f $g'
i  =  { f, g }
j  =  { '$f', '$g' }

k  =  'k1*'
l  =  'l1* l2*'
m  =  '$k $l'
n  =  { k, l }
o  =  { '$k', '$l' }

cmp(  ec 'ls $a /tmp/*',  'ls a1 /tmp/*'       )
cmp(  ec 'ls $c /tmp/*',  "ls 'a1 b1' /tmp/*"  )
cmp(  ec 'ls $d /tmp/*',  'ls a1  b1 /tmp/*'   )
cmp(  ec 'ls $e /tmp/*',  'ls a1  b1 /tmp/*'   )

cmp(  ec 'ls $f /tmp/*',  "ls 'f1 f2' /tmp/*"           )
cmp(  ec 'ls $h /tmp/*',  "ls 'f1 f2 g1 g2' /tmp/*"     )
cmp(  ec 'ls $i /tmp/*',  "ls 'f1 f2'  'g1 g2' /tmp/*"  )
cmp(  ec 'ls $j /tmp/*',  "ls 'f1 f2'  'g1 g2' /tmp/*"  )

cmp(  ec 'ls $k /tmp/*',  "ls 'k1*' /tmp/*"             )
cmp(  ec 'ls $m /tmp/*',  "ls 'k1* l1* l2*' /tmp/*"     )
cmp(  ec 'ls $n /tmp/*',  "ls 'k1*'  'l1* l2*' /tmp/*"  )
cmp(  ec 'ls $o /tmp/*',  "ls 'k1*'  'l1* l2*' /tmp/*"  )


--  test glob()
glob '*'    --  this test of glob should succeed


--  test loop()
function  iterate_to_ten  ()
  local  n  =  0
  local function  rv  ()
    n  =  n + 1
    if  n > 10  then  return  end
    return  n  end
  return  rv  end

function  tally  ( n, rv )  rv.n  =  rv.n + n  end

a  =  { n = 0 }
loop ( tally, iterate_to_ten(), a )
cmp(  a.n,  55  )




print  '----  end unit tests  ----'
print  ''
print  'unit.lua  success'
