

--  Copyright (c) 2019 Parke Bostrom, parke.nexus at gmail.com
--  See copyright notice in lush.lua.
--  Version 0.0.20191228


require  'lush' .import()


function  cm  ( v, ... )
  if  type(v) == 'string'  then  v  =  { v }  end
  assert ( type(v) == 'table' )
  return  lush .expand_command ( v, 2, ... )  end


function  fn  ( ... )
  local  t, rv  =  { ... },  {}
  for  n = 1,#t  do  rv[n]  =  lush .quote ( tostring ( t[n] ) )  end
  return  table .concat ( rv, '  ' )  end


function  cmp  ( actual, expect )
  if  type(actual) == 'string'  and
      type(expect) == 'string'  and
      actual == expect  then  return  end
  print ()
  print ( 'expect  > ' .. expect .. ' <' )
  print ( 'actual  > ' .. actual .. ' <' )
  os .exit ( 1 )  end


print  '----  begin unit tests  ----'

a  =  'b'
c  =  'd$a$a'
e  =  { '$a', '$c', '$a$c', '$a $c' }
f  =  ''

cmp(  cm '$a',          'b'                              )
cmp(  cm '$c',          'dbb'                            )
cmp(  cm '$a  $c',      'b  dbb'                         )
cmp(  cm '$a  $c  $e',  "b  dbb  b  dbb  bdbb  'b dbb'"  )
cmp(  cm '$a  $f  $c',  "b  ''  dbb"                     )

cmp(  cm ( { 'echo a b', 'c', 'd  e' }, 'f', 'g', 'h  i' ),
      "echo a b  c  'd  e'  f  g  'h  i'"  )

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


cmp(  fn(  cap ( { 'echo  a  b', 'c', 'd  e' }, 'f', 'g', 'h  i' )  ),
      "'a b c d  e f g h  i'  true  exit  0" )


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



print  '----  end unit tests  ----'
print  ''
print  'unit.lua  success'
