CREATE OR REPLACE PACKAGE BODY "API_CALL_STACK_PKG" -- -*-coding: utf-8-*-
is

function get_call_stack
( p_nr_items_to_skip in pls_integer
)
return t_call_stack_tab
is
  l_call_stack_rec t_call_stack_rec;
  l_call_stack_tab t_call_stack_tab;
  l_lwb constant binary_integer := 1 + p_nr_items_to_skip;
  l_upb constant binary_integer := utl_call_stack.dynamic_depth;
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

function id
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
end id;

function id
( p_call_stack_tab in t_call_stack_tab
)
return t_id_tab
deterministic
is
  l_id_tab t_id_tab;
begin
  l_id_tab := utl_call_stack.unit_qualified_name();
  if p_call_stack_tab.count > 0
  then
    l_id_tab.extend(p_call_stack_tab.count);
    for i_idx in 1 .. p_call_stack_tab.count
    loop
      l_id_tab(i_idx) := id(p_call_stack_tab(i_idx));
    end loop;
  end if;
  return l_id_tab;
end id;

function get_error_stack
( p_nr_items_to_skip in pls_integer
)
return t_error_stack_tab
is
  l_error_stack_rec t_error_stack_rec;
  l_error_stack_tab t_error_stack_tab;
  l_lwb constant binary_integer := 1 + p_nr_items_to_skip;
  l_upb constant binary_integer := utl_call_stack.error_depth;
begin
  for depth in reverse l_lwb .. l_upb
  loop
    l_error_stack_rec.error_depth := l_upb  - depth + 1;
    l_error_stack_rec.error_msg := utl_call_stack.error_msg(depth);
    l_error_stack_rec.error_number := utl_call_stack.error_number(depth);
    l_error_stack_tab(l_error_stack_tab.count + 1) := l_error_stack_rec;
  end loop;
  return l_error_stack_tab;
end get_error_stack;

function id
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
end id;

function id
( p_error_stack_tab in t_error_stack_tab
)
return t_id_tab
deterministic
is
  l_id_tab t_id_tab;
begin
  l_id_tab := utl_call_stack.unit_qualified_name();
  if p_error_stack_tab.count > 0
  then
    l_id_tab.extend(p_error_stack_tab.count);
    for i_idx in 1 .. p_error_stack_tab.count
    loop
      l_id_tab(i_idx) := id(p_error_stack_tab(i_idx));
    end loop;
  end if;
  return l_id_tab;
end id;

function get_backtrace_stack 
( p_nr_items_to_skip in pls_integer
)
return t_backtrace_stack_tab
is
  l_backtrace_stack_rec t_backtrace_stack_rec;
  l_backtrace_stack_tab t_backtrace_stack_tab;
  l_lwb constant binary_integer := 1 + p_nr_items_to_skip;
  l_upb constant binary_integer := utl_call_stack.backtrace_depth;
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

function id
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
end id;

function id
( p_backtrace_stack_tab in t_backtrace_stack_tab
)
return t_id_tab
deterministic
is
  l_id_tab t_id_tab;
begin
  l_id_tab := utl_call_stack.unit_qualified_name();
  if p_backtrace_stack_tab.count > 0
  then
    l_id_tab.extend(p_backtrace_stack_tab.count);
    for i_idx in 1 .. p_backtrace_stack_tab.count
    loop
      l_id_tab(i_idx) := id(p_backtrace_stack_tab(i_idx));
    end loop;
  end if;
  return l_id_tab;
end id;

procedure show_stack
( p_where_am_i in varchar2
)
is
  l_call_stack_tab constant t_call_stack_tab := get_call_stack;
  l_error_stack_tab constant t_error_stack_tab := get_error_stack;
  l_backtrace_stack_tab constant t_backtrace_stack_tab := get_backtrace_stack;
begin
  dbms_output.new_line;
  dbms_output.put_line('Current stack for  ' || p_where_am_i);
  dbms_output.put_line('  dynamic depth:   ' || utl_call_stack.dynamic_depth);
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
  for depth in /*reverse*/ 1 .. l_call_stack_tab.count
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
  end if;
  
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

  if utl_call_stack.backtrace_depth > 0
  then
    dbms_output.new_line;
  end if;

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
end show_stack;

end API_CALL_STACK_PKG;
/

