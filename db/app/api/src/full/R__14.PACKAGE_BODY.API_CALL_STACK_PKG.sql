CREATE OR REPLACE PACKAGE BODY "API_CALL_STACK_PKG" -- -*-coding: utf-8-*-
is

function get_call_stack
( p_start in pls_integer
, p_size in naturaln
)
return t_call_stack_tab
is
  -- we will return entries between 2 and utl_call_stack.dynamic_depth since we skip this call at entry 1
  l_size constant naturaln :=
    case
      when p_start > 0 -- start to count from the beginning which is actually the end (index utl_call_stack.dynamic_depth is first call)
      then p_size
      when p_start = 0
      then p_size -- like substr(X, 1, ...)
      when p_start < 0 -- start to count from the end
      then least(-p_start, p_size)
    end;
  l_upb constant binary_integer :=
    case
      when p_start > 0 -- start to count from the beginning which is actually the end (index utl_call_stack.dynamic_depth is first call)
      then utl_call_stack.dynamic_depth - p_start + 1
      when p_start = 0
      then utl_call_stack.dynamic_depth - 1 + 1 -- like substr(X, 1, ...)
      when p_start < 0 -- start to count from the end but exclude the first entry (this get_call_stack() call)
      then 2 - (p_start + 1)
    end;
  l_lwb constant binary_integer := greatest(l_upb - l_size + 1, 1);
  l_call_stack_rec t_call_stack_rec;
  l_call_stack_tab t_call_stack_tab;
begin
  for depth in reverse l_lwb .. l_upb
  loop
    l_call_stack_rec.dynamic_depth := l_upb - depth + 1;
    l_call_stack_rec.lexical_depth := utl_call_stack.lexical_depth(depth);
    l_call_stack_rec.owner := utl_call_stack.owner(depth);
    l_call_stack_rec.unit_type := utl_call_stack.unit_type(depth);
    l_call_stack_rec.subprogram := utl_call_stack.subprogram(depth);
    l_call_stack_rec.name := UTL_CALL_STACK.concatenate_subprogram(l_call_stack_rec.subprogram);
    l_call_stack_rec.unit_line := utl_call_stack.unit_line(depth);
    l_call_stack_tab(l_call_stack_tab.count + 1) := l_call_stack_rec;
  end loop;
  return l_call_stack_tab;
end get_call_stack;

function repr
( p_call_stack_rec in t_call_stack_rec
)
return varchar2
deterministic
is
begin
  return utl_lms.format_message
         ( '%d|%d|%s|%s|%s|%d'
         , p_call_stack_rec.dynamic_depth
         , p_call_stack_rec.lexical_depth
         , p_call_stack_rec.owner
         , p_call_stack_rec.unit_type
         , p_call_stack_rec.name
         , p_call_stack_rec.unit_line
         );
end repr;

function repr
( p_call_stack_tab in t_call_stack_tab
)
return t_repr_tab
deterministic
is
  l_repr_tab t_repr_tab;
begin
  l_repr_tab := utl_call_stack.unit_qualified_name();
  if p_call_stack_tab.count > 0
  then
    l_repr_tab.extend(p_call_stack_tab.count);
    for i_idx in 1 .. p_call_stack_tab.count
    loop
      l_repr_tab(i_idx) := repr(p_call_stack_tab(i_idx));
    end loop;
  end if;
  return l_repr_tab;
end repr;

function get_error_stack
( p_start in pls_integer
, p_size in naturaln
)
return t_error_stack_tab
is
  l_error_depth constant naturaln := utl_call_stack.error_depth;
  l_lwb constant binary_integer :=
    case
      when p_start > 0
      then p_start
      when p_start = 0
      then 1 -- like substr(X, 1, ...)
      when p_start < 0
      then l_error_depth + p_start + 1
    end;
  l_upb constant binary_integer := least(l_lwb + p_size - 1, l_error_depth);
  l_error_stack_rec t_error_stack_rec;
  l_error_stack_tab t_error_stack_tab;
begin
  for depth in l_lwb .. l_upb
  loop
    l_error_stack_rec.error_depth := depth;
    l_error_stack_rec.error_msg := utl_call_stack.error_msg(depth);
    l_error_stack_rec.error_number := utl_call_stack.error_number(depth);
    l_error_stack_tab(l_error_stack_tab.count + 1) := l_error_stack_rec;
  end loop;
  return l_error_stack_tab;
end get_error_stack;

function repr
( p_error_stack_rec in t_error_stack_rec
)
return varchar2
deterministic
is
begin
  return utl_lms.format_message
         ( '%d|%d|%s'
         , p_error_stack_rec.error_depth
         , p_error_stack_rec.error_number
         , p_error_stack_rec.error_msg
         );
end repr;

function repr
( p_error_stack_tab in t_error_stack_tab
)
return t_repr_tab
deterministic
is
  l_repr_tab t_repr_tab;
begin
  l_repr_tab := utl_call_stack.unit_qualified_name();
  if p_error_stack_tab.count > 0
  then
    l_repr_tab.extend(p_error_stack_tab.count);
    for i_idx in 1 .. p_error_stack_tab.count
    loop
      l_repr_tab(i_idx) := repr(p_error_stack_tab(i_idx));
    end loop;
  end if;
  return l_repr_tab;
end repr;

function get_backtrace_stack 
( p_start in pls_integer
, p_size in naturaln
)
return t_backtrace_stack_tab
is
  -- this is similar to get_call_stack with only one difference: do not exclude the first entry
  l_size constant naturaln :=
    case
      when p_start > 0 -- start to count from the beginning which is actually the end (index utl_call_stack.dynamic_depth is first call)
      then p_size
      when p_start = 0
      then p_size -- like substr(X, 1, ...)
      when p_start < 0 -- start to count from the end
      then least(-p_start, p_size)
    end;
  l_upb constant binary_integer :=
    case
      when p_start > 0 -- start to count from the beginning which is actually the end (index utl_call_stack.backtrace_depth is first call)
      then utl_call_stack.backtrace_depth - p_start + 1
      when p_start = 0
      then utl_call_stack.backtrace_depth - 1 + 1 -- like substr(X, 1, ...)
      when p_start < 0 -- start to count from the end
      then 1 - (p_start + 1)
    end;
  l_lwb constant binary_integer := greatest(l_upb - l_size + 1, 1);
  l_backtrace_stack_rec t_backtrace_stack_rec;
  l_backtrace_stack_tab t_backtrace_stack_tab;
begin
  for depth in reverse l_lwb .. l_upb
  loop
    l_backtrace_stack_rec.backtrace_depth := l_upb - depth + 1;
    l_backtrace_stack_rec.backtrace_line := utl_call_stack.backtrace_line(depth);
    l_backtrace_stack_rec.backtrace_unit := utl_call_stack.backtrace_unit(depth);
    l_backtrace_stack_tab(l_backtrace_stack_tab.count + 1) := l_backtrace_stack_rec;
  end loop;
  return l_backtrace_stack_tab;
end get_backtrace_stack;  

function repr
( p_backtrace_stack_rec in t_backtrace_stack_rec
)
return varchar2
deterministic
is
begin
  return utl_lms.format_message
         ( '%d|%d|%s'
         , p_backtrace_stack_rec.backtrace_depth
         , p_backtrace_stack_rec.backtrace_line
         , p_backtrace_stack_rec.backtrace_unit
         );
end repr;

function repr
( p_backtrace_stack_tab in t_backtrace_stack_tab
)
return t_repr_tab
deterministic
is
  l_repr_tab t_repr_tab;
begin
  l_repr_tab := utl_call_stack.unit_qualified_name();
  if p_backtrace_stack_tab.count > 0
  then
    l_repr_tab.extend(p_backtrace_stack_tab.count);
    for i_idx in 1 .. p_backtrace_stack_tab.count
    loop
      l_repr_tab(i_idx) := repr(p_backtrace_stack_tab(i_idx));
    end loop;
  end if;
  return l_repr_tab;
end repr;

procedure show_stack
( p_where_am_i in varchar2
)
is
  l_dynamic_depth constant naturaln := utl_call_stack.dynamic_depth - 1;
  l_call_stack_tab constant t_call_stack_tab := get_call_stack(p_size => l_dynamic_depth); -- skip this call and the call to get_call_stack too
  l_error_stack_tab constant t_error_stack_tab := get_error_stack;
  l_backtrace_stack_tab constant t_backtrace_stack_tab := get_backtrace_stack;
begin
  dbms_output.new_line;
  dbms_output.put_line('Current stack for  ' || p_where_am_i);
  dbms_output.put_line('  dynamic depth:   ' || l_dynamic_depth); -- skip this call
  dbms_output.put_line('  error depth:     ' || utl_call_stack.error_depth);
  dbms_output.put_line('  backtrace depth: ' || utl_call_stack.backtrace_depth);
  dbms_output.new_line;

  dbms_output.put_line
  ( lpad   ('DYNAMIC DEPTH', 13) || ' ' ||
    lpad   ('LEXICAL DEPTH', 13) || ' ' ||
    rpad   ('OWNER',     30 ) || ' ' ||
    rpad   ('UNIT TYPE',     30 ) || ' ' ||
    rpad   ('UNIT' , 30 ) || ' ' ||
    lpad   ('LINE', 6) || ' ' ||
            'NAME'                      
  );
  dbms_output.put_line
  ( lpad   ('=============', 13) || ' ' ||
    lpad   ('=============', 13) || ' ' ||
    rpad   ('=====',     30 ) || ' ' ||
    rpad   ('=========',     30 ) || ' ' ||
    rpad   ('====' , 30 ) || ' ' ||
    lpad   ('====', 6) || ' ' ||
            '===='                      
  );
  for depth in 1 .. l_call_stack_tab.count
  loop
    dbms_output.put_line
    ( to_char(l_call_stack_tab(depth).dynamic_depth,    '999999999990') || ' ' ||
      to_char(l_call_stack_tab(depth).lexical_depth,    '999999999990') || ' ' ||
      rpad   (nvl(l_call_stack_tab(depth).owner, ' '),     30 ) || ' ' ||
      rpad   (l_call_stack_tab(depth).unit_type,     30 ) || ' ' ||
      rpad   (l_call_stack_tab(depth).subprogram(1) , 30 ) || ' ' ||
      to_char(l_call_stack_tab(depth).unit_line, '99990') || ' ' ||
              l_call_stack_tab(depth).name                       
    );
  end loop;

  if utl_call_stack.error_depth > 0
  then
    dbms_output.new_line;
    dbms_output.put_line
    ( lpad   ('ERROR DEPTH', 11)    || ' ' ||
      rpad   ('ERROR MESSAGE'   , 100)    || ' ' ||
      rpad   ('ERROR', 9)
    );
    dbms_output.put_line
    ( lpad   ('===========', 11)    || ' ' ||
      rpad   ('============='   , 100)    || ' ' ||
      rpad   ('=====', 9)
    );
    for error in 1 ..  l_error_stack_tab.count
    loop
      dbms_output.put_line
      ( to_char(l_error_stack_tab(error).error_depth, '9999999990') || ' ' ||
        rpad   (l_error_stack_tab(error).error_msg   , 100)    || ' ' ||
        'ORA-' || to_char(l_error_stack_tab(error).error_number, 'FM00000')
      );
    end loop;
  end if;

  if utl_call_stack.backtrace_depth > 0
  then
    dbms_output.new_line;

    dbms_output.put_line
    ( lpad   ('BACKTRACE DEPTH', 15)    || ' ' ||
      rpad   ('BACKTRACE UNIT', 61) || ' ' ||
      lpad   ('LINE', 6)
    );
    dbms_output.put_line
    ( lpad   ('===============', 15)    || ' ' ||
      rpad   ('==============', 61) || ' ' ||
      lpad   ('====', 6)
    );
    for backtrace in 1 ..  l_backtrace_stack_tab.count
    loop
      dbms_output.put_line
      ( to_char(l_backtrace_stack_tab(backtrace).backtrace_depth, '99999999999990') || ' ' ||
        rpad   (l_backtrace_stack_tab(backtrace).backtrace_unit, 61) || ' ' ||
        to_char(l_backtrace_stack_tab(backtrace).backtrace_line, '99990')
      );
    end loop;
  end if;
exception
  when others
  then null;
end show_stack;

$if cfg_pkg.c_testing $then

procedure ut_get_call_stack
is
  l_call_stack_tab t_call_stack_tab;
  l_line_tab sys.odcivarchar2list := sys.odcivarchar2list(null, null, null);
  l_repr_tab sys.odcivarchar2list :=sys.odcivarchar2list(null, null, null);
  
  procedure proc_inside1
  is
    procedure proc_inside2
    is
    begin
      l_call_stack_tab := get_call_stack(-3); l_line_tab(3) := $$PLSQL_LINE;
      ut.expect(l_call_stack_tab.count, 'count3').to_equal(3);
      l_repr_tab(3) :=
        utl_lms.format_message
        ( '3|3|%s|PACKAGE BODY|%s.UT_GET_CALL_STACK.PROC_INSIDE1.PROC_INSIDE2|%s'
        , $$PLSQL_UNIT_OWNER
        , $$PLSQL_UNIT
        , l_line_tab(3)
        );
      for i_idx in 1 .. l_call_stack_tab.count
      loop
        -- the first and second call have changed their line number so skip that (assume length 3)
        ut.expect
        ( case
            when i_idx < l_call_stack_tab.count
            then substr(repr(l_call_stack_tab(i_idx)), 1, length(repr(l_call_stack_tab(i_idx))) - 3)
            else repr(l_call_stack_tab(i_idx))
          end
        , 'id3-'||i_idx
        )
        .to_equal
        ( case
            when i_idx < l_call_stack_tab.count
            then substr(l_repr_tab(i_idx), 1, length(l_repr_tab(i_idx)) - 3)
            else l_repr_tab(i_idx)
          end
        );
      end loop;
    end proc_inside2;
  begin
    l_call_stack_tab := get_call_stack(-2); l_line_tab(2) := $$PLSQL_LINE;
    ut.expect(l_call_stack_tab.count, 'count2').to_equal(2);
    l_repr_tab(2) :=
      utl_lms.format_message
      ( '2|2|%s|PACKAGE BODY|%s.UT_GET_CALL_STACK.PROC_INSIDE1|%s'
      , $$PLSQL_UNIT_OWNER
      , $$PLSQL_UNIT
      , l_line_tab(2)
      );
    for i_idx in 1 .. l_call_stack_tab.count
    loop
      -- the first call has changed its line number so skip that (assume length 3)
      ut.expect
      ( case
          when i_idx < l_call_stack_tab.count
          then substr(repr(l_call_stack_tab(i_idx)), 1, length(repr(l_call_stack_tab(i_idx))) - 3)
          else repr(l_call_stack_tab(i_idx))
        end
      , 'id2-'||i_idx
      )
      .to_equal
      ( case
          when i_idx < l_call_stack_tab.count
          then substr(l_repr_tab(i_idx), 1, length(l_repr_tab(i_idx)) - 3)
          else l_repr_tab(i_idx)
        end
      );
    end loop;
    proc_inside2;
  end proc_inside1;
begin
  l_call_stack_tab := get_call_stack(-1); l_line_tab(1) := $$PLSQL_LINE;
  ut.expect(l_call_stack_tab.count, 'count1').to_equal(1);
  l_repr_tab(1) :=
    utl_lms.format_message
    ( '1|1|%s|PACKAGE BODY|%s.UT_GET_CALL_STACK|%s'
    , $$PLSQL_UNIT_OWNER
    , $$PLSQL_UNIT
    , l_line_tab(1)
    );
  ut.expect(repr(l_call_stack_tab(1)), 'id1').to_equal(l_repr_tab(1));
  proc_inside1;
end ut_get_call_stack;

procedure ut_get_error_stack
is
  l_error_stack_tab t_error_stack_tab;
  l_line_tab sys.odcivarchar2list := sys.odcivarchar2list(null, null, null);
  l_repr_tab sys.odcivarchar2list :=sys.odcivarchar2list(null, null, null);

  procedure proc_inside1
  is
    procedure proc_inside2
    is
      l_divide_by_zero pls_integer;
    begin
      l_line_tab(3) := $$PLSQL_LINE; l_divide_by_zero := 1/0;
    exception
      when others
      then
        l_error_stack_tab := get_error_stack(-1);
        ut.expect(l_error_stack_tab.count, 'count3').to_equal(1);
        l_repr_tab(1) := '1|1476|divisor is equal to zero';
        ut.expect(repr(l_error_stack_tab(1)), 'id3').to_equal(l_repr_tab(1));
        l_line_tab(2) := $$PLSQL_LINE; raise;
    end proc_inside2;
  begin
    proc_inside2;
  exception
    when others
    then
      l_error_stack_tab := get_error_stack(-3);
      ut.expect(l_error_stack_tab.count, 'count2').to_equal(3);
      l_repr_tab(2) := '2|6512|at "ORACLE_TOOLS.API_CALL_STACK_PKG", line ' || l_line_tab(2);
      l_repr_tab(3) := '3|6512|at "ORACLE_TOOLS.API_CALL_STACK_PKG", line ' || l_line_tab(3);
      for i_idx in 1 .. l_error_stack_tab.count
      loop
        ut.expect(repr(l_error_stack_tab(i_idx)), 'id2-'||i_idx).to_equal(l_repr_tab(i_idx));
      end loop;
      raise;
  end proc_inside1;
begin
  l_error_stack_tab := get_error_stack;
  ut.expect(l_error_stack_tab.count, 'count1').to_equal(0);
  proc_inside1;
exception
  when others
  then
    null;  
end ut_get_error_stack;  

procedure ut_get_backtrace_stack
is
  l_backtrace_stack_tab t_backtrace_stack_tab;
  l_line_tab sys.odcivarchar2list := sys.odcivarchar2list(null, null, null);
  l_repr_tab sys.odcivarchar2list :=sys.odcivarchar2list(null, null, null);

  procedure proc_inside1
  is
    procedure proc_inside2
    is
      l_divide_by_zero pls_integer;
    begin
      l_line_tab(1) := $$PLSQL_LINE; l_divide_by_zero := 1/0;
    exception
      when others
      then
        l_backtrace_stack_tab := get_backtrace_stack(-1);
        ut.expect(l_backtrace_stack_tab.count, 'count3').to_equal(1);
        l_repr_tab(1) := utl_lms.format_message('1|%s|%s.%s', l_line_tab(1), $$PLSQL_UNIT_OWNER, $$PLSQL_UNIT);
        ut.expect(repr(l_backtrace_stack_tab(1)), 'id3').to_equal(l_repr_tab(1));
        l_line_tab(2) := $$PLSQL_LINE; raise;
    end proc_inside2;
  begin
    l_line_tab(3) := $$PLSQL_LINE; proc_inside2;
  exception
    when others
    then
      l_backtrace_stack_tab := get_backtrace_stack(-3);
      ut.expect(l_backtrace_stack_tab.count, 'count2').to_equal(3);
      l_repr_tab(1) := utl_lms.format_message('1|%s|%s.%s', l_line_tab(3), $$PLSQL_UNIT_OWNER, $$PLSQL_UNIT);
      l_repr_tab(2) := utl_lms.format_message('2|%s|%s.%s', l_line_tab(1), $$PLSQL_UNIT_OWNER, $$PLSQL_UNIT);
      l_repr_tab(3) := utl_lms.format_message('3|%s|%s.%s', l_line_tab(2), $$PLSQL_UNIT_OWNER, $$PLSQL_UNIT);
      for i_idx in 1 .. l_backtrace_stack_tab.count
      loop
        ut.expect(repr(l_backtrace_stack_tab(i_idx)), 'id2-'||i_idx).to_equal(l_repr_tab(i_idx));
      end loop;
      raise;
  end proc_inside1;
begin
  l_backtrace_stack_tab := get_backtrace_stack;
  ut.expect(l_backtrace_stack_tab.count, 'count1').to_equal(0);
  proc_inside1;
exception
  when others
  then
    null;  
end ut_get_backtrace_stack;

$end

end API_CALL_STACK_PKG;
/

