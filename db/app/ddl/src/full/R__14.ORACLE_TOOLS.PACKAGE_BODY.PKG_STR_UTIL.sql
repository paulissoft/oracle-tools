CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."PKG_STR_UTIL" IS

g_clob clob;

g_package_prefix constant varchar2(61) := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.';

$if oracle_tools.cfg_pkg.c_testing $then

"null" constant varchar2(1) := null;
"null clob" constant clob := null;
"lf" constant varchar2(1) := chr(10);
"cr" constant varchar2(1) := chr(13);
"crlf" constant varchar2(2) := "cr" || "lf";

g_clob_test clob;

$end

-- GLOBAL

function dbms_lob_substr
( p_clob in clob
, p_amount in naturaln
, p_offset in positiven
, p_check in varchar2
)
return varchar2
is
  l_offset positiven := p_offset;
  l_amount naturaln := p_amount; -- can become 0
  l_buffer t_max_varchar2 := null;
  l_chunk t_max_varchar2;
  l_chunk_length naturaln := 0; -- never null
  l_clob_length constant naturaln := nvl(dbms_lob.getlength(p_clob), 0);
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.enter(g_package_prefix || 'DBMS_LOB_SUBSTR');
  dbug.print
  ( dbug."input"
  , 'p_clob length: %s; p_amount: %s; p_offset: %s; p_check: %s'
  , l_clob_length
  , p_amount
  , p_offset
  , p_check
  );
$end

  if p_check is null or p_check in ('O', 'L', 'OL')
  then
    null; -- OK
  else
    raise program_error;
  end if;

  -- read till this entry is full (during testing I got 32764 instead of c_max_varchar2_size)
  <<buffer_loop>>
  while l_amount > 0
  loop
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
    dbug.print(dbug."info", 'l_offset: %s; l_amount: %s', l_offset, l_amount);
$end

    l_chunk :=
      dbms_lob.substr
      ( lob_loc => p_clob
      , offset => l_offset
      , amount => l_amount
      );

    l_chunk_length := nvl(length(l_chunk), 0);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
    dbug.print(dbug."info", 'l_chunk_length: %s', l_chunk_length);
$end

    begin
      l_buffer := l_buffer || l_chunk;
    exception
      when value_error
      then
        if p_check in ('O', 'OL')
        then raise; -- overflow
        else exit buffer_loop;
        end if;
    end;

    -- nothing read: stop;
    -- buffer length at least p_amount: stop
    exit buffer_loop when l_chunk_length = 0 or length(l_buffer) >= p_amount;

    l_offset := l_offset + l_chunk_length;
    l_amount := l_amount - l_chunk_length;
  end loop buffer_loop;

  if p_check in ('L', 'OL')
  then
    if nvl(length(l_buffer), 0) = p_amount
    then null; -- buffer length is amount requested, i.e. OK
    else raise value_error;
    end if;
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.print(dbug."output", 'return length: %s', length(l_buffer));
  dbug.leave;
$end

  return l_buffer;
end dbms_lob_substr;

function dbms_lob$substr
( p_clob in clob
, p_amount in naturaln
, p_offset in positiven
)
return varchar2
is
begin
  pragma inline (dbms_lob_substr, 'YES');
  return dbms_lob_substr(p_clob => p_clob, p_amount => p_amount, p_offset => p_offset, p_check => null);
end dbms_lob$substr;

procedure split
( p_str in varchar2
, p_delimiter in varchar2
, p_str_tab out nocopy dbms_sql.varchar2a
)
is
  l_pos pls_integer;
  l_start pls_integer;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.enter(g_package_prefix || 'SPLIT (1)');
  dbug.print(dbug."input", 'p_str: %s; p_delimiter: "%s"', p_str, p_delimiter);
$end

  if p_delimiter is null
  then
    raise program_error;
  end if;

  l_start := 1;

  <<split_loop>>
  loop
    l_pos := instr(p_str, p_delimiter, l_start);
    if l_pos > 0
    then
      p_str_tab(p_str_tab.count+1) := substr(p_str, l_start, l_pos-l_start);
      l_start := l_pos + length(p_delimiter);
    else
      p_str_tab(p_str_tab.count+1) := substr(p_str, l_start);
      exit split_loop;
    end if;
  end loop split_loop;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.print(dbug."output", 'p_str_tab.count: %s', p_str_tab.count);
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end split;

procedure split
( p_str in clob
, p_delimiter in varchar2
  -- type varchar2a is table of varchar2(32767) index by binary_integer;
, p_str_tab out nocopy dbms_sql.varchar2a
)
is
  l_pos pls_integer;
  l_start positiven := 1; -- never null
  l_amount simple_integer := 0; -- never null
  l_str_length constant naturaln := nvl(dbms_lob.getlength(p_str), 0);
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.enter(g_package_prefix || 'SPLIT (2)');
  dbug.print(dbug."input", 'p_str length: %s; p_delimiter: "%s"', l_str_length, p_delimiter);
$end

  if l_str_length = 0
  then
    p_str_tab(p_str_tab.count+1) := null;
  else
    while l_start <= l_str_length
    loop
      l_pos := case when p_delimiter is not null then dbms_lob.instr(lob_loc => p_str, pattern => p_delimiter, offset => l_start) else 0 end;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
      dbug.print(dbug."info", 'l_start: %s; l_pos: %s', l_start, l_pos);
$end

      l_amount := case when l_pos > 0 then l_pos - l_start else c_max_varchar2_size end;
      p_str_tab(p_str_tab.count+1) :=
        dbms_lob_substr
        ( p_clob => p_str
        , p_offset => l_start
        , p_amount => l_amount
        , p_check => case when l_pos > 0 then 'OL' end
        );
      l_start := l_start + nvl(length(p_str_tab(p_str_tab.count+0)), 0) + nvl(length(p_delimiter), 0);
    end loop;
    -- everything has been read BUT ...
    if l_pos > 0
    then
      -- the delimiter string is just at the end of p_str, hence add another empty line so a join() can reconstruct exactly the same clob
      p_str_tab(p_str_tab.count+1) := null;
    end if;
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.print(dbug."output", 'p_str_tab.count: %s', p_str_tab.count);
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end split;

procedure split
( p_str in clob
, p_delimiter in varchar2 := ','
, p_str_tab out nocopy t_clob_tab
)
is
  l_pos naturaln := 0;
  l_start positiven := 1;
  l_str_length constant naturaln := nvl(dbms_lob.getlength(p_str), 0);
  l_amount naturaln := 0;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.enter(g_package_prefix || 'SPLIT (3)');
  dbug.print(dbug."input", 'p_str length: %s; p_delimiter: "%s"', l_str_length, p_delimiter);
$end

  p_str_tab := t_clob_tab();

  if l_str_length = 0 or p_delimiter is null
  then
    -- copy p_str to first element
    p_str_tab.extend(1);
    if l_str_length > 0
    then
      dbms_lob.createtemporary(p_str_tab(p_str_tab.last), true);
      dbms_lob.copy
      ( dest_lob => p_str_tab(p_str_tab.last)
      , src_lob => p_str
      , amount => l_str_length
      , dest_offset => 1
      , src_offset => l_start
      );
    end if;
  else
    <<split_loop>>
    while l_start <= l_str_length
    loop
      l_pos := dbms_lob.instr(lob_loc => p_str, pattern => p_delimiter, offset => l_start);
      p_str_tab.extend(1);

      l_amount := case when l_pos > 0 then l_pos - l_start else l_str_length + 1 - l_start end;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
      dbug.print(dbug."debug", 'l_start: %s; l_pos: %s; l_amount: %s', l_start, l_pos, l_amount);
$end

      if l_amount > 0
      then
        dbms_lob.createtemporary(p_str_tab(p_str_tab.last), true);
        dbms_lob.copy
        ( dest_lob => p_str_tab(p_str_tab.last)
        , src_lob => p_str
        , amount => l_amount
        , dest_offset => 1
        , src_offset => l_start
        );
      end if;

      if l_pos > 0
      then
        l_start := l_pos + length(p_delimiter);
      else
        exit split_loop;
      end if;
    end loop split_loop;
    -- everything has been read BUT ...
    if l_pos > 0
    then
      -- the delimiter string is just at the end of p_str, so add another empty line so a join() can reconstruct exactly the same clob
      p_str_tab.extend(1);
    end if;
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.print(dbug."output", 'p_str_tab.count: %s', case when p_str_tab is not null then p_str_tab.count end);
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end split;

function join
( p_str_tab in dbms_sql.varchar2a
, p_delimiter in varchar2
)
return varchar2
deterministic
is
  l_str t_max_varchar2 := null;
begin
  if p_str_tab.count > 0
  then
    for i_idx in p_str_tab.first .. p_str_tab.last
    loop
      l_str :=
        case
          when i_idx = p_str_tab.first
          then p_str_tab(i_idx)
          else l_str || p_delimiter || p_str_tab(i_idx)
        end;
    end loop;
  end if;
  return l_str;
end join;

procedure join
( p_str_tab in dbms_sql.varchar2a
, p_delimiter in varchar2 := ','
, p_str out nocopy clob
)
is
begin
  p_str := null;
  if p_str_tab.count > 0
  then
    for i_idx in p_str_tab.first .. p_str_tab.last
    loop
      append_text(case when i_idx > p_str_tab.first then p_delimiter end || p_str_tab(i_idx), p_str);
    end loop;
  end if;
end join;  

procedure trim
( p_str in out nocopy clob
, p_set in varchar2
)
is
  l_str_length constant pls_integer := dbms_lob.getlength(p_str);
  l_start pls_integer := null;
  l_end pls_integer := null;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.enter(g_package_prefix || 'TRIM (1)');
  dbug.print(dbug."input", 'p_str length: %s; p_set: %s', dbms_lob.getlength(p_str), p_set);
$end

  -- a dummy loop so you can quit fast without too many if statements
  loop
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
    dbug.print(dbug."debug", 'l_str_length: %s', l_str_length);
$end

    exit when l_str_length is null or l_str_length <= 0;

    -- l_str_length > 0

    for i_start in 1 .. l_str_length
    loop
      if instr
         ( p_set
         , dbms_lob.substr
           ( lob_loc => p_str
           , offset => i_start
           , amount => 1
           )
         ) > 0
      then
        null;
      else
        l_start := i_start;
        exit;
      end if;
    end loop;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
    dbug.print(dbug."debug", 'l_start: %s', l_start);
$end

    if l_start is null -- alleen maar characters die je niet wilt
    then
      p_str := null;
      exit;
    end if;

    for i_end in reverse 1 .. l_str_length
    loop
      if instr
         ( p_set
         , dbms_lob.substr
           ( lob_loc => p_str
           , offset => i_end
           , amount => 1
           )
         ) > 0
      then
        null;
      else
        l_end := i_end;
        exit;
      end if;
    end loop;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
    dbug.print(dbug."debug", 'l_end: %s', l_end);
$end

    if l_start = 1 and l_end = l_str_length -- niets gevonden, niets te doen
    then
      exit;
    end if;

    -- sanity check
    if l_start > l_end
    then
      raise program_error;
    end if;

    -- Er is iets gevonden en er blijft wat over: kopieer wat overblijft.
    -- Merk op dat je niet rechtstreeks van p_str naar p_str kunt kopieren omdat het ook de bron is.
    dbms_lob.trim(g_clob, 0);
    dbms_lob.copy
    ( dest_lob => g_clob
    , src_lob => p_str
    , amount => l_end - l_start + 1
    , dest_offset => 1
    , src_offset => l_start
    );
    dbms_lob.trim(p_str, 0);
    dbms_lob.append(dest_lob => p_str, src_lob => g_clob);

    exit; -- essentieel
  end loop;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.print(dbug."output", 'p_str length: %s', dbms_lob.getlength(p_str));
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end trim;

procedure trim
( p_str_tab in out nocopy t_clob_tab
, p_set in varchar2
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.enter(g_package_prefix || 'TRIM (2)');
  dbug.print(dbug."input", 'p_str_tab.count: %s; p_set: %s', case when p_str_tab is not null then p_str_tab.count end, p_set);
$end

  if p_str_tab is not null and p_str_tab.count > 0
  then
    for i_idx in p_str_tab.first .. p_str_tab.last
    loop
      trim
      ( p_str => p_str_tab(i_idx)
      , p_set => p_set
      );
    end loop;

    while p_str_tab.last is not null and p_str_tab(p_str_tab.last) is null
    loop
      p_str_tab.trim;
    end loop;
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.print(dbug."output", 'p_str_tab.count: %s', case when p_str_tab is not null then p_str_tab.count end);
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end trim;

function compare
( p_str1_tab in t_clob_tab
, p_str2_tab in t_clob_tab
)
return integer
is
  l_retval pls_integer;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.enter(g_package_prefix || 'COMPARE (1)');
  dbug.print
  ( dbug."input"
  , 'p_str1_tab.count: %s; p_str2_tab.count: %s'
  , case when p_str1_tab is not null then p_str1_tab.count end
  , case when p_str2_tab is not null then p_str2_tab.count end
  );
$end

  if p_str1_tab.count < p_str2_tab.count
  then
    l_retval := -1;
  elsif p_str1_tab.count > p_str2_tab.count
  then
    l_retval := 1;
  elsif p_str1_tab.count = 0
  then
    l_retval := 0;
  else
    -- beide collecties even groot en niet leeg
    for i_idx in p_str1_tab.first .. p_str1_tab.last
    loop
      l_retval :=
  case
    when p_str1_tab(i_idx) is null and p_str2_tab(i_idx) is null
    then 0
    when p_str1_tab(i_idx) is null
    then -1
    when p_str2_tab(i_idx) is null
    then 1
    else dbms_lob.compare(p_str1_tab(i_idx), p_str2_tab(i_idx))
  end;
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
      dbug.print
      ( dbug."debug"
      , 'p_str1_tab(%s) length: %s; p_str1_tab(%s) length: %s; l_retval: %s'
      , i_idx
      , dbms_lob.getlength(p_str1_tab(i_idx))
      , i_idx
      , dbms_lob.getlength(p_str2_tab(i_idx))
      , l_retval
      );
$end
      exit when l_retval != 0;
    end loop;
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.print(dbug."output", 'return: %s', l_retval);
  dbug.leave;
$end

  return l_retval;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end compare;

procedure compare
( p_str1_tab in t_clob_tab
, p_str2_tab in t_clob_tab
, p_first_line_not_equal out binary_integer
, p_first_char_not_equal out binary_integer
)
is
  l_line_idx binary_integer;
  l_str1_length binary_integer;
  l_str2_length binary_integer;
  l_char_idx binary_integer;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.enter(g_package_prefix || 'COMPARE (2)');
  dbug.print
  ( dbug."input"
  , 'p_str1_tab.count: %s; p_str2_tab.count: %s'
  , case when p_str1_tab is not null then p_str1_tab.count end
  , case when p_str2_tab is not null then p_str2_tab.count end
  );
$end

  p_first_line_not_equal := null;
  p_first_char_not_equal := null;
  l_line_idx := 1;
  <<line_loop>>
  loop
    if l_line_idx > p_str1_tab.count and l_line_idx > p_str2_tab.count
    then
      -- no differnce found: stop
      exit line_loop;
    elsif l_line_idx > p_str1_tab.count or l_line_idx > p_str2_tab.count
    then
      -- there is a difference since one collection is larger than the other: stop
      p_first_line_not_equal := l_line_idx;

      exit line_loop;
    else
      l_str1_length := dbms_lob.getlength(p_str1_tab(l_line_idx));
      l_str2_length := dbms_lob.getlength(p_str2_tab(l_line_idx));
      l_char_idx := 1;
      <<char_loop>>
      loop
  if (l_str1_length is null or l_char_idx > l_str1_length) and
     (l_str2_length is null or l_char_idx > l_str2_length)
  then
    exit char_loop;
  elsif (l_str1_length is null or l_char_idx > l_str1_length) or
        (l_str2_length is null or l_char_idx > l_str2_length) or
        dbms_lob.substr(lob_loc => p_str1_tab(l_line_idx), offset => l_char_idx, amount => 1) !=
        dbms_lob.substr(lob_loc => p_str2_tab(l_line_idx), offset => l_char_idx, amount => 1)
  then
    p_first_line_not_equal := l_line_idx;
    p_first_char_not_equal := l_char_idx;

    exit line_loop; -- first difference found: stop
  end if;

  l_char_idx := l_char_idx + 1;
      end loop char_loop;
    end if;

    l_line_idx := l_line_idx + 1;
  end loop line_loop;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.print
  ( dbug."output"
  , 'p_first_line_not_equal: %s; p_first_char_not_equal: %s'
  , p_first_line_not_equal
  , p_first_char_not_equal
  );
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end compare;

procedure compare
( p_source_line_tab in dbms_sql.varchar2a
, p_target_line_tab in dbms_sql.varchar2a
, p_stop_after_first_diff in boolean
, p_show_equal_lines in boolean
, p_convert_to_base64 in boolean
, p_compare_line_tab out nocopy dbms_sql.varchar2a
)
is
  type t_array_1_dim_tab is table of pls_integer index by binary_integer; /* simple_integer may not be null */
  type t_array_2_dim_tab is table of t_array_1_dim_tab index by binary_integer;
  l_opt_tab t_array_2_dim_tab;
  l_stop boolean := false;

  function eq(p_target_line in varchar2, p_source_line in varchar2)
  return boolean
  is
  begin
    return ( p_target_line is null and p_source_line is null ) or p_target_line = p_source_line;
  end eq;

  procedure add(p_line in varchar2, p_marker in varchar2, p_old in pls_integer, p_new in pls_integer)
  is
  begin
    if p_marker <> '=' or p_show_equal_lines
    then
      p_compare_line_tab(p_compare_line_tab.count+1) :=
        '[' ||
        to_char(p_old) ||
        '][' ||
        to_char(p_new) ||
        '] ' ||
        p_marker ||
        ' ' ||
        case
          when p_convert_to_base64 and p_line is not null
          then utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(p_line)))
          else p_line
        end;
    end if;
    if p_marker <> '=' and p_stop_after_first_diff
    then
      l_stop := true;
    end if;
  end add;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.enter(g_package_prefix || 'COMPARE (3)');
  dbug.print
  ( dbug."output"
  , 'p_source_line_tab.count: %s; p_target_line_tab.count: %s; p_stop_after_first_diff: %s; p_show_equal_lines: %s; p_convert_to_base64: %s'
  , p_source_line_tab.count
  , p_target_line_tab.count
  , dbug.cast_to_varchar2(p_stop_after_first_diff)
  , dbug.cast_to_varchar2(p_show_equal_lines)
  , dbug.cast_to_varchar2(p_convert_to_base64)
  );
$end

  -- Some checks to make life more easier.
  if p_target_line_tab.count > 0 and (p_target_line_tab.first != 1 or (p_target_line_tab.last - p_target_line_tab.first) + 1 != p_target_line_tab.count)
  then
    raise program_error;
  elsif p_source_line_tab.count > 0 and (p_source_line_tab.first != 1 or (p_source_line_tab.last - p_source_line_tab.first) + 1 != p_source_line_tab.count)
  then
    raise program_error;
  end if;

  /*
     The code is taken from Diff.java (http://introcs.cs.princeton.edu/java/96optimization/Diff.java.html)

     Variables:

     Java example  Here
     ------------  ----
     x             p_target_line_tab
     y             p_source_line_tab
     M             p_target_line_tab.count
     N             p_source_line_tab.count
     opt           l_opt_tab
  */

  /*
     In Java this creates a 2 dimensional array with all the indices filled and opt[i][j] = 0.

     int[][] opt = new int[M+1][N+1];

     Please note that in Java arrays start with index 0.

     The collections here start with 1 (due to the checks at the start).
  */

  -- Create an empty array slice with one more element than
  if p_source_line_tab.count > 0
  then
    for j in p_source_line_tab.first .. p_source_line_tab.last
    loop
      l_opt_tab(1)(j) := 0;
    end loop;
    l_opt_tab(1)(p_source_line_tab.count+1) := 0;
  end if;

  -- Use the empty array slice to fill the others.
  for i in 2 .. p_target_line_tab.count+1
  loop
    l_opt_tab(i) := l_opt_tab(1);
  end loop;

  -- compute length of LCS and all subproblems via dynamic programming
  if p_target_line_tab.count > 0
  then
    for i in reverse p_target_line_tab.first .. p_target_line_tab.last
    loop
      if p_source_line_tab.count > 0
      then
        for j in reverse p_source_line_tab.first .. p_source_line_tab.last
        loop
          if eq(p_target_line_tab(i), p_source_line_tab(j))
          then
            l_opt_tab(i)(j) := l_opt_tab(i+1)(j+1) + 1;
          else
            l_opt_tab(i)(j) := greatest(l_opt_tab(i+1)(j), l_opt_tab(i)(j+1));
          end if;
        end loop;
      end if;
    end loop;
  end if;

  declare
    i pls_integer := nvl(p_target_line_tab.first, 1);
    j pls_integer := nvl(p_source_line_tab.first, 1);
  begin
    -- recover LCS itself
    while (i <= p_target_line_tab.count and j <= p_source_line_tab.count) and not(l_stop)
    loop
      if eq(p_target_line_tab(i), p_source_line_tab(j))
      then
        add(p_target_line_tab(i), '=', i, j);
        i := i + 1;
        j := j + 1;
      elsif l_opt_tab(i+1)(j) >= l_opt_tab(i)(j+1)
      then
        add(p_target_line_tab(i), '-', i, j);
        i := i + 1;
      else
        add(p_source_line_tab(j), '+', i, j);
        j := j + 1;
      end if;
    end loop;

    -- dump out one remainder of one collection if the other is exhausted
    while (i <= p_target_line_tab.count or j <= p_source_line_tab.count) and not(l_stop)
    loop
      if i > p_target_line_tab.count
      then
        add(p_source_line_tab(j), '+', i, j);
        j := j + 1;
      elsif j > p_source_line_tab.count
      then
        add(p_target_line_tab(i), '-', i, j);
        i := i + 1;
      end if;
    end loop;
  end;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.print
  ( dbug."output"
  , 'p_compare_line_tab.count: %s'
  , p_compare_line_tab.count
  );
  dbug.leave;
$end

end compare;

procedure compare
( p_source in clob
, p_target in clob
, p_delimiter in varchar2
, p_stop_after_first_diff in boolean
, p_show_equal_lines in boolean
, p_convert_to_base64 in boolean
, p_compare_line_tab out nocopy dbms_sql.varchar2a
)
is
  l_source_line_tab dbms_sql.varchar2a;
  l_target_line_tab dbms_sql.varchar2a;
begin
  oracle_tools.pkg_str_util.split
  ( p_str => p_source
  , p_delimiter => p_delimiter
  , p_str_tab => l_source_line_tab
  );
  oracle_tools.pkg_str_util.split
  ( p_str => p_target
  , p_delimiter => p_delimiter
  , p_str_tab => l_target_line_tab
  );
  compare
  ( p_source_line_tab => l_source_line_tab
  , p_target_line_tab => l_target_line_tab
  , p_stop_after_first_diff => p_stop_after_first_diff
  , p_show_equal_lines => p_show_equal_lines
  , p_convert_to_base64 => p_convert_to_base64
  , p_compare_line_tab => p_compare_line_tab
  );
end compare;

procedure append_text
( pi_buffer in varchar2
, pio_clob in out nocopy clob
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.enter(g_package_prefix || 'APPEND_TEXT (1)');
  dbug.print
  ( dbug."input"
  , 'pi_buffer (max 100): %s; dbms_lob.getlength(pio_clob): %s'
  , substr(pi_buffer, 1, 100)
  , dbms_lob.getlength(pio_clob)
  );
$end

  if pi_buffer is not null
  then
    if pio_clob is null
    then
      dbms_lob.createtemporary(pio_clob, true);
    end if;
    dbms_lob.writeappend(lob_loc => pio_clob, amount => length(pi_buffer), buffer => pi_buffer);
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.print
  ( dbug."output"
  , 'dbms_lob.getlength(pio_clob): %s'
  , dbms_lob.getlength(pio_clob)
  );
  dbug.leave;
$end
end append_text;

procedure append_text
( pi_text in varchar2
, pio_buffer in out nocopy varchar2
, pio_clob in out nocopy clob
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.enter(g_package_prefix || 'APPEND_TEXT (2)');
$end

  begin
    pio_buffer := pio_buffer || pi_text;
  exception
    when value_error
    then
      append_text(pio_clob => pio_clob, pi_buffer => pio_buffer);
      pio_buffer := pi_text;
  end;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.leave;
$end
end append_text;

procedure text2clob
( pi_text_tab in oracle_tools.t_text_tab
, pio_clob in out nocopy clob
, pi_append in boolean := false
)
is
  l_buffer t_max_varchar2 := null;
  l_text t_max_varchar2;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.enter(g_package_prefix || 'TEXT2CLOB (1)');
  dbug.print
  ( dbug."input"
  , 'pi_text_tab.count: %s; dbms_lob.getlength(pio_clob): %s; pi_append: %s'
  , case when pi_text_tab is not null then pi_text_tab.count end
  , case when pio_clob is not null then dbms_lob.getlength(pio_clob) end
  , dbug.cast_to_varchar2(pi_append)
  );
$end

  if pio_clob is not null and not(pi_append)
  then
    dbms_lob.trim(pio_clob, 0);
  end if;

  if pi_text_tab is not null and pi_text_tab.count > 0
  then
    for i_idx in pi_text_tab.first .. pi_text_tab.last
    loop
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
      dbug.print(dbug."info", 'i_idx: %s', i_idx);
$end
      l_text := pi_text_tab(i_idx); -- GPA 2016-11-30 Otherwise we get a VALUE_ERROR (?!)
      oracle_tools.pkg_str_util.append_text(pi_text => l_text, pio_buffer => l_buffer, pio_clob => pio_clob);
    end loop;
  end if;
  -- flush the rest of the buffer
  oracle_tools.pkg_str_util.append_text(pi_buffer => l_buffer, pio_clob => pio_clob);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.leave;
$end
end text2clob;

function text2clob
( pi_text_tab in oracle_tools.t_text_tab
)
return clob
is
  l_clob clob := null;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.enter(g_package_prefix || 'TEXT2CLOB (2)');
  dbug.print
  ( dbug."input"
  , 'pi_text_tab.count: %s'
  , case when pi_text_tab is not null then pi_text_tab.count end
  );
$end

  text2clob
  ( pi_text_tab => pi_text_tab
  , pio_clob => l_clob
  , pi_append => false
  );

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.leave;
$end

  return l_clob;
end text2clob;

function clob2text
( pi_clob in clob
, pi_trim in naturaln
)
return oracle_tools.t_text_tab
is
  l_text_tab oracle_tools.t_text_tab := null;
  l_first pls_integer := 1;
  l_last pls_integer := dbms_lob.getlength(pi_clob);
  l_buffer t_sql_string;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.enter(g_package_prefix || 'CLOB2TEXT');
  dbug.print
  ( dbug."input"
  , 'pi_clob length: %s; pi_trim: %s'
  , l_last
  , pi_trim
  );
$end

  if l_last > 0
  then
    l_text_tab := oracle_tools.t_text_tab();

    if pi_trim <> 0
    then
      -- skip whitespace at the begin
      while l_first <= l_last and dbms_lob.substr(lob_loc => pi_clob, offset => l_first, amount => 1) in (chr(9), chr(10), chr(13), chr(32))
      loop
        l_first := l_first + 1;
      end loop;
      -- skip whitespace at the end
      while l_first <= l_last and dbms_lob.substr(lob_loc => pi_clob, offset => l_last, amount => 1) in (chr(9), chr(10), chr(13), chr(32))
      loop
        l_last := l_last - 1;
      end loop;
    end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
    dbug.print(dbug."info", 'l_first: %s; l_last: %s', l_first, l_last);
$end

    if l_first <= l_last
    then
      for i_chunk in 1 .. ceil((l_last - l_first + 1) / c_sql_string_size)
      loop
        l_buffer :=
          dbms_lob_substr
          ( p_clob => pi_clob
          , p_offset => l_first + (i_chunk-1) * c_sql_string_size
          , p_amount => c_sql_string_size
          , p_check => 'OL'              
          );
        l_text_tab.extend(1);
        l_text_tab(l_text_tab.last) := l_buffer;
      end loop;
    end if;
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.leave;
$end

  return l_text_tab;
end clob2text;

$if oracle_tools.cfg_pkg.c_testing $then

procedure ut_dbms_lob_substr
is
  l_str_act t_max_varchar2;
  l_str_exp t_max_varchar2;
begin
  dbms_lob.trim(g_clob_test, 0);

  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob(rpad('a', c_max_varchar2_size, 'a')));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob("crlf"));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob(rpad('b', c_max_varchar2_size, 'b')));

  for i_part in 1..3
  loop
    for i_case in 1..5 -- include 32768 as well
    loop
      l_str_act := dbms_lob_substr(g_clob_test, c_max_varchar2_size-4 + i_case, 1+c_max_varchar2_size*(i_part-1));
      l_str_exp := dbms_lob.substr(g_clob_test, c_max_varchar2_size-4 + i_case, 1+c_max_varchar2_size*(i_part-1));
      if i_case = 1 or i_part = 3
      then
        ut.expect(l_str_act, 'test contents dbms_lob_substr ' || i_part || '.' || i_case).to_equal(l_str_exp);
        ut.expect(length(l_str_act), 'test length dbms_lob_substr ' || i_part || '.' || i_case).to_equal(length(l_str_exp));
      elsif i_case = 5
      then
        ut.expect(l_str_act, 'test contents dbms_lob_substr ' || i_part || '.' || i_case).to_be_null();
        ut.expect(l_str_exp, 'test contents dbms_lob.substr ' || i_part || '.' || i_case).to_be_null();
      else
        ut.expect(l_str_act, 'test contents dbms_lob_substr ' || i_part || '.' || i_case).not_to_equal(l_str_exp);
        ut.expect(length(l_str_act), 'test length dbms_lob_substr ' || i_part || '.' || i_case).not_to_equal(length(l_str_exp));
      end if;
    end loop;
  end loop;
end;

procedure ut_split1
is
  l_str_tab dbms_sql.varchar2a;
begin
  /*
procedure split
( p_str in varchar2
, p_delimiter in varchar2 := ','
, p_str_tab out nocopy dbms_sql.varchar2a
);
*/
  begin
    split("null", "null", l_str_tab);
    raise value_error; -- should not come here since a program_error (ORA-06501) must be raised 
  exception
    when others
    then
      ut.expect(sqlcode, 'test 1.1').to_equal(-06501);
  end;

  split("null", "lf", l_str_tab);

  ut.expect(l_str_tab.count, 'test 2.1').to_equal(1);
  ut.expect(l_str_tab(1), 'test 2.2').to_be_null();

  split("lf" || 'abcd' || "lf" || 'efgh', "lf", l_str_tab);

  ut.expect(l_str_tab.count, 'test 3.1').to_equal(3);
  ut.expect(l_str_tab(1), 'test 3.2').to_be_null();
  ut.expect(l_str_tab(2), 'test 3.2').to_equal('abcd');
  ut.expect(l_str_tab(3), 'test 3.2').to_equal('efgh');

  split("crlf" || 'abcd' || "crlf" || 'efgh' || "crlf", "crlf", l_str_tab);

  ut.expect(l_str_tab.count, 'test 4.1').to_equal(4);
  ut.expect(l_str_tab(1), 'test 4.2').to_be_null();
  ut.expect(l_str_tab(2), 'test 4.3').to_equal('abcd');
  ut.expect(l_str_tab(3), 'test 4.4').to_equal('efgh');
  ut.expect(l_str_tab(4), 'test 4.5').to_be_null();

  split('abcd' || "crlf" || 'efgh', "crlf", l_str_tab);

  ut.expect(l_str_tab.count, 'test 5.1').to_equal(2);
  ut.expect(l_str_tab(1), 'test 5.2').to_equal('abcd');
  ut.expect(l_str_tab(2), 'test 5.3').to_equal('efgh');
end;

procedure ut_split2
is
  l_str_tab dbms_sql.varchar2a;
begin
  /*
procedure split
( p_str in clob
, p_delimiter in varchar2 := ','
, p_str_tab out nocopy dbms_sql.varchar2a
);
*/
  dbms_lob.trim(g_clob_test, 0);

  split("null clob", null, l_str_tab);

  ut.expect(l_str_tab.count, 'test 1.1').to_equal(1);
  ut.expect(l_str_tab(1), 'test 1.2').to_be_null();

  split(g_clob_test, "lf", l_str_tab);

  ut.expect(l_str_tab.count, 'test 2.1').to_equal(1);
  ut.expect(l_str_tab(1), 'test 2.2').to_be_null();

  split(to_clob("lf" || 'abcd' || "lf" || 'efgh'), "lf", l_str_tab);

  ut.expect(l_str_tab.count, 'test 3.1').to_equal(3);
  ut.expect(l_str_tab(1), 'test 3.2').to_be_null();
  ut.expect(l_str_tab(2), 'test 3.2').to_equal('abcd');
  ut.expect(l_str_tab(3), 'test 3.2').to_equal('efgh');

  split(to_clob("crlf" || 'abcd' || "crlf" || 'efgh' || "crlf"), "crlf", l_str_tab);

  ut.expect(l_str_tab.count, 'test 4.1').to_equal(4);
  ut.expect(l_str_tab(1), 'test 4.2').to_be_null();
  ut.expect(l_str_tab(2), 'test 4.3').to_equal('abcd');
  ut.expect(l_str_tab(3), 'test 4.4').to_equal('efgh');
  ut.expect(l_str_tab(4), 'test 4.5').to_be_null();

  split(to_clob('abcd' || "crlf" || 'efgh'), "crlf", l_str_tab);

  ut.expect(l_str_tab.count, 'test 5.1').to_equal(2);
  ut.expect(l_str_tab(1), 'test 5.2').to_equal('abcd');
  ut.expect(l_str_tab(2), 'test 5.3').to_equal('efgh');

  dbms_lob.trim(g_clob_test, 0);
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob(rpad('a', c_max_varchar2_size, 'a')));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob("crlf"));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob(rpad('b', c_max_varchar2_size, 'b')));

  split(g_clob_test, "crlf", l_str_tab);

  ut.expect(dbms_lob.getlength(g_clob_test), 'test 6.0').to_equal(c_max_varchar2_size * 2 + 2);
  ut.expect(l_str_tab.count, 'test 6.1').to_equal(2);
  ut.expect(l_str_tab(1), 'test 6.2').to_equal(rpad('a', c_max_varchar2_size, 'a'));
  ut.expect(l_str_tab(2), 'test 6.3').to_equal(rpad('b', c_max_varchar2_size, 'b'));

  dbms_lob.trim(g_clob_test, 0);
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob(rpad('a', c_max_varchar2_size, 'a')));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob(rpad('b', c_max_varchar2_size, 'b')));

  split(g_clob_test, null, l_str_tab);

  ut.expect(dbms_lob.getlength(g_clob_test), 'test 7.0').to_equal(c_max_varchar2_size * 2);
  ut.expect(l_str_tab.count, 'test 7.1').to_equal(2);
  ut.expect(l_str_tab(1), 'test 7.2').to_equal(rpad('a', c_max_varchar2_size, 'a'));
  ut.expect(l_str_tab(2), 'test 7.3').to_equal(rpad('b', c_max_varchar2_size, 'b'));
end;

procedure ut_split3
is
  l_str_tab t_clob_tab;
begin
  /*
procedure split
( p_str in clob
, p_delimiter in varchar2 := ','
, p_str_tab out nocopy t_clob_tab
);
*/
  dbms_lob.trim(g_clob_test, 0);

  split("null clob", null, l_str_tab);

  ut.expect(l_str_tab.count, 'test 1.1').to_equal(1);
  ut.expect(dbms_lob.getlength(l_str_tab(1)), 'test 1.2').to_be_null();

  split(g_clob_test, "lf", l_str_tab);

  ut.expect(l_str_tab.count, 'test 2.1').to_equal(1);
  ut.expect(dbms_lob.getlength(l_str_tab(1)), 'test 2.2').to_be_null();

  split(to_clob("lf" || 'abcd' || "lf" || 'efgh'), "lf", l_str_tab);

  ut.expect(l_str_tab.count, 'test 3.1').to_equal(3);
  ut.expect(dbms_lob.getlength(l_str_tab(1)), 'test 3.2').to_be_null();
  ut.expect(l_str_tab(2), 'test 3.2').to_equal(to_clob('abcd'));
  ut.expect(l_str_tab(3), 'test 3.2').to_equal(to_clob('efgh'));

  split(to_clob("crlf" || 'abcd' || "crlf" || 'efgh' || "crlf"), "crlf", l_str_tab);

  ut.expect(l_str_tab.count, 'test 4.1').to_equal(4);
  ut.expect(dbms_lob.getlength(l_str_tab(1)), 'test 4.2').to_be_null();
  ut.expect(l_str_tab(2), 'test 4.3').to_equal(to_clob('abcd'));
  ut.expect(l_str_tab(3), 'test 4.4').to_equal(to_clob('efgh'));
  ut.expect(dbms_lob.getlength(l_str_tab(4)), 'test 4.5').to_be_null();

  split(to_clob('abcd' || "crlf" || 'efgh'), "crlf", l_str_tab);

  ut.expect(l_str_tab.count, 'test 5.1').to_equal(2);
  ut.expect(l_str_tab(1), 'test 5.2').to_equal(to_clob('abcd'));
  ut.expect(l_str_tab(2), 'test 5.3').to_equal(to_clob('efgh'));

  dbms_lob.trim(g_clob_test, 0);
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob(rpad('a', c_max_varchar2_size, 'a')));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob("crlf"));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob(rpad('b', c_max_varchar2_size, 'b')));

  split(g_clob_test, "crlf", l_str_tab);

  ut.expect(dbms_lob.getlength(g_clob_test), 'test 6.0').to_equal(c_max_varchar2_size * 2 + 2);
  ut.expect(l_str_tab.count, 'test 6.1').to_equal(2);
  ut.expect(l_str_tab(1), 'test 6.2').to_equal(to_clob(rpad('a', c_max_varchar2_size, 'a')));
  ut.expect(l_str_tab(2), 'test 6.3').to_equal(to_clob(rpad('b', c_max_varchar2_size, 'b')));

  dbms_lob.trim(g_clob_test, 0);
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob(rpad('a', c_max_varchar2_size, 'a')));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob(rpad('b', c_max_varchar2_size, 'b')));

  split(g_clob_test, null, l_str_tab);

  ut.expect(dbms_lob.getlength(g_clob_test), 'test 7.0').to_equal(c_max_varchar2_size * 2);
  ut.expect(l_str_tab.count, 'test 7.1').to_equal(1);
  ut.expect(l_str_tab(1), 'test 7.2').to_equal(g_clob_test);
end;

procedure ut_trim1
is
begin
/*
trim
( p_str in out nocopy clob
, p_set in varchar2 := ' '
);
*/
  dbms_lob.trim(g_clob_test, 0);

  trim(g_clob_test, null);
  ut.expect(dbms_lob.getlength(g_clob_test), 'test 1').to_equal(0);
  
  trim(g_clob_test, 'a');
  ut.expect(dbms_lob.getlength(g_clob_test), 'test 2').to_equal(0);

  dbms_lob.trim(g_clob_test, 0);
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob('abcd'));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob("crlf"));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob('dcba'));
  trim(g_clob_test, 'abcd');
  ut.expect(g_clob_test, 'test 3').to_equal(to_clob("crlf"));

  dbms_lob.trim(g_clob_test, 0);
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob('abcd'));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob("crlf"));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob('dcba'));
  trim(g_clob_test, 'a');
  ut.expect(g_clob_test, 'test 4').to_equal(to_clob('bcd' || "crlf" || 'dcb'));
  
  dbms_lob.trim(g_clob_test, 0);
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob('abcd'));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob("crlf"));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob('dcba'));
  trim(g_clob_test, 'ab');
  ut.expect(g_clob_test, 'test 5').to_equal(to_clob('cd' || "crlf" || 'dc'));
  
  dbms_lob.trim(g_clob_test, 0);
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob('abcd'));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob("crlf"));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob('dcba'));
  trim(g_clob_test, 'b');
  ut.expect(g_clob_test, 'test 5').to_equal(to_clob('abcd' || "crlf" || 'dcba'));
end;

procedure ut_trim2
is
begin
  raise program_error;
end;

procedure ut_compare1
is
begin
  raise program_error;
end;

procedure ut_compare2
is
begin
  raise program_error;
end;

procedure ut_append_text1
is
begin
  raise program_error;
end;

procedure ut_append_text2
is
begin
  raise program_error;
end;

procedure ut_text2clob1
is
begin
  raise program_error;
end;

procedure ut_text2clob2
is
begin
  raise program_error;
end;

procedure ut_clob2text
is
begin
  raise program_error;
end;

procedure ut_split2_line_too_large
is
  l_str_tab dbms_sql.varchar2a;
  l_responses1 constant t_max_varchar2 := '
    "responses" : "[
        {
            \"title_code\":\"ONB_CONTACT_EMAIL_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":\"^\\\\w+([\\\\.-]?\\\\w+)*@\\\\w+([\\\\.-]?\\\\w+)*(\\\\.\\\\w{2,4})+$\"},{\"title_code\":\"ONB_CUST_TYPE_ID_Q\",\"answer\":\"1\",\"readonly\":false,\"refresh\":true,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"1\",\"d\":\"Private\",\"i\":null},{\"v\":\"2\",\"d\":\"Company\",\"i\":null}]},{\"title_code\":\"ONB_COMPANY_NAME_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_KVK_NUMBER_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_BTW_NUMBER_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_CONTACT_SALUATION_Q\",\"answer\":\"De heer\",\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"De heer\",\"d\":\"Mr.\",\"i\":null},{\"v\":\"Mevrouw\",\"d\":\"Mrs.\",\"i\":null}]},{\"title_code\":\"ONB_CONTACT_FIRSTNAME_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_CONTACT_LASTNAME_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_CONTACT_COUNTRY_CODE_Q\",\"answer\":\"BE\",\"readonly\":false,\"refresh\":true,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"BE\",\"d\":\"België\",\"i\":null},{\"v\":\"DE\",\"d\":\"Duitsland\",\"i\":null},{\"v\":\"LU\",\"d\":\"Luxemburg\",\"i\":null},{\"v\":\"NL\",\"d\":\"Nederland\",\"i\":null}]},{\"title_code\":\"ONB_CONTACT_ZIP_CODE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_CONTACT_HOUSENUMBER_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_CONTACT_STREET_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_CONTACT_CITY_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_CONTACT_TELEPHONE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_LOCATION_SAME_Q\",\"answer\":\"1\",\"readonly\":false,\"refresh\":true,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"1\",\"d\":\"Yes\",\"i\":null},{\"v\":\"0\",\"d\":\"No\",\"i\":null}]},{\"title_code\":\"ONB_LOCATION_COUNTRY_CODE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"BE\",\"d\":\"België\",\"i\":null},{\"v\":\"DE\",\"d\":\"Duitsland\",\"i\":null},{\"v\":\"LU\",\"d\":\"Luxemburg\",\"i\":null},{\"v\":\"NL\",\"d\":\"Nederland\",\"i\":null}]},{\"title_code\":\"ONB_LOCATION_ZIP_CODE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_LOCATION_HOUSENUMBER_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_LOCATION_STREET_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_LOCATION_CITY_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_LOCATION_TELEPHONE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_TECHNICAL_SALUATION_Q\",\"answer\":\"De heer\",\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"De heer\",\"d\":\"Mr.\",\"i\":null},{\"v\":\"Mevrouw\",\"d\":\"Mrs.\",\"i\":null}]},{\"title_code\":\"ONB_TECHNICAL_FIRSTNAME_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_TECHNICAL_LASTNAME_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_TECHNICAL_EMAIL_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":\"^\\\\w+([\\\\.-]?\\\\w+)*@\\\\w+([\\\\.-]?\\\\w+)*(\\\\.\\\\w{2,4})+$\"},{\"title_code\":\"ONB_TECHNICAL_TELEPHONE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_SUBSCRIPTION_TYPE_Q\",\"answer\":\"BASIS\",\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"BASIS\",\"d\":\"Basic support\",\"i\":\"https://xqor3b69vfiecdt-dbsmart01.adb.eu-frankfurt-1.oraclecloudapps.com/ords/bcp_api/api/v1/onboarding-image/ONB_SUBSCRIPTION_TYPE_Q/BASIS/content\"},{\"v\":\"EXTENDED\",\"d\":\"Extended support\",\"i\":\"https://xqor3b69vfiecdt-dbsmart01.adb.eu-frankfurt-1.oraclecloudapps.com/ords/bcp_api/api/v1/onboarding-image/ONB_SUBSCRIPTION_TYPE_Q/EXTENDED/content\"},{\"v\":\"FULL\",\"d\":\"Full support\",\"i\":\"https://xqor3b69vfiecdt-dbsmart01.adb.eu-frankfurt-1.oraclecloudapps.com/ords/bcp_api/api/v1/onboarding-image/ONB_SUBSCRIPTION_TYPE_Q/FULL/content\"}]},{\"title_code\":\"ONB_START_DATE_CONTRACT_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_SUBSCRIPTION_SAME_Q\",\"answer\":\"1\",\"readonly\":false,\"refresh\":true,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"1\",\"d\":\"Yes\",\"i\":null},{\"v\":\"0\",\"d\":\"No\",\"i\":null}]},{\"title_code\":\"ONB_SUBSCRIPTION_NAME_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_SUBSCRIPTION_EMAIL_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":\"^\\\\w+([\\\\.-]?\\\\w+)*@\\\\w+([\\\\.-]?\\\\w+)*(\\\\.\\\\w{2,4})+$\"},{\"title_code\":\"ONB_SUBSCRIPTION_COUNTRY_CODE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"BE\",\"d\":\"België\",\"i\":null},{\"v\":\"DE\",\"d\":\"Duitsland\",\"i\":null},{\"v\":\"LU\",\"d\":\"Luxemburg\",\"i\":null},{\"v\":\"NL\",\"d\":\"Nederland\",\"i\":null}]},{\"title_code\":\"ONB_SUBSCRIPTION_ZIP_CODE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_SUBSCRIPTION_HOUSENUMBER_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_SUBSCRIPTION_STREET_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_SUBSCRIPTION_CITY_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_SUBSCRIPTION_REFERENCE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_IBAN_BENEFICIARY_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_BENEFICIARY_REFERENCE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_BENEFICIARY_PERIOD_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"monthly\",\"d\":\"Payment each month\",\"i\":null},{\"v\":\"quarterly\",\"d\":\"Payment each 3 months\",\"i\":null},{\"v\":\"yearly\",\"d\":\"Payment each 12 months\",\"i\":null}]},{\"title_code\":\"ONB_BENEFICIARY_SAME_Q\",\"answer\":null,\"readonly\":false,\"refresh\":true,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"1\",\"d\":\"Yes\",\"i\":null},{\"v\":\"0\",\"d\":\"No\",\"i\":null}]},{\"title_code\":\"ONB_BENEFICIARY_NAME_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_BENEFICIARY_EMAIL_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":\"^\\\\w+([\\\\.-]?\\\\w+)*@\\\\w+([\\\\.-]?\\\\w+)*(\\\\.\\\\w{2,4})+$\"},';
  l_responses2 constant t_max_varchar2 := '{\"title_code\":\"ONB_BENEFICIARY_COUNTRY_CODE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"BE\",\"d\":\"België\",\"i\":null},{\"v\":\"DE\",\"d\":\"Duitsland\",\"i\":null},{\"v\":\"LU\",\"d\":\"Luxemburg\",\"i\":null},{\"v\":\"NL\",\"d\":\"Nederland\",\"i\":null}]},{\"title_code\":\"ONB_BENEFICIARY_ZIP_CODE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_BENEFICIARY_HOUSENUMBER_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_BENEFICIARY_STREET_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_BENEFICIARY_CITY_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_PUBLISH_YN_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"Y\",\"d\":\"Yes\",\"i\":null},{\"v\":\"N\",\"d\":\"No\",\"i\":null}]},{\"title_code\":\"ONB_PLUG_AND_CHARGE_YN_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"Y\",\"d\":\"Yes\",\"i\":null},{\"v\":\"N\",\"d\":\"No\",\"i\":null}]},{\"title_code\":\"ONB_GUEST_USAGE_YN_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"Y\",\"d\":\"Yes\",\"i\":null},{\"v\":\"N\",\"d\":\"No\",\"i\":null}]},{\"title_code\":\"ONB_FIRST_PASS_NUMBER_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_SECOND_PASS_NUMBER_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_FREE_CHARGING_ADDITIONAL_CARDS_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"Y\",\"d\":\"Yes\",\"i\":null},{\"v\":\"N\",\"d\":\"No\",\"i\":null}]},{\"title_code\":\"ONB_FINANCIAL_CHARGING_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"free\",\"d\":\"All passes can be used for free\",\"i\":null},{\"v\":\"paying\",\"d\":\"For each pass you have to pay\",\"i\":null}]},{\"title_code\":\"ONB_CHARGE_POINT_RATE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"NLBCUT74\",\"d\":\"10,89 cent incl (9 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT12\",\"d\":\"12 cent incl (9,92 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT48\",\"d\":\"12,1 cent incl (10 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT49\",\"d\":\"13,31 cent incl (11 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT50\",\"d\":\"14,52 cent incl (12 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT51\",\"d\":\"15,73 cent incl (13 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT52\",\"d\":\"16,94 cent incl (14 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT53\",\"d\":\"18,15 cent incl (15 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT7\",\"d\":\"19 cent incl (15,7 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT54\",\"d\":\"19,36 cent incl (16 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT2\",\"d\":\"20 cent incl (16,53 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT55\",\"d\":\"20,57 cent incl (17 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT20\",\"d\":\"21 cent incl (17,36 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT56\",\"d\":\"21,78 cent incl (18 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT47\",\"d\":\"22 cent incl (18,18 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT23\",\"d\":\"22,44 cent incl (18,55 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT57\",\"d\":\"22,99 cent incl (19 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT3\",\"d\":\"24 cent incl (19,83 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT58\",\"d\":\"24,2  cent incl (20 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT79\",\"d\":\"25 cent incl (20,66 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT59\",\"d\":\"25,41 cent incl (21 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT19\",\"d\":\"25,59 cent incl (21,15 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT45\",\"d\":\"26 cent incl (21,49 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT60\",\"d\":\"26,62 cent incl (22 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT11\",\"d\":\"27 cent incl (22,31 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT61\",\"d\":\"27,83 cent incl (23 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT16\",\"d\":\"28 cent incl (23,14 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT4\",\"d\":\"29 cent incl (23,97 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT62\",\"d\":\"29,04 cent incl (24 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT10\",\"d\":\"30 cent incl (24,79 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT63\",\"d\":\"30,25 cent incl (25 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT14\",\"d\":\"31 cent incl (25,62 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT64\",\"d\":\"31,46 cent incl (26 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT21\",\"d\":\"32 cent incl (26,45 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT65\",\"d\":\"32,67 cent incl (27 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT13\",\"d\":\"33 cent incl (27,27 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT66\",\"d\":\"33,88 cent incl (28 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT8\",\"d\":\"34 cent incl (28,1 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT5\",\"d\":\"35 cent incl (28,93 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT6\",\"d\":\"35 cent incl, Start tarief: 1.50 euro (21%)\",\"i\":null},{\"v\":\"NLBCUT67\",\"d\":\"35,09 cent incl (29 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT46\",\"d\":\"35,45 cent incl (29,3 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT9\",\"d\":\"36 cent incl (29,75 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT68\",\"d\":\"36,3 cent incl (30 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT77\",\"d\":\"37 cent incl (30,58 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT78\",\"d\":\"37 cent incl, Start tarief: 1.50 euro (21%)\",\"i\":null},{\"v\":\"NLBCUT69\",\"d\":\"37,51 cent incl (31 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT122\",\"d\":\"38 cent incl (31,4 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT70\",\"d\":\"38,72 cent incl (32 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT15\",\"d\":\"39 cent incl (32,23 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT71\",\"d\":\"39,93 cent incl (33 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT24\",\"d\":\"40 cent incl (33,06 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT25\",\"d\":\"41 cent incl (33,88 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT72\",\"d\":\"41,14 cent incl (34 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT26\",\"d\":\"42 cent incl (34,71 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT73\",\"d\":\"42,35 cent incl (35 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT27\",\"d\":\"43 cent incl (35,54 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT95\",\"d\":\"43,56 cent incl (36 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT28\",\"d\":\"44 cent incl (36,36 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT96\",\"d\":\"44,77 cent incl (37 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT29\",\"d\":\"45 cent incl (37,19 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT97\",\"d\":\"45,98 cent incl (38 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT30\",\"d\":\"46 cent incl (38,02 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT31\",\"d\":\"47 cent incl (38,84 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT98\",\"d\":\"47,19 cent incl (39 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT32\",\"d\":\"48 cent incl (39,67 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT99\",\"d\":\"48,40 cent incl (40 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT33\",\"d\":\"49 cent incl (40,5 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT100\",\"d\":\"49,61 cent incl (41 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT34\",\"d\":\"50 cent incl (41,32 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT101\",\"d\":\"50,82 cent incl (42 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT35\",\"d\":\"51 cent incl (42,15 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT36\",\"d\":\"52 cent incl (42,98 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT102\",\"d\":\"52,03 cent incl (43 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT37\",\"d\":\"53 cent incl (43,8 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT103\",\"d\":\"53,24 cent incl (44 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT38\",\"d\":\"54 cent incl (44,63 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT104\",\"d\":\"54,45 cent incl (45 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT39\",\"d\":\"55 cent incl (45,45 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT105\",\"d\":\"55,66 cent incl (46 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT40\",\"d\":\"56 cent incl (46,28 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT106\",\"d\":\"56,87 cent incl (47 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT41\",\"d\":\"57 cent incl (47,11 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT42\",\"d\":\"58 cent incl (47,93 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT107\",\"d\":\"58,08 cent incl (48 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT43\",\"d\":\"59 cent incl (48,76 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT108\",\"d\":\"59,29 cent incl (49 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT22\",\"d\":\"6 cent incl (4,96 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT44\",\"d\":\"60 cent incl (49,59 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT109\",\"d\":\"60,50 cent incl (50 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT110\",\"d\":\"61,71 cent incl (51 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT111\",\"d\":\"62,92 cent incl (52 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT87\",\"d\":\"62,95 cent incl (52,03 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT112\",\"d\":\"64,13 cent incl (53 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT113\",\"d\":\"65,34 cent incl (54 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT114\",\"d\":\"66,55 cent incl (55 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT115\",\"d\":\"67,76 cent incl (56 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT116\",\"d\":\"68,97 cent incl (57 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT117\",\"d\":\"70,18 cent incl (58 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT118\",\"d\":\"71,39 cent incl (59 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT119\",\"d\":\"72,60 cent incl (60 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT17\",\"d\":\"73,205 cent incl (60,5 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT125\",\"d\":\"75,02 cent incl (62 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT121\",\"d\":\"78,65 cent incl (65 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT76\",\"d\":\"8,47 cent incl (7 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT120\",\"d\":\"81,07 cent incl (67 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT124\",\"d\":\"83,49 cent incl (69 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT123\",\"d\":\"87,12 cent incl (72 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT75\",\"d\":\"9,68 cent incl (8 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT126\",\"d\":\"94,38 cent incl (78 cent excl) (21%)\",\"i\":null},{\"v\":\"NLBCUT1\",\"d\":\"Gratis laden\",\"i\":null}]},{\"title_code\":\"ONB_ORDER_DATE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_DELIVERY_DATE_CAR_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_DRIVER_FIRSTNAME_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_DRIVER_LASTNAME_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_DRIVER_EMAIL_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":true,\"regexp\":\"^\\\\w+([\\\\.-]?\\\\w+)*@\\\\w+([\\\\.-]?\\\\w+)*(\\\\.\\\\w{2,4})+$\"},{\"title_code\":\"ONB_MOBILE_NUMBER_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_CAR_BRAND_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_CAR_TYPE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":false,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_TARIFF_EX_VAT_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"1\",\"d\":\"1\",\"i\":null},{\"v\":\"2\",\"d\":\"2\",\"i\":null},{\"v\":\"3\",\"d\":\"3\",\"i\":null},{\"v\":\"4\",\"d\":\"4\",\"i\":null},{\"v\":\"5\",\"d\":\"5\",\"i\":null},{\"v\":\"6\",\"d\":\"6\",\"i\":null},{\"v\":\"7\",\"d\":\"7\",\"i\":null},{\"v\":\"8\",\"d\":\"8\",\"i\":null},{\"v\":\"9\",\"d\":\"9\",\"i\":null},{\"v\":\"10\",\"d\":\"10\",\"i\":null},{\"v\":\"11\",\"d\":\"11\",\"i\":null},{\"v\":\"12\",\"d\":\"12\",\"i\":null},{\"v\":\"13\",\"d\":\"13\",\"i\":null},{\"v\":\"14\",\"d\":\"14\",\"i\":null},{\"v\":\"15\",\"d\":\"15\",\"i\":null},{\"v\":\"16\",\"d\":\"16\",\"i\":null},{\"v\":\"17\",\"d\":\"17\",\"i\":null},{\"v\":\"18\",\"d\":\"18\",\"i\":null},{\"v\":\"19\",\"d\":\"19\",\"i\":null},{\"v\":\"20\",\"d\":\"20\",\"i\":null},{\"v\":\"21\",\"d\":\"21\",\"i\":null},{\"v\":\"22\",\"d\":\"22\",\"i\":null},{\"v\":\"23\",\"d\":\"23\",\"i\":null},{\"v\":\"24\",\"d\":\"24\",\"i\":null},{\"v\":\"25\",\"d\":\"25\",\"i\":null},{\"v\":\"26\",\"d\":\"26\",\"i\":null},{\"v\":\"27\",\"d\":\"27\",\"i\":null},{\"v\":\"28\",\"d\":\"28\",\"i\":null},{\"v\":\"29\",\"d\":\"29\",\"i\":null},{\"v\":\"30\",\"d\":\"30\",\"i\":null}]},{\"title_code\":\"ONB_IBAN_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_PRODUCT_Q\",\"answer\":null,\"readonly\":false,\"refresh\":true,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"426\",\"d\":\"EVE vaste kabel 8m (Product)\",\"i\":null}]},{\"title_code\":\"ONB_CUSTOM_COLOUR_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_INSTALLATION_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"634\",\"d\":\"Afmontage laadpunt wand (Installation)\",\"i\":null},{\"v\":\"423\",\"d\":\"Extra datakabel (Installation)\",\"i\":null},{\"v\":\"428\",\"d\":\"Fulfilment (Installation)\",\"i\":null},{\"v\":\"391\",\"d\":\"Installatiekosten wandmontage incl fulfilment (Installation)\",\"i\":null},{\"v\":\"429\",\"d\":\"P1 splitter leveren en plaatsen (Installation)\",\"i\":null},{\"v\":\"430\",\"d\":\"Verhuizen paalmontage incl fulfilment (Installation)\",\"i\":null},{\"v\":\"431\",\"d\":\"Verhuizen wandmontage incl fulfilment (Installation)\",\"i\":null},{\"v\":\"424\",\"d\":\"Vervangen meterkast (Installation)\",\"i\":null}]},{\"title_code\":\"ONB_SMART_CHARGING_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null,\"lov\":[{\"v\":\"427\",\"d\":\"EVE smart charging (Smartcharging)\",\"i\":null}]},{\"title_code\":\"ONB_POLE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null,\"lov\":[{\"v\":\"392\",\"d\":\"EVE paal (Pole)\",\"i\":null}]},{\"title_code\":\"ONB_SUBSCRIPTION_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_CAPACITY_INSTL_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"1-25\",\"d\":\"1 phase - 25A\",\"i\":null},{\"v\":\"1-35\",\"d\":\"1 phase - 35A\",\"i\":null},{\"v\":\"1-40\",\"d\":\"1 phase - 40A\",\"i\":null},{\"v\":\"3-25\",\"d\":\"3 phase - 25A\",\"i\":null},{\"v\":\"UNSURE\",\"d\":\"Different / Not sure\",\"i\":null},{\"v\":\"3-40\",\"d\":\"3 phase - 40A\",\"i\":null},{\"v\":\"3-63\",\"d\":\"3 phase - 63A\",\"i\":null},{\"v\":\"3-80\",\"d\":\"3 phase - 80A\",\"i\":null},{\"v\":\"3-35\",\"d\":\"3 phase - 35A\",\"i\":null}]},{\"title_code\":\"ONB_NUMBER_PHASE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"3 PHASE\",\"d\":\"3 Phase (> 10 kW)\",\"i\":null},{\"v\":\"1 PHASE\",\"d\":\"1 Phase (< 10 kW)\",\"i\":null}]},{\"title_code\":\"ONB_TYPE_SMART_METER_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"IskraAM550_OK_3\",\"d\":\"Iskra AM550 (suitable)\",\"i\":null},{\"v\":\"IskraME382_NO_1\",\"d\":\"Iskra ME382 (not suitable)\",\"i\":null},{\"v\":\"IskraMT382_NO_3\",\"d\":\"Iskra MT382 (not suitable)\",\"i\":null},{\"v\":\"KaifaE0003_NO_3\",\"d\":\"Kaifa E0003 (not suitable)\",\"i\":null},{\"v\":\"KaifaE0025_OK_1\",\"d\":\"Kaifa E0025 (suitable)\",\"i\":null},{\"v\":\"KaifaE0026_OK_3\",\"d\":\"Kaifa E0026 (suitable)\",\"i\":null},{\"v\":\"KaifaMA105_NO_1\",\"d\":\"Kaifa MA105 (not suitable)\",\"i\":null},{\"v\":\"KaifaMA105C_OK_1\",\"d\":\"Kaifa MA105C (suitable)\",\"i\":null},{\"v\":\"KaifaMA304_NO_3\",\"d\":\"Kaifa MA304 (suitable)\",\"i\":null},{\"v\":\"KaifaMA304C_OK_3\",\"d\":\"Kaifa MA304C (suitable)\",\"i\":null},{\"v\":\"Kamstrup162_NO_1\",\"d\":\"Kamstrup 162 (not suitable)\",\"i\":null},{\"v\":\"Kamstrup351_NO_3\",\"d\":\"Kamstrup 351 (not suitable)\",\"i\":null},{\"v\":\"Kamstrup382_NO_3\",\"d\":\"Kamstrup 382 (not suitable)\",\"i\":null},{\"v\":\"LandisE360SMR50_OK_1-3\",\"d\":\"Landis E360 SMR 5.0 (suitable)\",\"i\":null},{\"v\":\"LandisZCF_NO_1\",\"d\":\"Landis ZCF DSMR4.0 (not suitable)\",\"i\":null},{\"v\":\"LandisZCF_OK_1\",\"d\":\"Landis ZCF DSMR4.2 (suitable)\",\"i\":null},{\"v\":\"LandisZFF_NO_3\",\"d\":\"Landis ZFF (not suitable)\",\"i\":null},{\"v\":\"LandisZMF100_NO_1-3\",\"d\":\"Landis ZMF100 (not suitable)\",\"i\":null},{\"v\":\"LandisZMF110CB_OK_3\",\"d\":\"Landis ZMF110CB (suitable)\",\"i\":null},{\"v\":\"LandisZMF110CC_OK_3\",\"d\":\"Landis ZMF110CC (suitable)\",\"i\":null},{\"v\":\"other\",\"d\":\"Other (upload photo)\",\"i\":null},{\"v\":\"SagemcomT210_OK_3\",\"d\":\"Sagemcom T210 (suitable)\",\"i\":null}]},{\"title_code\":\"ONB_METER_NUMBER_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_ETHERNET_CONN_AVL_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"YES-ETHERNET\",\"d\":\"Yes, ethernet\",\"i\":null},{\"v\":\"YES-WIFI\",\"d\":\"Yes, strong WIFI signal\",\"i\":null},{\"v\":\"NO-ELSE\",\"d\":\"No, different location\",\"i\":null},{\"v\":\"NO\",\"d\":\"No internet possible\",\"i\":null}]},{\"title_code\":\"ONB_DISTANCE_FUSE_TO_CHARGER_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_CRAWL_SPACE_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null,\"lov\":[{\"v\":\"Y\",\"d\":\"Crawl space available?\",\"i\":null}]},{\"title_code\":\"ONB_CRAWL_SPACE_DRY_YN_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null,\"lov\":[{\"v\":\"Y\",\"d\":\"Crawl space dry?\",\"i\":null}]},{\"title_code\":\"ONB_METERS_DIGGING_TYPE1_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"1\",\"d\":\"1\",\"i\":null},{\"v\":\"2\",\"d\":\"2\",\"i\":null},{\"v\":\"3\",\"d\":\"3\",\"i\":null},{\"v\":\"4\",\"d\":\"4\",\"i\":null},{\"v\":\"5\",\"d\":\"5\",\"i\":null},{\"v\":\"6\",\"d\":\"6\",\"i\":null},{\"v\":\"7\",\"d\":\"7\",\"i\":null},{\"v\":\"8\",\"d\":\"8\",\"i\":null},{\"v\":\"9\",\"d\":\"9\",\"i\":null},{\"v\":\"10\",\"d\":\"10\",\"i\":null},{\"v\":\"11\",\"d\":\"11\",\"i\":null},{\"v\":\"12\",\"d\":\"12\",\"i\":null},{\"v\":\"13\",\"d\":\"13\",\"i\":null},{\"v\":\"14\",\"d\":\"14\",\"i\":null},{\"v\":\"15\",\"d\":\"15\",\"i\":null},{\"v\":\"16\",\"d\":\"16\",\"i\":null},{\"v\":\"17\",\"d\":\"17\",\"i\":null},{\"v\":\"18\",\"d\":\"18\",\"i\":null},{\"v\":\"19\",\"d\":\"19\",\"i\":null},{\"v\":\"20\",\"d\":\"20\",\"i\":null},{\"v\":\"21\",\"d\":\"21\",\"i\":null},{\"v\":\"22\",\"d\":\"22\",\"i\":null},{\"v\":\"23\",\"d\":\"23\",\"i\":null},{\"v\":\"24\",\"d\":\"24\",\"i\":null},{\"v\":\"25\",\"d\":\"25\",\"i\":null}]},{\"title_code\":\"ONB_METERS_DIGGING_TYPE2_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"1\",\"d\":\"1\",\"i\":null},{\"v\":\"2\",\"d\":\"2\",\"i\":null},{\"v\":\"3\",\"d\":\"3\",\"i\":null},{\"v\":\"4\",\"d\":\"4\",\"i\":null},{\"v\":\"5\",\"d\":\"5\",\"i\":null},{\"v\":\"6\",\"d\":\"6\",\"i\":null},{\"v\":\"7\",\"d\":\"7\",\"i\":null},{\"v\":\"8\",\"d\":\"8\",\"i\":null},{\"v\":\"9\",\"d\":\"9\",\"i\":null},{\"v\":\"10\",\"d\":\"10\",\"i\":null},{\"v\":\"11\",\"d\":\"11\",\"i\":null},{\"v\":\"12\",\"d\":\"12\",\"i\":null},{\"v\":\"13\",\"d\":\"13\",\"i\":null},{\"v\":\"14\",\"d\":\"14\",\"i\":null},{\"v\":\"15\",\"d\":\"15\",\"i\":null},{\"v\":\"16\",\"d\":\"16\",\"i\":null},{\"v\":\"17\",\"d\":\"17\",\"i\":null},{\"v\":\"18\",\"d\":\"18\",\"i\":null},{\"v\":\"19\",\"d\":\"19\",\"i\":null},{\"v\":\"20\",\"d\":\"20\",\"i\":null},{\"v\":\"21\",\"d\":\"21\",\"i\":null},{\"v\":\"22\",\"d\":\"22\",\"i\":null},{\"v\":\"23\",\"d\":\"23\",\"i\":null},{\"v\":\"24\",\"d\":\"24\",\"i\":null},{\"v\":\"25\",\"d\":\"25\",\"i\":null}]},{\"title_code\":\"ONB_METERS_DIGGING_TYPE3_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":true,\"regexp\":null,\"lov\":[{\"v\":\"1\",\"d\":\"1\",\"i\":null},{\"v\":\"2\",\"d\":\"2\",\"i\":null},{\"v\":\"3\",\"d\":\"3\",\"i\":null},{\"v\":\"4\",\"d\":\"4\",\"i\":null},{\"v\":\"5\",\"d\":\"5\",\"i\":null},{\"v\":\"6\",\"d\":\"6\",\"i\":null},{\"v\":\"7\",\"d\":\"7\",\"i\":null},{\"v\":\"8\",\"d\":\"8\",\"i\":null},{\"v\":\"9\",\"d\":\"9\",\"i\":null},{\"v\":\"10\",\"d\":\"10\",\"i\":null},{\"v\":\"11\",\"d\":\"11\",\"i\":null},{\"v\":\"12\",\"d\":\"12\",\"i\":null},{\"v\":\"13\",\"d\":\"13\",\"i\":null},{\"v\":\"14\",\"d\":\"14\",\"i\":null},{\"v\":\"15\",\"d\":\"15\",\"i\":null},{\"v\":\"16\",\"d\":\"16\",\"i\":null},{\"v\":\"17\",\"d\":\"17\",\"i\":null},{\"v\":\"18\",\"d\":\"18\",\"i\":null},{\"v\":\"19\",\"d\":\"19\",\"i\":null},{\"v\":\"20\",\"d\":\"20\",\"i\":null},{\"v\":\"21\",\"d\":\"21\",\"i\":null},{\"v\":\"22\",\"d\":\"22\",\"i\":null},{\"v\":\"23\",\"d\":\"23\",\"i\":null},{\"v\":\"24\",\"d\":\"24\",\"i\":null},{\"v\":\"25\",\"d\":\"25\",\"i\":null}]},{\"title_code\":\"ONB_PHOTO_FUSE_BOX_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_PHOTO_LOCATION_CP_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_PHOTO_PAVEMENT_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_PHOTO_SMART_METER_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_PHOTO_OTHER_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null},{\"title_code\":\"ONB_CUSTOMER_REMARKS_Q\",\"answer\":null,\"readonly\":false,\"refresh\":false,\"display\":true,\"mandatory\":false,\"regexp\":null}]"';
  l_error_messages constant t_max_varchar2 := '
    "error_messages": "[{\"name\":\"ANSWER_BUT_EMPTY_DOMAIN\",\"message_text\":\"Question \\\"<p1>\\\" has answer \\\"<p2>\\\" but no allowable values\"},{\"name\":\"ANSWER_DOES_NOT_MATCH_REGEXP\",\"message_text\":\"Question \\\"<p1>\\\" has an answer \\\"<p2>\\\" that does not match regular expression \\\"<p3>\\\"\"},{\"name\":\"ANSWER_MANDATORY\",\"message_text\":\"Question \\\"<p1>\\\" must have an answer\"},{\"name\":\"ANSWER_NOT_IN_DOMAIN\",\"message_text\":\"Question \\\"<p1>\\\" has an answer \\\"<p2>\\\" that is not part of the allowed values (<p3>)\"}]"';
begin
  /*
procedure split
( p_str in clob
, p_delimiter in varchar2 := ','
, p_str_tab out nocopy dbms_sql.varchar2a
);
*/
  dbms_lob.trim(g_clob_test, 0);
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob('{' || "lf"));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob(l_responses1));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob(l_responses2 || ',' || "lf"));
  dbms_lob.append(dest_lob => g_clob_test, src_lob => to_clob(l_error_messages || "lf" || '}'));

  begin
    split(g_clob_test, null, l_str_tab); -- just a chunked read must succeed
  exception
    when others
    then raise program_error; -- this is not the expected thrown exception
  end;

  -- this one should throw value_error
  split(g_clob_test, "lf", l_str_tab);
end;

$end -- $if oracle_tools.cfg_pkg.c_testing $then

begin
  dbms_lob.createtemporary(g_clob, true);
$if oracle_tools.cfg_pkg.c_testing $then
  dbms_lob.createtemporary(g_clob_test, true);
$end  
end pkg_str_util;
/

