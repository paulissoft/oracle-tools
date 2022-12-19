CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."PKG_STR_UTIL" IS

g_clob clob;

g_package_prefix constant varchar2(61) := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.';

$if oracle_tools.cfg_pkg.c_testing $then

"null" constant varchar2(1) := null;
"null clob" constant clob := null;
"lf" constant varchar2(1) := chr(10);
"cr" constant varchar2(1) := chr(13);
"crlf" constant varchar2(2) := "cr" || "lf";

$end

-- GLOBAL

function dbms_lob_substr
( p_clob in clob
, p_amount in naturaln
, p_offset in positiven
)
return varchar2
is
  l_offset positiven := p_offset;
  l_amount naturaln := p_amount; -- can become 0
  l_buffer varchar2(32767 char) := null;
  l_chunk varchar2(32767 char);
  l_chunk_length naturaln := 0; -- never null
  l_clob_length constant naturaln := nvl(dbms_lob.getlength(p_clob), 0);
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.enter(g_package_prefix || 'DBMS_LOB_SUBSTR');
  dbug.print(dbug."input", 'p_clob length: %s; p_amount: %s; p_offset: %s', l_clob_length, p_amount, p_offset);
$end

  -- read till this entry is full (during testing I got 32764 instead of 32767)
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

    l_buffer := l_buffer || l_chunk;

    -- nothing read: stop;
    -- buffer length at least p_amount: stop
    exit buffer_loop when l_chunk_length = 0 or length(l_buffer) >= p_amount;

    l_offset := l_offset + l_chunk_length;
    l_amount := l_amount - l_chunk_length;
  end loop buffer_loop;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.print(dbug."output", 'return length: %s', length(l_buffer));
  dbug.leave;
$end

  return l_buffer;
end dbms_lob_substr;

procedure split
( p_str in varchar2
, p_delimiter in varchar2 := ','
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
, p_delimiter in varchar2 := ','
, p_str_tab out nocopy dbms_sql.varchar2a
)
is
  l_pos pls_integer;
  l_start positiven := 1; -- never null
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

      p_str_tab(p_str_tab.count+1) :=
        dbms_lob_substr
        ( p_clob => p_str
        , p_offset => l_start
        , p_amount => case when l_pos > 0 then l_pos - l_start else 32767 end
        );
      l_start := l_start + nvl(length(p_str_tab(p_str_tab.count+0)), 0) + nvl(length(p_delimiter), 0);
    end loop;
    -- everything has been read BUT ...
    if l_pos > 0
    then
      -- the delimiter string is just at the end of p_str, so add another empty line so a join() can reconstruct exactly the same clob
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
  l_str varchar2(32767 char) := null;
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

  -- een dummy loop om er snel uit te springen en niet teveel if statements te hebben
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
         , dbms_lob_substr
           ( p_clob => p_str
           , p_offset => i_start
           , p_amount => 1
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
         , dbms_lob_substr
           ( p_clob => p_str
           , p_offset => i_end
           , p_amount => 1
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
        dbms_lob_substr(p_clob => p_str1_tab(l_line_idx), p_offset => l_char_idx, p_amount => 1) !=
        dbms_lob_substr(p_clob => p_str2_tab(l_line_idx), p_offset => l_char_idx, p_amount => 1)
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
  l_buffer varchar2(32767 char) := null;
  l_text varchar2(32767 char);
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
      while l_first <= l_last and dbms_lob_substr(p_clob => pi_clob, p_offset => l_first, p_amount => 1) in (chr(9), chr(10), chr(13), chr(32))
      loop
        l_first := l_first + 1;
      end loop;
      -- skip whitespace at the end
      while l_first <= l_last and dbms_lob_substr(p_clob => pi_clob, p_offset => l_last, p_amount => 1) in (chr(9), chr(10), chr(13), chr(32))
      loop
        l_last := l_last - 1;
      end loop;
    end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
    dbug.print(dbug."info", 'l_first: %s; l_last: %s', l_first, l_last);
$end

    if l_first <= l_last
    then
      for i_chunk in 1 .. ceil((l_last - l_first + 1) / 4000)
      loop
        l_text_tab.extend(1);
        l_text_tab(l_text_tab.last) :=
          dbms_lob_substr
          ( p_clob => pi_clob
          , p_offset => l_first + (i_chunk-1) * 4000
          , p_amount => case
                          when i_chunk < ceil((l_last - l_first + 1) / 4000)
                          then 4000
                          else (l_last - l_first + 1) - (i_chunk-1) * 4000
                        end
          );
      end loop;
    end if;
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_str_util.c_debugging >= 1 $then
  dbug.leave;
$end

  return l_text_tab;
end clob2text;

$if oracle_tools.cfg_pkg.c_testing $then

-- test functions

--%suitepath(DDL)
--%suite

--%test
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
  split("null", "null", l_str_tab);

  ut.expect(l_str_tab.count, 'test 1.1').to_equal(1);
  ut.expect(l_str_tab(1), 'test 1.2').to_be_null();

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

--%test
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
  dbms_lob.trim(g_clob, 0);

  split("null clob", null, l_str_tab);

  ut.expect(l_str_tab.count, 'test 1.1').to_equal(1);
  ut.expect(l_str_tab(1), 'test 1.2').to_be_null();

  split(g_clob, "lf", l_str_tab);

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

  dbms_lob.trim(g_clob, 0);
  dbms_lob.append(dest_lob => g_clob, src_lob => to_clob(rpad('a', 32767, 'a')));
  dbms_lob.append(dest_lob => g_clob, src_lob => to_clob("crlf"));
  dbms_lob.append(dest_lob => g_clob, src_lob => to_clob(rpad('b', 32767, 'b')));

  split(g_clob, "crlf", l_str_tab);

  ut.expect(dbms_lob.getlength(g_clob), 'test 6.0').to_equal(32767 * 2 + 2);
  ut.expect(l_str_tab.count, 'test 6.1').to_equal(2);
  ut.expect(l_str_tab(1), 'test 6.2').to_equal(rpad('a', 32767, 'a'));
  ut.expect(l_str_tab(2), 'test 6.3').to_equal(rpad('b', 32767, 'b'));

  dbms_lob.trim(g_clob, 0);
  dbms_lob.append(dest_lob => g_clob, src_lob => to_clob(rpad('a', 32767, 'a')));
  dbms_lob.append(dest_lob => g_clob, src_lob => to_clob(rpad('b', 32767, 'b')));

  split(g_clob, null, l_str_tab);

  ut.expect(dbms_lob.getlength(g_clob), 'test 7.0').to_equal(32767 * 2);
  ut.expect(l_str_tab.count, 'test 7.1').to_equal(2);
  ut.expect(l_str_tab(1), 'test 7.2').to_equal(rpad('a', 32767, 'a'));
  ut.expect(l_str_tab(2), 'test 7.3').to_equal(rpad('b', 32767, 'b'));
end;

--%test
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
  dbms_lob.trim(g_clob, 0);

  split("null clob", null, l_str_tab);

  ut.expect(l_str_tab.count, 'test 1.1').to_equal(1);
  ut.expect(dbms_lob.getlength(l_str_tab(1)), 'test 1.2').to_be_null();

  split(g_clob, "lf", l_str_tab);

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

  dbms_lob.trim(g_clob, 0);
  dbms_lob.append(dest_lob => g_clob, src_lob => to_clob(rpad('a', 32767, 'a')));
  dbms_lob.append(dest_lob => g_clob, src_lob => to_clob("crlf"));
  dbms_lob.append(dest_lob => g_clob, src_lob => to_clob(rpad('b', 32767, 'b')));

  split(g_clob, "crlf", l_str_tab);

  ut.expect(dbms_lob.getlength(g_clob), 'test 6.0').to_equal(32767 * 2 + 2);
  ut.expect(l_str_tab.count, 'test 6.1').to_equal(2);
  ut.expect(l_str_tab(1), 'test 6.2').to_equal(to_clob(rpad('a', 32767, 'a')));
  ut.expect(l_str_tab(2), 'test 6.3').to_equal(to_clob(rpad('b', 32767, 'b')));

  dbms_lob.trim(g_clob, 0);
  dbms_lob.append(dest_lob => g_clob, src_lob => to_clob(rpad('a', 32767, 'a')));
  dbms_lob.append(dest_lob => g_clob, src_lob => to_clob(rpad('b', 32767, 'b')));

  split(g_clob, null, l_str_tab);

  ut.expect(dbms_lob.getlength(g_clob), 'test 7.0').to_equal(32767 * 2);
  ut.expect(l_str_tab.count, 'test 7.1').to_equal(1);
  ut.expect(l_str_tab(1), 'test 7.2').to_equal(g_clob);
end;

--%test
procedure ut_trim1
is
begin
  raise program_error;
end;

--%test
procedure ut_trim2
is
begin
  raise program_error;
end;

--%test
procedure ut_compare1
is
begin
  raise program_error;
end;

--%test
procedure ut_compare2
is
begin
  raise program_error;
end;

--%test
procedure ut_append_text1
is
begin
  raise program_error;
end;

--%test
procedure ut_append_text2
is
begin
  raise program_error;
end;

--%test
procedure ut_text2clob1
is
begin
  raise program_error;
end;

--%test
procedure ut_text2clob2
is
begin
  raise program_error;
end;

--%test
procedure ut_clob2text
is
begin
  raise program_error;
end;

$end -- $if oracle_tools.cfg_pkg.c_testing $then

begin
  dbms_lob.createtemporary(g_clob, true);
end pkg_str_util;
/

