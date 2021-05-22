create or replace package body ext_load_file_pkg as

-- LOCAL

g_package_name constant varchar2(30 char) := upper('ext_load_file_pkg');
"ROW##NUMBER" constant varchar2(30 char) := 'ROW##NUMBER';
"SHEET##NAME" constant varchar2(30 char) := 'SHEET##NAME';

"<load_file_object_info>" constant varchar2(30 char) := '<load_file_object_info>';
"//load_file_object_info/" constant varchar2(30 char) := '//load_file_object_info/';

"<load_file_column_info>" constant varchar2(30 char) := '<load_file_column_info>';
"//load_file_column_info/" constant varchar2(30 char) := '//load_file_column_info/';

"text/csv" constant t_mime_type := 'text/csv';

-- Can have hundredths of a second from now on (%)
"LOAD_FILE_VIEW_EXPR" constant varchar2(100 char) := 'LOAD\_FILE\_______________%\_V';

-- forward declaration
function default_read_method
return pls_integer;

g_method constant pls_integer := default_read_method;

cursor c_load_file_object_info is
  select  vw.view_name
  from    user_views vw
          inner join user_tab_comments com
          on com.table_name = vw.view_name and
             instr(com.comments, "<load_file_object_info>") > 0
          inner join user_objects obj
          on obj.object_name = vw.view_name and
             obj.object_type = 'VIEW' and
             obj.status = 'VALID'
             /* GJP 2020-067-01 
                Every time the package is recompiled obj.last_ddl_time changes.
             */
             /* and
             obj.created = obj.last_ddl_time -- no one has changed the definition             
             */
  where   vw.view_name like "LOAD_FILE_VIEW_EXPR" escape '\';
    
$if cfg_pkg.c_testing $then

g_object_info_rec t_object_info_rec;
g_column_info_tab t_column_info_tab := t_column_info_tab();
g_view_name user_views.view_name%type := null;

$end

$if cfg_pkg.c_debugging $then
procedure print
( p_break_point in dbug.break_point_t
, p_object_info_rec in t_object_info_rec
)
is
begin
  dbug.print
  ( p_break_point
  , 'view_name: %s; file_name: %s; mime_type: %s; object_name: %s; sheet_names: %s'
  , p_object_info_rec.view_name
  , p_object_info_rec.file_name
  , p_object_info_rec.mime_type
  , p_object_info_rec.object_name
  , p_object_info_rec.sheet_names
  );
  dbug.print
  ( p_break_point
  , 'last_excel_column_name: %s; header_rows: %s; data_rows: %s: determine_datatype: %s; nls_charset_name: %s'
  , p_object_info_rec.last_excel_column_name
  , p_object_info_rec.header_row_from||'-'||p_object_info_rec.header_row_till
  , p_object_info_rec.data_row_from||'-'||p_object_info_rec.data_row_till
  , p_object_info_rec.determine_datatype
  , p_object_info_rec.nls_charset_name
  );
end print;
$end

-- Java may not be available or the Java library may not have been loaded
function default_read_method
return pls_integer
is
  l_value pls_integer;
begin
  return 
    case
      when ExcelTable.isReadMethodAvailable(ExcelTable.STREAM_READ)
      then ExcelTable.STREAM_READ
      else ExcelTable.DOM_READ
    end;
end default_read_method;

procedure get_column_info_tab
( p_apex_file_id in apex_application_temp_files.id%type
, p_column_info_tab out nocopy t_column_info_tab
)
is
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'GET_COLUMN_INFO_TAB';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print
  ( dbug."input"
  , 'p_apex_file_id: %s'
  , p_apex_file_id
  );
$end

  select  to_number(c.collection_name) as apex_file_id
  ,       c.seq_id
  ,       null as view_name
  ,       c.c001 as excel_column_name
  ,       c.c002 as header_row
  ,       c.c003 as data_row
  ,       c.c004 as data_type
  ,       c.c005 as format_mask
  ,       c.n001 as in_key
  ,       c.c006 as default_value
  bulk collect
  into    p_column_info_tab
  from    apex_collections c
  where   c.collection_name = to_char(p_apex_file_id)
  order by
          ext_load_file_pkg.excel_column_name2number(excel_column_name);

$if cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'p_column_info_tab.count: %s'
  , p_column_info_tab.count
  );
  dbug.leave;
$end
end get_column_info_tab;

function unquote
( p_name in varchar2
)
return varchar2
is
begin
  return case
           when p_name like '"%"'
           then substr(p_name, 2, length(p_name) - 2)
           else upper(p_name)
         end;
end unquote;

procedure get_key
( p_apex_file_id in apex_application_temp_files.id%type
, p_owner in varchar2
, p_table_name in varchar2
, p_key_columns out nocopy varchar2
, p_key out nocopy varchar2
)
is
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'GET_KEY';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print
  ( dbug."input"
  , 'p_apex_file_id: %s; p_owner: %s; p_table_name: %s'
  , p_apex_file_id
  , p_owner
  , p_table_name
  );
$end

  -- always returns 1 row
  select  listagg(t.table_column, ',') within group (order by t.table_column) as key_columns
  into    p_key_columns
  from    ( select  t.header_row as table_column
            from    table(ext_load_file_pkg.display(p_apex_file_id)) t
            where   t.in_key = 1
          ) t;

  begin
    select  t.constraint_name
    into    p_key
    from    ( select  col.constraint_name
              ,       listagg(col.column_name, ',') within group (order by col.column_name) as key_columns
              from    all_cons_columns col
                      inner join all_constraints con
                      on con.owner = col.owner and
                         con.table_name = col.table_name and
                         con.constraint_name = col.constraint_name and
                         con.constraint_type in ('P', 'U')
              where   col.owner = p_owner
              and     col.table_name = p_table_name
              group by
                      col.constraint_name
            ) t
    where   t.key_columns = p_key_columns;
  exception
    when no_data_found
    then
      p_key := null;
  end;

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_key_columns: %s; p_key: %s', p_key_columns, p_key);  
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end get_key;

procedure validate
( p_apex_file_id in apex_application_temp_files.id%type
, p_object_info_rec in t_object_info_rec
, p_action in varchar2
, p_key_columns out nocopy varchar2
, p_key out nocopy varchar2
)
is
  l_error_msg varchar2(2000 char) := null;
  l_owner all_objects.owner%type;
  l_object_name all_objects.object_name%type;
  l_column_info_tab t_column_info_tab;
  
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'VALIDATE';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print
  ( dbug."input"
  , 'p_apex_file_id: %s; p_action: %s'
  , p_apex_file_id
  , p_action
  );
  print(dbug."input", p_object_info_rec);
$end

  get_column_info_tab
  ( p_apex_file_id => p_apex_file_id
  , p_column_info_tab => l_column_info_tab
  );

  -- ERROR 1: duplicate table column names?
  for r in
  ( select  t.header_row
    ,       listagg(t.excel_column_name, ',') within group (order by t.excel_column_name) as duplicates  
    from    table(l_column_info_tab) t
    group by
            t.header_row
    having  count(*) > 1
    order by
            duplicates
  )
  loop
    l_error_msg :=
      case when l_error_msg is not null then l_error_msg || chr(10) end ||
      'File columns (' || r.duplicates || ') have the same table column (' || r.header_row || ')';
  end loop;

  if l_error_msg is not null
  then
    raise_application_error(-20000, l_error_msg);
  end if;

  -- ERROR 2: is the (fully qualified) object column set a superset of the file column set?
  parse_object_name(p_object_info_rec.object_name, l_owner, l_object_name);

  select  listagg(table_column, ',') within group (order by table_column) as table_columns
  into    l_error_msg
  from    ( select  t.header_row as table_column
            from    table(l_column_info_tab) t
            minus
            select  c.column_name
            from    all_tab_columns c
            where   c.owner = l_owner
            and     c.table_name = l_object_name
          );

  if l_error_msg is not null
  then
    raise_application_error(-20000, 'File table columns not in database table/view ' || p_object_info_rec.object_name || ': ' || l_error_msg);
  end if;

  get_key
  ( p_apex_file_id => p_apex_file_id
  , p_owner => l_owner
  , p_table_name => l_object_name
  , p_key_columns => p_key_columns
  , p_key => p_key
  );

  -- ERROR 3: for action U, M or D there must be a primary/unique key matching the key columns
  case
    when p_action in ('I', 'R')
    then
      null;
    
    when p_action in ('U', 'M', 'D')
    then
      if p_key is null
      then
        raise_application_error
        ( -20000
        , 'Action (' ||
          case p_action
            when 'U' then 'Update'
            when 'M' then 'Merge'
            when 'D' then 'Delete'
          end || ') needs a primary/unique key matching the key columns'
        );
      end if;
      
    else
      raise_application_error(-20000, 'Action (' || p_action || ') must be one of (I)insert, (R)eplace, (U)pdate, (M)erge or (D)elete.');  
  end case;

  if not(l_column_info_tab is null or l_column_info_tab.count = 0)
  then
    for i_idx in l_column_info_tab.first .. l_column_info_tab.last
    loop
      validate
      ( p_excel_column_name => l_column_info_tab(i_idx).excel_column_name
      , p_header_row => l_column_info_tab(i_idx).header_row
      , p_data_type => l_column_info_tab(i_idx).data_type
      , p_format_mask => l_column_info_tab(i_idx).format_mask
      , p_in_key => l_column_info_tab(i_idx).in_key
      , p_default_value => l_column_info_tab(i_idx).default_value
      );
    end loop;
  end if;

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_key_columns: %s; p_key: %s', p_key_columns, p_key);  
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end validate;

function get_xml_from_comment
( p_tag in varchar2
, p_comment in varchar2
)
return varchar2
is
  l_pos pls_integer;
begin
  l_pos := instr(p_comment, p_tag);
  return case when l_pos > 0 then substr(p_comment, l_pos) else null end;
end get_xml_from_comment;

procedure strip_xml_from_comment
( p_tag in varchar2
, p_comment in out nocopy varchar2
)
is
  l_pos pls_integer;
begin
  l_pos := instr(p_comment, p_tag);
  if l_pos > 0
  then
    p_comment := substr(p_comment, 1, l_pos - 1);
  end if;
end strip_xml_from_comment;

procedure convert_from_xml
( p_xml_fragment in XMLType
, p_var out nocopy varchar2
)
is
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'CONVERT_FROM_XML';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print
  ( dbug."input"
  , 'p_xml_fragment.getStringVal(): %s', case when p_xml_fragment is not null then p_xml_fragment.getStringVal() end
  );
$end

  if p_xml_fragment is not null
  then
    p_var := dbms_xmlgen.convert(p_xml_fragment.getStringVal(), dbms_xmlgen.ENTITY_DECODE);
  else
    p_var := null;
  end if;

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_var: %s', p_var);
  dbug.leave;
$end
end convert_from_xml;

procedure convert_from_xml
( p_xml_fragment in XMLType
, p_var out nocopy number
)
is
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'CONVERT_FROM_XML';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print
  ( dbug."input"
  , 'p_xml_fragment.getStringVal(): %s', case when p_xml_fragment is not null then p_xml_fragment.getStringVal() end
  );
$end

  if p_xml_fragment is not null
  then
    p_var := p_xml_fragment.getNumberVal();
  else
    p_var := null;
  end if;

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_var: %s', p_var);
  dbug.leave;
$end
end convert_from_xml;

procedure prepare_load
( p_object_name in varchar2
, p_column_info_tab in t_column_info_tab
, p_action in varchar2
, p_flat_file in boolean
, p_ctx out nocopy ExcelTable.DMLContext
)
is
  l_found pls_integer;
  l_owner all_objects.owner%type;
  l_object_name all_objects.object_name%type;
begin
  p_ctx := ExcelTable.createDMLContext(p_table_name => p_object_name);

  if not(p_column_info_tab is null or p_column_info_tab.count = 0)
  then
    parse_object_name(p_object_name, l_owner, l_object_name);

    -- does the column ROW##NUMBER exist? If so, use it for the cardinality
    begin
      select  1
      into    l_found
      from    all_tab_columns c
      where   c.owner = l_owner
      and     c.table_name = l_object_name
      and     c.column_name = "ROW##NUMBER";

      ExcelTable.mapColumn
      ( p_ctx => p_ctx
      , p_col_name => "ROW##NUMBER"
      , p_meta => ExcelTable.META_ORDINALITY
      );
    exception
      when no_data_found
      then
        null;
    end;

    if not(p_flat_file)
    then
      -- does the column SHEET##NAME exist? If so, use it for the sheet name
      begin
        select  1
        into    l_found
        from    all_tab_columns c
        where   c.owner = l_owner
        and     c.table_name = l_object_name
        and     c.column_name = "SHEET##NAME";

        ExcelTable.mapColumn
        ( p_ctx => p_ctx
        , p_col_name => "SHEET##NAME"
        , p_meta => ExcelTable.META_SHEET_NAME
        );
      exception
        when no_data_found
        then
          null;
      end;
    end if;
        
    for i_idx in p_column_info_tab.first .. p_column_info_tab.last
    loop
      ExcelTable.mapColumnWithDefault
      ( p_ctx => p_ctx
      , p_col_name => p_column_info_tab(i_idx).header_row -- ExcelFile does enquote it
      , p_col_ref => p_column_info_tab(i_idx).excel_column_name
      , p_format => p_column_info_tab(i_idx).format_mask
      , p_key => case when p_column_info_tab(i_idx).in_key = 1 then true else false end
      , p_default => p_column_info_tab(i_idx).default_value
      );
    end loop;
  end if;
  
  ExcelTable.useSheetPattern(true); -- may treat sheet name as a regular expression

  if p_action = 'R'
  then
    begin
      execute immediate 'truncate table ' || p_object_name;
    exception
      when others
      then
        execute immediate 'delete from ' || p_object_name;
    end;
  end if;
end prepare_load;

function get_owner
return all_objects.owner%type
is
begin
  return sys_context('userenv', 'current_schema');
end get_owner;

function create_table_statement
( p_column_info_tab in t_column_info_tab
, p_table_name in varchar2
, p_flat_file in boolean
)
return dbms_sql.varchar2a
is
  l_sql_text dbms_sql.varchar2a;
  l_key_columns varchar2(32767 char) := null;
  
  l_column_name varchar2(4000 char) := null;
  l_owner all_objects.owner%type;
  l_object_name all_objects.object_name%type;
  l_found pls_integer;

  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'CREATE_TABLE_STATEMENT';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print
  ( dbug."input"
  , 'p_column_info_tab.count: %s; p_table_name: %s; p_flat_file: %s'
  , case when p_column_info_tab is not null then p_column_info_tab.count end
  , p_table_name
  , dbug.cast_to_varchar2(p_flat_file)
  );
$end

  parse_object_name
  ( p_fq_object_name => p_table_name
  , p_owner => l_owner
  , p_object_name => l_object_name
  );
  
  select  count(*)
  into    l_found
  from    all_objects obj
  where   obj.owner = l_owner
  and     obj.object_name = l_object_name
  and     obj.object_type in ('TABLE', 'VIEW');

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'l_found: %s', l_found);
$end

  if l_found > 0
  then
    raise_application_error(-20000, 'Table ' || p_table_name || ' already exists.');
  else 
    if not(p_column_info_tab is null or p_column_info_tab.count = 0)
    then
      l_sql_text(l_sql_text.count + 1) := 'CREATE TABLE ' || p_table_name;
      l_sql_text(l_sql_text.count + 1) := '( ' || "ROW##NUMBER" || ' INTEGER NOT NULL';
      if not(p_flat_file)
      then
        l_sql_text(l_sql_text.count + 1) := ', ' || "SHEET##NAME" || ' VARCHAR2(100 CHAR) NOT NULL';
      end if;

      for i_idx in p_column_info_tab.first .. p_column_info_tab.last
      loop
        l_column_name := dbms_assert.enquote_name(p_column_info_tab(i_idx).header_row, false);
        l_sql_text(l_sql_text.count + 1) := ', ' || l_column_name || ' ' || p_column_info_tab(i_idx).data_type;
        
        if p_column_info_tab(i_idx).in_key = 1
        then
          l_key_columns := case when l_key_columns is not null then l_key_columns || ', ' end || l_column_name;
        end if;
      end loop;
      
      if l_key_columns is not null
      then
        l_sql_text(l_sql_text.count + 1) := ', PRIMARY KEY (' || l_key_columns || ')';
      end if;
      
      l_sql_text(l_sql_text.count + 1) := ')';
    end if;
  end if;

$if cfg_pkg.c_debugging $then
  for i_idx in 1 .. l_sql_text.count
  loop
    dbug.print(dbug."output", 'l_sql_text(%s): %s', i_idx, l_sql_text(i_idx));
  end loop;
  dbug.leave;
$end

  return l_sql_text;

$if cfg_pkg.c_debugging $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end create_table_statement;

procedure get_sheet_name_list
( p_sheet_names in varchar2
, p_sheet_name_list out nocopy ExcelTableSheetList
)
is
begin
  select substr(str, pos + 1, lead(pos, 1, 4000) over(order by pos) - pos - 1) part
  bulk collect
  into   p_sheet_name_list
  from   ( select  str
           ,       instr(str, ':', 1, level) pos
           from    ( select  p_sheet_names as str
                     from    dual
                     where   rownum <= 1
                   )
           connect by
                   level <= length(str) - nvl(length(replace(str, ':')), 0) /* number of colons */ + 1
         );
end get_sheet_name_list;

-- GLOBAL

function get_load_data_owner
return all_users.username%type
is
  l_username all_users.username%type;
begin
  select  o.owner
  into    l_username
  from    all_objects o
  where   o.object_name = 'EXCELTABLE'
  and     o.object_type = 'PACKAGE';

  return l_username;
end get_load_data_owner;

function excel_column_name2number
( p_excel_column_name in varchar2
)
return naturaln
deterministic
is
  l_ch varchar2(1 char);
  l_number naturaln := 0;
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'EXCEL_COLUMN_NAME2NUMBER';
begin
  if p_excel_column_name is not null
  then
    for i_idx in 1 .. length(p_excel_column_name)
    loop
      l_ch := substr(p_excel_column_name, -1 * i_idx, 1);
      if l_ch between 'A' and 'Z'
      then
        l_number := l_number + ( ascii(l_ch) - ascii('A') + 1 ) * power(26, i_idx - 1);
      else
        raise_application_error(-20000, 'Character (' || l_ch || ') should be between "A" and "Z"');
      end if;
    end loop;
  end if;

  return l_number;
end excel_column_name2number;

function number2excel_column_name
( p_number in naturaln
)
return varchar2
deterministic
is
  l_excel_column_name t_excel_column_name := null;
  l_rest naturaln := p_number;
  l_number naturaln := 0;
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'NUMBER2EXCEL_COLUMN_NAME';
begin
  while l_rest > 0
  loop
    l_number := mod(l_rest - 1, 26) + 1;
    l_rest := (l_rest - l_number) / 26;
    l_excel_column_name := chr(ascii('A') + l_number - 1) || l_excel_column_name;
  end loop;

  return l_excel_column_name;
end number2excel_column_name;

procedure set_load_file_info
( p_object_info_rec in t_object_info_rec
, p_column_info_tab in t_column_info_tab
, p_view_name out nocopy varchar2
)
is
  l_xml XMLType;
  l_sql_statement varchar2(32767 char) := null;
  l_key_constraint varchar2(32767 char) := null;

  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'SET_LOAD_FILE_INFO';

  procedure execute_statement
  ( p_sql_statement in varchar2
  )
  is
  begin
$if cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'p_sql_statement: %s', p_sql_statement);  
$end

    execute immediate p_sql_statement;
  end execute_statement;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  print(dbug."input", p_object_info_rec);
$end

  -- 2020-06-24  During unit testing this may cause collisions
  -- p_view_name := 'LOAD_FILE_' || to_char(sysdate, 'yyyymmddhh24miss') || '_V';
  -- Maximum 30 characters for Oracle 12.1 databases
  -- p_view_name := 'LOAD_FILE_' || to_char(localtimestamp, 'yyyymmddhh24missff') || '_V';
  p_view_name := 'LOAD_FILE_' || to_char(localtimestamp, 'yyyymmddhh24missff4') || '_V';

  -- We only create it, not replace
  l_sql_statement := 'CREATE VIEW ' || p_view_name;

  -- Use the Excel Column Names (A, B, etcetera) as view column name
  for i_idx in p_column_info_tab.first .. p_column_info_tab.last
  loop
$if cfg_pkg.c_debugging $then
    dbug.print
    ( dbug."info"
    , 'p_column_info_tab(%s); excel_column_name: %s; in_key: %s'
    , i_idx
    , p_column_info_tab(i_idx).excel_column_name
    , p_column_info_tab(i_idx).in_key
    );
$end

    l_sql_statement :=
      l_sql_statement ||
      case i_idx
        when p_column_info_tab.first then '('
        else ', '
      end ||
      '"' ||
      p_column_info_tab(i_idx).excel_column_name ||
      '"';

    if p_column_info_tab(i_idx).in_key = 1
    then
      l_key_constraint :=
        l_key_constraint ||
        case
          when l_key_constraint is null then ', PRIMARY KEY ('
          else ', '
        end ||
        '"' ||
        p_column_info_tab(i_idx).excel_column_name ||
        '"';
    end if;
    
$if cfg_pkg.c_debugging $then
    dbug.print
    ( dbug."info"
    , 'l_sql_statement: %s; l_key_constraint: %s'
    , l_sql_statement
    , l_key_constraint
    );
$end
  end loop;

  if l_key_constraint is not null
  then
    l_key_constraint := l_key_constraint || ') RELY DISABLE NOVALIDATE';
  end if;

  l_sql_statement := l_sql_statement || l_key_constraint || ') AS ' || chr(10);

  for i_idx in p_column_info_tab.first .. p_column_info_tab.last
  loop
    l_sql_statement :=
      l_sql_statement ||
      case
        when i_idx = p_column_info_tab.first
        then 'SELECT  '
        else ',       '
      end ||
      '"' ||
      p_column_info_tab(i_idx).header_row ||
      '"' ||
      chr(10);
  end loop;

  l_sql_statement := l_sql_statement || 'FROM    ' || p_object_info_rec.object_name;

  execute_statement(l_sql_statement);

  /*
   * Create the XML for the table/view.
   *
   * No need to store:
   * - view_name: since the view is part of the comment
   */
  select  xmlelement("load_file_object_info",
            xmlelement("file_name", p_object_info_rec.file_name),
            xmlelement("mime_type", p_object_info_rec.mime_type),
            xmlelement("object_name", p_object_info_rec.object_name),
            xmlelement("sheet_names", p_object_info_rec.sheet_names),
            xmlelement("last_excel_column_name", p_object_info_rec.last_excel_column_name),
            xmlelement("header_row_from", p_object_info_rec.header_row_from),
            xmlelement("header_row_till", p_object_info_rec.header_row_till),
            xmlelement("data_row_from", p_object_info_rec.data_row_from),
            xmlelement("data_row_till", p_object_info_rec.data_row_till),
            xmlelement("determine_datatype", p_object_info_rec.determine_datatype),
            xmlelement("nls_charset_name", p_object_info_rec.nls_charset_name)
          ) as load_file_object_info
  into    l_xml
  from    dual;

  -- ensure the comment gets created even though there is a quote in comment
  execute_statement('COMMENT ON TABLE ' || p_view_name || ' IS q''[' || l_xml.getStringVal() || ']''');

  /*
   * Create the XML for the table/view columns.
   *
   * No need to store:
   * - apex_file_id: temporary file id
   * - seq_id: derived from excel_column_name
   * - view_name: since the view is part of the comment
   * - excel_column_name: since the column is part of the comment
   * - data_row: depends on the temporary file
   *
   * Strictly speaking the in_key information is redundant since there is a view primary key.
   */
  for r in
  ( select  f.excel_column_name
    ,       xmlelement("load_file_column_info",
              xmlelement("header_row", f.header_row),
              xmlelement("data_type", f.data_type),
              xmlelement("format_mask", f.format_mask),
              xmlelement("in_key", f.in_key),
              xmlelement("default_value", f.default_value)
            ) as xml
    from    table(p_column_info_tab) f
  )
  loop
    -- ensure the comment gets created even though there is a quote in comment
    execute_statement
    ( 'COMMENT ON COLUMN ' ||
      p_view_name ||
      '."' ||
      r.excel_column_name ||
      '" IS q''[' ||
      r.xml.getStringVal() ||
      ']'''
    );
  end loop;

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_view_name: %s', p_view_name);
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end set_load_file_info;

procedure get_object_info
( p_view_name in varchar2
, p_object_info_rec out nocopy t_object_info_rec 
)
is
  l_view_name constant user_views.view_name%type := unquote(p_view_name);
  l_xml XMLType;  
  l_comment user_tab_comments.comments%type;

  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'GET_OBJECT_INFO';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print
  ( dbug."input"
  , 'p_view_name: %s'
  , p_view_name
  );
$end

  /*
   * Get the XML for the table/view.
   */
  begin
    select  com.comments
    into    l_comment
    from    user_tab_comments com
    where   com.table_name = l_view_name;

    l_comment := get_xml_from_comment("<load_file_object_info>", l_comment);
  exception
    when no_data_found
    then
      l_comment := null;
  end;

$if cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."info"
  , 'l_comment: %s'
  , l_comment
  );
$end

  p_object_info_rec.view_name := l_view_name;
  
  p_object_info_rec.file_name := null;  
  p_object_info_rec.mime_type := null;  
  p_object_info_rec.object_name := null;  
  p_object_info_rec.sheet_names := null;
  p_object_info_rec.last_excel_column_name := null;
  p_object_info_rec.header_row_from := null;
  p_object_info_rec.header_row_till := null;
  p_object_info_rec.data_row_from := null;
  p_object_info_rec.data_row_till := null;
  p_object_info_rec.determine_datatype := null;
  p_object_info_rec.nls_charset_name := null;

  if l_comment is not null
  then
    l_xml := XMLType.createXML(l_comment);

    convert_from_xml
    ( l_xml.extract("//load_file_object_info/" || 'file_name/text()')
    , p_object_info_rec.file_name
    );

    convert_from_xml
    ( l_xml.extract("//load_file_object_info/" || 'mime_type/text()')
    , p_object_info_rec.mime_type
    );

    convert_from_xml
    ( l_xml.extract("//load_file_object_info/" || 'object_name/text()')
    , p_object_info_rec.object_name
    );

    convert_from_xml
    ( l_xml.extract("//load_file_object_info/" || 'sheet_names/text()')
    , p_object_info_rec.sheet_names
    );

    convert_from_xml
    ( l_xml.extract("//load_file_object_info/" || 'last_excel_column_name/text()')
    , p_object_info_rec.last_excel_column_name
    );

    convert_from_xml
    ( l_xml.extract("//load_file_object_info/" || 'header_row_from/text()')
    , p_object_info_rec.header_row_from
    );
    
    convert_from_xml
    ( l_xml.extract("//load_file_object_info/" || 'header_row_till/text()')
    , p_object_info_rec.header_row_till
    );

    convert_from_xml
    ( l_xml.extract("//load_file_object_info/" || 'data_row_from/text()')
    , p_object_info_rec.data_row_from
    );

    convert_from_xml
    ( l_xml.extract("//load_file_object_info/" || 'data_row_till/text()')
    , p_object_info_rec.data_row_till
    );

    convert_from_xml
    ( l_xml.extract("//load_file_object_info/" || 'determine_datatype/text()')
    , p_object_info_rec.determine_datatype
    );
    
    convert_from_xml
    ( l_xml.extract("//load_file_object_info/" || 'nls_charset_name/text()')
    , p_object_info_rec.nls_charset_name
    );
  end if;

  if p_object_info_rec.last_excel_column_name is null
  then
    p_object_info_rec.last_excel_column_name := 'ZZ';
  end if;

  if p_object_info_rec.header_row_from is null
  then
    p_object_info_rec.header_row_from := 1;
  end if;

  if p_object_info_rec.header_row_till is null
  then
    p_object_info_rec.header_row_till := 1;
  end if;

  if p_object_info_rec.data_row_from is null
  then
    p_object_info_rec.data_row_from := 2;
  end if;

  if p_object_info_rec.determine_datatype is null
  then
    p_object_info_rec.determine_datatype := 1;
  end if;

  if p_object_info_rec.nls_charset_name is null
  then
    p_object_info_rec.nls_charset_name := csv_nls_charset_name;
  end if;

$if cfg_pkg.c_debugging $then
  print(dbug."output", p_object_info_rec);
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end get_object_info;

procedure get_column_info
( p_view_name in varchar2
, p_column_info_tab out nocopy t_column_info_tab
)
is
  l_view_name constant user_views.view_name%type := unquote(p_view_name);
  l_comment user_tab_comments.comments%type;
  l_xml XMLType;

  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'GET_COLUMN_INFO';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print
  ( dbug."input"
  , 'p_view_name: %s'
  , p_view_name
  );
$end

  /*
   * Get the XML for the table/view columns.
   * Only when there is XML the column has been used for the DML.
   */
  p_column_info_tab := t_column_info_tab();

  -- store the default value in column comments (or remove by setting it to null)
  for r in
  ( select  col.column_name
    ,       com.comments
    from    user_tab_columns col
            left outer join user_col_comments com
            on com.table_name = col.table_name and
               com.column_name = col.column_name and
               instr(com.comments, "<load_file_column_info>") > 0
    where   col.table_name = l_view_name
    order by
            col.column_id 
  )
  loop
    l_comment := get_xml_from_comment("<load_file_column_info>", r.comments);
    if l_comment is not null
    then
      p_column_info_tab.extend(1);
      p_column_info_tab(p_column_info_tab.last).apex_file_id := null;
      p_column_info_tab(p_column_info_tab.last).seq_id := null;
      p_column_info_tab(p_column_info_tab.last).view_name := l_view_name;
      p_column_info_tab(p_column_info_tab.last).excel_column_name := r.column_name;

      convert_from_xml
      ( XMLType.createXML(l_comment).extract("//load_file_column_info/" || 'header_row/text()')
      , p_column_info_tab(p_column_info_tab.last).header_row
      );

      p_column_info_tab(p_column_info_tab.last).data_row := null;

      convert_from_xml
      ( XMLType.createXML(l_comment).extract("//load_file_column_info/" || 'data_type/text()')
      , p_column_info_tab(p_column_info_tab.last).data_type
      );

      convert_from_xml
      ( XMLType.createXML(l_comment).extract("//load_file_column_info/" || 'format_mask/text()')
      , p_column_info_tab(p_column_info_tab.last).format_mask
      );
      
      convert_from_xml
      ( XMLType.createXML(l_comment).extract("//load_file_column_info/" || 'in_key/text()')
      , p_column_info_tab(p_column_info_tab.last).in_key
      );

      convert_from_xml
      ( XMLType.createXML(l_comment).extract("//load_file_column_info/" || 'default_value/text()')
      , p_column_info_tab(p_column_info_tab.last).default_value
      );
    end if;
  end loop;

$if cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'p_column_info_tab.count: %s'
  , p_column_info_tab.count
  );
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end get_column_info;

function display_object_info
return t_object_info_tab
pipelined
is
  l_object_info_rec t_object_info_rec;
begin
  for r in c_load_file_object_info
  loop
    get_object_info(r.view_name, l_object_info_rec);
    pipe row (l_object_info_rec);
  end loop;
  
  return; -- essential
end display_object_info;

function display_column_info
return t_column_info_tab
pipelined
is
  l_column_info_tab t_column_info_tab;
begin
  for r in c_load_file_object_info
  loop
    get_column_info(r.view_name, l_column_info_tab);
    if l_column_info_tab is not null and l_column_info_tab.count > 0
    then
      for i_idx in l_column_info_tab.first .. l_column_info_tab.last
      loop
        pipe row (l_column_info_tab(i_idx));
      end loop;
    end if;
  end loop;
  
  return; -- essential
end display_column_info;

function blob2clob
( p_blob in blob
, p_nls_charset_name in t_nls_charset_name
)
return clob
is
  l_clob clob;
  -- variables needed for blob-clob convertion
  l_dest_offset integer := 1;
  l_src_offset integer := 1;
  l_lang_context integer := dbms_lob.default_lang_ctx;
  l_warning integer := 0;
begin    
  dbms_lob.createtemporary(l_clob, true);
  dbms_lob.converttoclob(l_clob, p_blob, dbms_lob.lobmaxsize, l_dest_offset, l_src_offset, nls_charset_id(p_nls_charset_name), l_lang_context, l_warning);
  
  return l_clob;
end blob2clob;

function display
( p_apex_file_id in apex_application_temp_files.id%type
, p_sheet_names in varchar2
, p_last_excel_column_name in varchar2
, p_header_row_from in natural
, p_header_row_till in natural
, p_data_row_from in natural
, p_data_row_till in natural
, p_determine_datatype in t_boolean
, p_format_mask in varchar2
, p_view_name in varchar2
, p_nls_charset_name in t_nls_charset_name
)
return t_column_info_tab
pipelined
is
  l_blob blob;
  l_clob clob;
  l_mime_type t_mime_type;
  l_eol varchar2(2 char) := null;
  l_field_separator varchar2(1 char) := null;
  l_quote_char varchar2(1 char) := '"';
  l_column_info_tab t_column_info_tab;

  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'DISPLAY';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print
  ( dbug."input"
  , 'p_apex_file_id: %s; p_sheet_names: %s; p_last_excel_column_name: %s; p_header_rows: %s; p_data_rows: %s'
  , p_apex_file_id
  , p_sheet_names
  , p_last_excel_column_name
  , p_header_row_from||'-'||p_header_row_till
  , p_data_row_from||'-'||p_data_row_till
  );
  dbug.print
  ( dbug."input"
  , 'p_determine_datatype: %s; p_format_mask: %s; p_view_name: %s; p_nls_charset_name: %s'
  , p_determine_datatype
  , p_format_mask
  , p_view_name
  , p_nls_charset_name
  );
$end

  select  f.blob_content
  ,       f.mime_type
  into    l_blob
  ,       l_mime_type
  from    apex_application_temp_files f
  where   f.id = p_apex_file_id
  union all -- works with BLOBs
  select  f.blob_content
  ,       f.mime_type
  from    apex_application_files f
  where   f.id = p_apex_file_id;

  if l_mime_type = "text/csv"
  then
    l_clob := ext_load_file_pkg.blob2clob(l_blob, p_nls_charset_name);
    l_blob := null;

    determine_csv_info
    ( p_csv => l_clob
    , p_quote_char => l_quote_char
    , p_eol => l_eol
    , p_field_separator => l_field_separator
    );
  else
    l_clob := null;
  end if;

  get_column_info_tab
  ( p_apex_file_id => p_apex_file_id
  , p_last_excel_column_name => p_last_excel_column_name
  , p_header_row_from => p_header_row_from
  , p_header_row_till => p_header_row_till
  , p_data_row_from => p_data_row_from
  , p_data_row_till => p_data_row_till
  , p_determine_datatype => p_determine_datatype
  , p_format_mask => p_format_mask
  , p_view_name => p_view_name
    -- CSV parameters
  , p_clob => l_clob
  , p_eol => l_eol
  , p_field_separator => l_field_separator
  , p_quote_char => l_quote_char
    -- Spreadsheet parameters
  , p_blob => l_blob
  , p_sheet_names => p_sheet_names
  , p_column_info_tab => l_column_info_tab
  );

  if l_column_info_tab is not null and l_column_info_tab.count > 0
  then
    for i_idx in l_column_info_tab.first .. l_column_info_tab.last
    loop
      pipe row (l_column_info_tab(i_idx));
    end loop;
  end if;

  if l_clob is not null
  then
    dbms_lob.freetemporary(l_clob);
  end if;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end

  return; -- essential for a pipelined function
end display;

procedure determine_csv_info
( p_csv in clob
, p_field_separators in varchar2
, p_quote_char in varchar2
, p_eol out nocopy varchar2
, p_field_separator out nocopy varchar2
)
is
  l_field_separator_count_tab sys.odcinumberlist := sys.odcinumberlist();
  l_buffer varchar2(32767 char);
  l_char varchar(1 char);
  l_buffer_idx pls_integer;
  l_quoted boolean := false;
  l_first_char boolean := true;
  l_ready boolean := false;
  l_pos pls_integer;
  l_row pls_integer := 1;
  l_prev_row pls_integer := 1;
  l_max_idx pls_integer;

  type t_field_separator_used_tab is table of boolean index by l_char%type;
  
  l_field_separator_used_tab t_field_separator_used_tab;
  l_field_separator_used_new_tab t_field_separator_used_tab; 

  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'DETERMINE_CSV_INFO';

  procedure next_row
  is
  begin
$if cfg_pkg.c_debugging and cfg_pkg.c_testing $then
    dbug.enter(l_module_name || '.NEXT_ROW');
    dbug.print(dbug."input", 'l_field_separator_used_tab.count: %s', l_field_separator_used_tab.count);
$end
    if l_field_separator_used_tab.count > 1
    then
      l_ready := false;
      l_field_separator_used_tab := l_field_separator_used_new_tab;
    else
      l_ready := true;
      -- keep l_field_separator_used_tab
    end if;
$if cfg_pkg.c_debugging and cfg_pkg.c_testing $then    
    dbug.print(dbug."output", 'l_ready: %s', l_ready);
    dbug.leave;
$end
  end next_row;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print
  ( dbug."input"
  , 'p_csv length: %s; p_field_separators: %s; p_quote_char: %s'
  , dbms_lob.getlength(p_csv)
  , p_field_separators
  , p_quote_char
  );
$end
  -- some checks
  if p_csv is null
  then
    raise_application_error(-20000, 'The CSV should not be empty');    
  elsif p_field_separators is null
  then
    raise_application_error(-20000, 'The possible field separators should not be empty');    
  elsif p_quote_char is null or length(p_quote_char) != 1
  then
    raise_application_error(-20000, 'The quote character string should contain exactly one character');    
  end if;

  l_field_separator_count_tab.extend(length(p_field_separators));  
  l_buffer := dbms_lob.substr(lob_loc => p_csv, amount => 32767, offset => 1);
  l_buffer_idx := 1;
  
  while not(l_ready)
  loop
$if cfg_pkg.c_debugging and cfg_pkg.c_testing $then
    dbug.print
    ( dbug."info"
    , 'l_buffer length: %s; l_buffer_idx: %s'
    , length(l_buffer)
    , l_buffer_idx
    );
$end

    l_char := substr(l_buffer, l_buffer_idx, 1);
    l_prev_row := l_row;

$if cfg_pkg.c_debugging and cfg_pkg.c_testing $then
    dbug.print
    ( dbug."info"
    , 'l_char (hex): %s; l_buffer_idx: %s; l_row: %s; l_quoted: %s; l_first_char: %s'
    , rawtohex(utl_raw.cast_to_raw(l_char))
    , l_buffer_idx
    , l_row
    , dbug.cast_to_varchar2(l_quoted)
    , dbug.cast_to_varchar2(l_first_char)
    );
$end

    case 
      when l_char = p_quote_char
      then
        if l_quoted
        then
          if substr(l_buffer, l_buffer_idx + 1, 1) != p_quote_char -- peek
          then
            /* Value is quoted and current character is " and next character is not ". */
            l_quoted := false;
          else
            -- Value is quoted and current and 
            -- next characters are "" - read (skip) peeked qoute.
            l_buffer_idx := l_buffer_idx + 1; 
          end if;
        else
          if l_first_char
          then
            -- Set value as quoted only if this quote is the 
            -- first char in the value.
            l_quoted := true;
          end if;
        end if;
        l_first_char := false;

      when l_char in (chr(10), chr(13))
      then
        if not(l_quoted)
        then
          if l_row = 1
          then
            p_eol := l_char;
          end if;
          while substr(l_buffer, l_buffer_idx + 1, 1) in (chr(10), chr(13)) -- peek
          loop
            if l_row = 1
            then
              p_eol := p_eol || substr(l_buffer, l_buffer_idx + 1, 1);
            end if;
            l_buffer_idx := l_buffer_idx + 1;
          end loop;
          l_row := l_row + 1;
          l_first_char := true;
        else
          l_first_char := false;
        end if;

      when l_char is null -- no more data
      then
        l_ready := true;

      else
        if not(l_quoted)
        then
          l_pos := instr(p_field_separators, l_char);
          if l_pos > 0
          then
            l_field_separator_used_tab(l_char) := true;
            l_field_separator_count_tab(l_pos) := nvl(l_field_separator_count_tab(l_pos), 0) + 1;
            l_first_char := true;
          else
            l_first_char := false;
          end if;
        else
          l_first_char := false;
        end if;
    end case;

    if l_prev_row != l_row
    then
      next_row;  
    end if;
    
    l_buffer_idx := l_buffer_idx + 1;
  end loop;

  case l_field_separator_used_tab.count
    when 0
    then
      p_field_separator := null;

    when 1
    then
      p_field_separator := l_field_separator_used_tab.first;

    else
      -- take the candidate with the maximal count
      l_max_idx := null;
      if l_field_separator_count_tab.count >= 0
      then
        for i_idx in l_field_separator_count_tab.first .. l_field_separator_count_tab.last
        loop
          if l_max_idx is null or l_field_separator_count_tab(i_idx) > l_field_separator_count_tab(l_max_idx)
          then
            l_max_idx := i_idx;
          end if;
        end loop;
      end if;

$if cfg_pkg.c_debugging $then
      dbug.print
      ( dbug."info"
      , 'l_field_separator_count_tab(%s): %s; p_field_separator: %s'
      , l_max_idx
      , l_field_separator_count_tab(l_max_idx)
      , substr(p_field_separators, l_max_idx, 1)
      );
$end

      p_field_separator := substr(p_field_separators, l_max_idx, 1);
  end case;

$if cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'p_eol (hex): %s; p_field_separator (hex): %s'
  , rawtohex(utl_raw.cast_to_raw(p_eol))
  , rawtohex(utl_raw.cast_to_raw(p_field_separator))
  );
  dbug.leave;
$end
end determine_csv_info;

procedure get_column_info_tab
( -- common parameters
  p_apex_file_id in apex_application_temp_files.id%type
, p_last_excel_column_name in varchar2
, p_header_row_from in natural
, p_header_row_till in natural
, p_data_row_from in natural
, p_data_row_till in natural
, p_determine_datatype in t_boolean
, p_format_mask in varchar2
, p_view_name in varchar2
  -- CSV parameters
, p_clob in clob default null
, p_eol in varchar2 default null
, p_field_separator in varchar2 default null
, p_quote_char in varchar2 default null
  -- Spreadsheet parameters
, p_blob in blob default null
, p_sheet_names in varchar2 default null
, p_column_info_tab out nocopy t_column_info_tab
)
is
  type t_column_info_by_name_tab is table of t_column_info_rec index by t_excel_column_name;
  
  l_owner all_objects.owner%type := null;
  l_view_name all_views.view_name%type := null;
    
  l_md_column_info_tab t_column_info_tab := t_column_info_tab();

  l_column_info_by_name_tab t_column_info_by_name_tab;
  l_md_column_info_by_name_tab t_column_info_by_name_tab;

  l_column_info_rec t_column_info_rec;

  l_max_length pls_integer := null;
  l_header_row varchar2(4000 char) := null;
  l_header_row_regexp constant varchar2(4000 char) := '^(.+) \(\d+\)$';

  type t_header_row_count_tab is table of pls_integer index by l_header_row%type;
  
  l_header_row_count_tab t_header_row_count_tab;

  l_sheet_name_list ExcelTableSheetList;

  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'GET_COLUMN_INFO_TAB';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print
  ( dbug."input"
  , 'p_apex_file_id: %s; p_last_excel_column_name: %s; p_header_rows: %s; p_data_rows: %s; p_determine_datatype: %s'
  , p_apex_file_id
  , p_last_excel_column_name
  , p_header_row_from||'-'||p_header_row_till
  , p_data_row_from||'-'||p_data_row_till
  , p_determine_datatype
  );
  dbug.print
  ( dbug."input"
  , 'p_format_mask: %s; p_view_name: %s'
  , p_format_mask
  , p_view_name
  );
  dbug.print
  ( dbug."input"
  , 'p_clob not null: %s; p_eol (hex): %s; p_field_separator (hex): %s; p_quote_char (hex): %s'
  , dbug.cast_to_varchar2(p_clob is not null)
  , rawtohex(utl_raw.cast_to_raw(p_eol))
  , rawtohex(utl_raw.cast_to_raw(p_field_separator))
  , rawtohex(utl_raw.cast_to_raw(p_quote_char))
  );
  dbug.print
  ( dbug."input"
  , 'p_blob not null: %s; p_sheet_names: %s'
  , dbug.cast_to_varchar2(p_blob is not null)
  , p_sheet_names
  );
$end

  /*
  -- some sanity checks (not all yet)
  */
  if p_last_excel_column_name is null
  then
    raise_application_error(-20000, 'p_last_excel_column_name should not be empty');
  elsif p_header_row_from is null
  then
    raise_application_error(-20000, 'p_header_row_from should not be empty');
  elsif p_header_row_till is null
  then
    raise_application_error(-20000, 'p_header_row_till should not be empty');
  elsif p_header_row_from > p_header_row_till
  then
    raise_application_error
    ( -20000
    , utl_lms.format_message
      ( 'p_header_row_from (%s) should be at most p_header_row_till (%s)'
      , to_char(p_header_row_from)
      , to_char(p_header_row_till)
      )
    );
  elsif p_header_row_from = 0 and p_header_row_till > 0
  then
    raise_application_error
    ( -20000
    , utl_lms.format_message
      ( 'p_header_row_till (%s) should be 0 when p_header_row_till is 0 (%s)'
      , to_char(p_header_row_till)
      , to_char(p_header_row_from)
      )
    );
  elsif p_data_row_from is null
  then
    raise_application_error(-20000, 'p_data_row_from should not be empty');
  elsif p_header_row_till >= p_data_row_from
  then
    raise_application_error
    ( -20000
    , utl_lms.format_message
      ( 'p_header_row_till (%s) should be less than p_data_row_from (%s)'
      , to_char(p_header_row_till)
      , to_char(p_data_row_from)
      )
    );
  elsif p_data_row_till < p_data_row_from
  then
    raise_application_error
    ( -20000
    , utl_lms.format_message
      ( 'p_data_row_till (%s) should be at least p_data_row_from (%s)'
      , to_char(p_data_row_till)
      , to_char(p_data_row_from)
      )
    );
  elsif p_determine_datatype is null
  then
    raise_application_error(-20000, 'p_determine_datatype should not be empty');
  end if;

  /*
  -- some more sanity checks depending on p_clob / p_blob
  */
  
  if p_clob is not null
  then
    if p_eol is null
    then
      raise_application_error(-20000, 'p_eol should not be empty'); 
    elsif p_field_separator is null
    then
      raise_application_error(-20000, 'p_field_separator should not be empty');
    elsif p_quote_char is null
    then
      raise_application_error(-20000, 'p_quote_char should not be empty');
    end if;
  else
    if p_blob is null
    then
      raise_application_error(-20000, 'p_blob should not be empty');
    elsif p_sheet_names is null
    then
      raise_application_error(-20000, 'p_sheet_names should not be empty');
    end if;
  end if;

  if p_view_name is not null -- history
  then
    parse_object_name
    ( p_fq_object_name => p_view_name
    , p_owner => l_owner
    , p_object_name => l_view_name
    );
    get_column_info
    ( p_view_name => l_view_name
    , p_column_info_tab => l_md_column_info_tab
    );
    if l_md_column_info_tab.count > 0
    then
      for i_idx in l_md_column_info_tab.first .. l_md_column_info_tab.last
      loop
        l_md_column_info_by_name_tab(l_md_column_info_tab(i_idx).excel_column_name) := l_md_column_info_tab(i_idx);
      end loop;
    end if;
  end if;

  /*
  -- Now the real stuff begins...
  */
  ExcelTable.useSheetPattern(true); -- may treat sheet name as a regular expression

  /*
   * GJP 2020-06-09
   * 
   * I) Sometimes an Excel file may start like:
   *
   *   A          B   C       D           E             F                     G           H           I             J                     K
   * 1                                       2012/2013                                                   2013/2014     
   * 2 Matricule  NOM Prenom  Bonus cible Bonus realise Prime complementaire  Bonus total Bonus cible Bonus realise Prime complementaire  Bonus total
   *
   * Then the first two rows will be header rows (separate them by a |). Please note that A1 does not exist, but E1 does.
   * 
   * We have to adjust the initialization for such a case.
   *
   * II) Sometimes an Excel row may not have all data columns.
   *
   * In the example above where p_header_row_from = 0 and p_header_row_till too, there is no header.
   * So it does not suffice to just read one line. 
   * We will need to read all lines which may impact performance: better safe than sorry.
   *
   * III) We may scan several sheets.
   * This means that the header can be skipped for the second sheet and so on.
   * The same for the first data row value.
   */

  get_sheet_name_list(p_sheet_names, l_sheet_name_list);

  for r in 
  ( with excel as
    ( select  t.*
      ,       ext_load_file_pkg.excel_column_name2number(t.cellCol) as column_nr
      ,       substr(t.cellData.getTypeName(), 5) as data_type
      ,       case t.cellData.getTypeName()
                when 'SYS.VARCHAR2'  then t.cellData.accessVarchar2() 
                when 'SYS.NUMBER'    then to_char(t.cellData.accessNumber())
                when 'SYS.TIMESTAMP' then to_char(t.cellData.accessTimestamp())
             end as data_value
      ,       case
                when t.cellRow between p_header_row_from and p_header_row_till
                then t.cellRow - p_header_row_from + 1
              end as header_row_idx
      ,       case
                when t.cellRow >= p_data_row_from
                then t.cellRow - p_data_row_from + 1
              end as data_row_idx
      from    ( select  excel.*
                from    table
                        ( ExcelTable.getRawCells
                          ( p_file        => p_blob
                          , p_sheetFilter => anydata.ConvertCollection(l_sheet_name_list)
                          , p_cols        => 'A-' || p_last_excel_column_name
                          , p_method      => g_method
                          )
                        ) excel
                where   p_clob is null
                union all
                select  csv.*
                from    table
                        ( xutl_flatfile.get_fields_delimited
                          ( p_content => p_clob
                          , p_cols => 'A-' || p_last_excel_column_name
                          , p_line_term => p_eol
                          , p_field_sep => p_field_separator
                          , p_text_qual => p_quote_char
                          )
                        ) csv
                where   p_clob is not null
              ) t
      where   ( /* header row? */
                t.cellRow between p_header_row_from and p_header_row_till or
                /* data row? */
                ( t.cellRow >= p_data_row_from and
                  ( p_data_row_till is null or t.cellRow <= p_data_row_till ) )
              )
    )          
    select  e.sheetIdx
    ,       e.cellCol as excel_column_name
    ,       nvl
            ( case 
                when e.header_row_idx is not null
                then e.data_value
              end
              -- 2020-04-29  Use column names like Column1, Column2, ..., ColumnN
              -- r.cellCol
            , 'Column' || e.column_nr
            ) as header_row
    ,       e.header_row_idx
    ,       e.data_row_idx
    ,       e.data_value
    ,       case
              when e.header_row_idx is not null -- do not take into account the data_type of the header
              then null
              else e.data_type
            end as data_type
            -- See note II, data_row_idx 1 may be missing for a column so we need another way to determine the first data row
            -- See note III, we may scan several sheets
    ,       row_number() over (partition by e.column_nr order by e.sheetIdx asc, e.data_row_idx asc nulls last) as first_data_row
    ,       rank() over (order by e.sheetIdx asc) as sheet_index -- 1, 2, etcetera
    from    excel e
    order by
            e.sheetIdx
    ,       e.column_nr asc -- derived from excel column name
    ,       e.header_row_idx asc nulls last -- ascending header
    ,       e.data_row_idx desc -- so we go from last to first to calculate the maximum length
  )
  loop
$if cfg_pkg.c_debugging and cfg_pkg.c_testing $then
    dbug.print
    ( dbug."info"
    , 'r.sheet_index: %s; r.excel_column_name: %s; r.header_row: %s; r.header_row_idx: %s; r.data_row_idx: %s'
    , r.sheet_index
    , r.excel_column_name
    , r.header_row
    , r.header_row_idx
    , r.data_row_idx
    );
    dbug.print
    ( dbug."info"
    , 'r.data_value: %s; r.data_type: %s; r.first_data_row: %s; column exists?: %s; metadata column exists?: %s'
    , r.data_value
    , r.data_type
    , r.first_data_row
    , dbug.cast_to_varchar2(l_column_info_by_name_tab.exists(r.excel_column_name))
    , dbug.cast_to_varchar2(l_md_column_info_by_name_tab.exists(r.excel_column_name))
    );
$end

    if not(l_column_info_by_name_tab.exists(r.excel_column_name))
    then
      -- metadata exists?
      if l_md_column_info_by_name_tab.exists(r.excel_column_name)
      then
        l_column_info_rec := l_md_column_info_by_name_tab(r.excel_column_name);
      else
        l_column_info_rec.seq_id := null;
        l_column_info_rec.excel_column_name := r.excel_column_name;
        l_column_info_rec.header_row := r.header_row;
        l_column_info_rec.data_row := null;
        l_column_info_rec.data_type :=  r.data_type;
        l_column_info_rec.format_mask := null;
        l_column_info_rec.in_key := 0;
        l_column_info_rec.default_value := null;
      end if;
      l_column_info_rec.apex_file_id := p_apex_file_id;
      l_column_info_rec.view_name := null; -- the new view name is not known yet
      l_column_info_by_name_tab(r.excel_column_name) := l_column_info_rec;
      l_max_length := 0;
    elsif not(l_md_column_info_by_name_tab.exists(r.excel_column_name)) and
          r.sheet_index = 1 and
          r.header_row_idx > 1
    then
      /* See note I above */
      l_column_info_by_name_tab(r.excel_column_name).header_row := 
        l_column_info_by_name_tab(r.excel_column_name).header_row || '|' || r.header_row;
    end if;

    if r.header_row_idx is null
    then
      -- A non header row.
      --
      -- May modify:
      -- 1) l_column_info_by_name_tab(r.excel_column_name).data_row
      -- 2) l_column_info_by_name_tab(r.excel_column_name).data_type (no metadata)
      -- 3) l_column_info_by_name_tab(r.excel_column_name).format_mask (no metadata)

      if r.first_data_row = 1 and r.data_row_idx = 1
      then
        -- first data row
        l_column_info_by_name_tab(r.excel_column_name).data_row := r.data_value;
      elsif r.first_data_row = 1 and r.data_row_idx > 1
      then
        -- for other columns the first data row was on another line so
        -- l_column_info_by_name_tab(r.excel_column_name).data_row stays null
        null;
      end if;

      -- no metadata
      if not(l_md_column_info_by_name_tab.exists(r.excel_column_name))
      then
        if p_determine_datatype != 0
        then
          l_max_length := greatest(l_max_length, nvl(length(r.data_value), 0));

          if l_column_info_by_name_tab(r.excel_column_name).data_type is null
          then
            l_column_info_by_name_tab(r.excel_column_name).data_type := r.data_type; -- might stay null
          elsif l_column_info_by_name_tab(r.excel_column_name).data_type != r.data_type
          then
            l_column_info_by_name_tab(r.excel_column_name).data_type := 'VARCHAR2'; -- can always convert to VARCHAR2 and back
          end if;
        end if;
        
        if r.first_data_row = 1
        then
          -- first data row
          if l_column_info_by_name_tab(r.excel_column_name).data_type = 'VARCHAR2'
          then
            l_column_info_by_name_tab(r.excel_column_name).data_type :=
              l_column_info_by_name_tab(r.excel_column_name).data_type ||
              '(' ||
              case
                when l_max_length = 0
                then 4000 -- imagine all data rows have nulls
                else l_max_length
              end ||
              ' CHAR)';
          elsif l_column_info_by_name_tab(r.excel_column_name).data_type in ('DATE', 'TIMESTAMP') and
                l_column_info_by_name_tab(r.excel_column_name).format_mask is null
          then
            l_column_info_by_name_tab(r.excel_column_name).format_mask := p_format_mask;
          end if;
        end if;
      end if;
    end if;
  end loop;

  p_column_info_tab := t_column_info_tab();
  l_column_info_rec.excel_column_name := l_column_info_by_name_tab.first;
  while l_column_info_rec.excel_column_name is not null
  loop
    p_column_info_tab.extend(1);
    p_column_info_tab(p_column_info_tab.last) := l_column_info_by_name_tab(l_column_info_rec.excel_column_name);    
    l_column_info_rec.excel_column_name := l_column_info_by_name_tab.next(l_column_info_rec.excel_column_name);
  end loop;

  if not(p_column_info_tab is null or p_column_info_tab.count = 0)
  then
    for i_idx in p_column_info_tab.first .. p_column_info_tab.last
    loop
      -- GJP 2020-04-30  Add the count thus far to the header_row: <header_row> (<count>)
      -- Only when p_header_row_from = 1 since the header_row is unique for p_header_row_from = 0
      if p_header_row_from >= 1
      then
        if not(l_header_row_count_tab.exists(p_column_info_tab(i_idx).header_row))
        then
          l_header_row_count_tab(p_column_info_tab(i_idx).header_row) := 1;
        else
          l_header_row_count_tab(p_column_info_tab(i_idx).header_row) := 
            l_header_row_count_tab(p_column_info_tab(i_idx).header_row) + 1;
        end if;

        p_column_info_tab(i_idx).header_row :=
          p_column_info_tab(i_idx).header_row ||
          ' ' ||
          '(' ||
          to_char(l_header_row_count_tab(p_column_info_tab(i_idx).header_row)) ||
          ')';
          
$if cfg_pkg.c_debugging $then
        dbug.print
        ( dbug."info"
        , 'p_column_info_tab(%s).header_row: %s'
        , i_idx
        , p_column_info_tab(i_idx).header_row
        );
$end
      end if;
    end loop;

    for i_idx in p_column_info_tab.first .. p_column_info_tab.last
    loop
      -- p_determine_datatype = 0 or maybe there was no data row
      if p_column_info_tab(i_idx).data_type is null or
         p_column_info_tab(i_idx).data_type = 'VARCHAR2'
      then
        p_column_info_tab(i_idx).data_type := 'VARCHAR2(4000 CHAR)';
      end if;

      -- GJP 2020-04-30  Add the count thus far to the header_row: <header_row> (<count>)
      -- Only when p_header_row_from >= 1 since the header_row is unique for p_header_row_from = 0.
      -- Should we remove the (<count>) from the header_row name? Only when total count is 1.
      if p_header_row_from >= 1
      then
        l_header_row :=
          regexp_replace
          ( p_column_info_tab(i_idx).header_row
          , l_header_row_regexp
          , '\1'
          , 1 -- position
          , 1 -- occurrence
          , 'n' -- match_param, 'n' allows the period (.), which is the match-any-character character, to match the newline character.
          );
$if cfg_pkg.c_debugging $then
        dbug.print
        ( dbug."info"
        , 'p_column_info_tab(%s).header_row: %s; l_header_row: %s'
        , i_idx
        , p_column_info_tab(i_idx).header_row
        , l_header_row
        );
$end
        if l_header_row_count_tab(l_header_row) = 1
        then
          p_column_info_tab(i_idx).header_row := l_header_row; -- strip it since there was just one such a header_row
        end if;
      end if;

      if p_column_info_tab(i_idx).data_type not in ('DATE', 'TIMESTAMP') and
         p_column_info_tab(i_idx).format_mask is not null
      then
        p_column_info_tab(i_idx).format_mask := null;
      end if;
    end loop;
  end if;

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end get_column_info_tab;

procedure init
( p_apex_file_id in apex_application_temp_files.id%type
, p_sheet_names in varchar2
, p_last_excel_column_name in varchar2
, p_header_row_from in natural
, p_header_row_till in natural
, p_data_row_from in natural
, p_data_row_till in natural
, p_determine_datatype in t_boolean
, p_format_mask in varchar2
, p_view_name in varchar2
, p_nls_charset_name in t_nls_charset_name
)
is
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'INIT';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
$end

$if ext_load_file_pkg.create_collection_from_query $then

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'delete collection if it exists');
$end

  if apex_collection.collection_exists(to_char(p_apex_file_id))
  then
    apex_collection.delete_collection(to_char(p_apex_file_id));
  end if;

  apex_collection.create_collection_from_queryb2
  ( p_collection_name => to_char(p_apex_file_id)
    /* first 5 must be numeric fields (n001 - n005)
       next 5 must be date fields (d001 - d005)
       the rest character fields (c001 until c050)
    */ 
  , p_query => '
select  t.in_key as n001
,       to_number(null) as n002
,       to_number(null) as n003
,       to_number(null) as n004
,       to_number(null) as n005
,       to_date(null) as d001
,       to_date(null) as d002
,       to_date(null) as d003
,       to_date(null) as d004
,       to_date(null) as d005
,       t.excel_column_name as c001
,       t.header_row as c002
,       t.data_row as c003
,       t.data_type as c004
,       t.format_mask as c005
,       t.default_value as c006
from    table
        ( ext_load_file_pkg.display
          ( p_apex_file_id => ' || p_apex_file_id || '
          , p_sheet_names => q''[' || p_sheet_names || ']''
          , p_last_excel_column_name => q''[' || p_last_excel_column_name || ']''
          , p_header_row_from => ' || p_header_row_from || '
          , p_header_row_till => ' || p_header_row_till || '
          , p_data_row_from => ' || p_data_row_from || '
          , p_data_row_till => ' || p_data_row_till || '
          , p_determine_datatype => ' || p_determine_datatype || '
          , p_format_mask => q''[' || p_format_mask || ']''
          , p_view_name => q''[' || p_view_name || ']''
          , p_nls_charset_name => q''[' || p_nls_charset_name || ']''
          )
        ) t'
  );

$else

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'create or truncate collection');
$end

  apex_collection.create_or_truncate_collection(to_char(p_apex_file_id));

  for r in
  ( select  t.*
    from    table
            ( ext_load_file_pkg.display
              ( p_apex_file_id => p_apex_file_id
              , p_sheet_names => p_sheet_names
              , p_last_excel_column_name => p_last_excel_column_name
              , p_header_row_from => p_header_row_from
              , p_header_row_till => p_header_row_till
              , p_data_row_from => p_data_row_from
              , p_data_row_till => p_data_row_till
              , p_determine_datatype => p_determine_datatype
              , p_format_mask => p_format_mask
              , p_view_name => p_view_name
              , p_nls_charset_name => p_nls_charset_name
              )
            ) t
  )
  loop
    dml
    ( p_action => 'I'
    , p_apex_file_id => r.apex_file_id
    , p_seq_id => r.seq_id
    , p_excel_column_name => r.excel_column_name
    , p_header_row => r.header_row
    , p_data_row => r.data_row
    , p_data_type => r.data_type
    , p_format_mask => r.format_mask
    , p_in_key => r.in_key
    , p_default_value => r.default_value
    );
  end loop;

$end

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end init;

function display
( p_apex_file_id in apex_application_temp_files.id%type
)
return t_column_info_tab
pipelined
is
  l_column_info_tab t_column_info_tab;
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'DISPLAY';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print(dbug."input", 'p_apex_file_id: %s', p_apex_file_id);
$end

  get_column_info_tab(p_apex_file_id, l_column_info_tab);
  
  if not(l_column_info_tab is null or l_column_info_tab.count = 0)
  then
    for i_idx in l_column_info_tab.first .. l_column_info_tab.last
    loop
      pipe row (l_column_info_tab(i_idx));
    end loop;
  end if;
    
$if cfg_pkg.c_debugging $then
  dbug.leave;
$end

  return; -- essential for a pipelined function

$if cfg_pkg.c_debugging $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end display;

function create_table_statement
( p_apex_file_id in apex_application_temp_files.id%type
, p_table_name in varchar2
)
return dbms_sql.varchar2a
is
  l_column_info_tab t_column_info_tab;
  l_mime_type t_mime_type;
begin
  get_column_info_tab(p_apex_file_id, l_column_info_tab);

  select  f.mime_type
  into    l_mime_type
  from    apex_application_temp_files f
  where   f.id = p_apex_file_id
  union all -- works with BLOBs
  select  f.mime_type
  from    apex_application_files f
  where   f.id = p_apex_file_id;

  return create_table_statement
         ( p_column_info_tab => l_column_info_tab
         , p_table_name => p_table_name
         , p_flat_file => case when l_mime_type = "text/csv" then true else false end
         );
end create_table_statement;

procedure validate
( p_excel_column_name in varchar2
, p_header_row in varchar2
, p_data_type in varchar2
, p_format_mask in varchar2
, p_in_key in varchar2
, p_default_value in varchar2
)
is
  l_statement varchar2(4000 char) := null;  
  
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'VALIDATE';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print
  ( dbug."input"
  , 'p_excel_column_name: %s; p_header_row: %s; p_data_type: %s; p_format_mask: %s; p_in_key: %s; '
  , p_excel_column_name
  , p_header_row
  , p_data_type
  , p_format_mask
  , p_in_key
  );
  dbug.print
  ( dbug."input"
  , 'p_default_value: %s'
  , p_default_value
  );
$end

  if p_excel_column_name is null
  then
    raise_application_error(-20000, 'EXCEL COLUMN NAME should not be empty');
  elsif p_header_row is null
  then
    raise_application_error(-20000, 'HEADER ROW should not be empty');
  elsif p_data_type is null
  then
    raise_application_error(-20000, 'DATA TYPE should not be empty');
  elsif p_in_key is null
  then
    raise_application_error(-20000, 'IN KEY should not be empty');
  end if;

  if number2excel_column_name(excel_column_name2number(p_excel_column_name)) = p_excel_column_name
  then
    null;
  else
    raise_application_error
    ( -20000
    , utl_lms.format_message
      ( 'Can not convert EXCEL COLUMN NAME (%s) to a number (%s) and vice versa (%s)'
      , p_excel_column_name
      , to_char(excel_column_name2number(p_excel_column_name))
      , number2excel_column_name(excel_column_name2number(p_excel_column_name))
      )
    );    
  end if;

  if p_format_mask is null or
     upper(p_data_type) = 'DATE' or
     upper(p_data_type) like 'TIMESTAMP%'
  then
    null;
  else
    raise_application_error
    ( -20000
    , utl_lms.format_message
      ( 'When a FORMAT MASK (%s) is specified, the DATA TYPE (%s) must be DATE or TIMESTAMP'
      , p_format_mask
      , p_data_type
      )
    );    
  end if;
  
  if p_in_key in ('0', 'N', 'F', '1', 'Y', 'T')
  then
    null;
  else
    raise_application_error
    ( -20000
    , utl_lms.format_message('IN KEY (%s) should be false (0, N, F) or true (1, Y, T)', p_in_key)
    );
  end if;

  l_statement :=
    utl_lms.format_message
    ( q'{
declare
  "%s" %s := q'[%s]';
  "%s" varchar2(4000 char) := to_char("%s"%s);
begin
  null;
end;}'
    , p_header_row
    , p_data_type
    , p_default_value
    , p_excel_column_name
    , p_header_row
    , case when p_format_mask is not null then q'[, ']' || p_format_mask || q'[']' end
    );

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'l_statement: %s', l_statement);
$end

  execute immediate l_statement;

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end validate;

procedure validate
( p_apex_file_id in apex_application_temp_files.id%type
, p_object_info_rec in t_object_info_rec
, p_action in varchar2
)
is
  l_key_columns varchar2(4000 char);
  l_key all_constraints.constraint_name%type;
begin
  validate
  ( p_apex_file_id => p_apex_file_id
  , p_object_info_rec => p_object_info_rec
  , p_action => p_action
  , p_key_columns => l_key_columns
  , p_key => l_key
  );
end validate;

procedure validate
( p_apex_file_id in apex_application_temp_files.id%type
, p_sheet_names in varchar2
, p_last_excel_column_name in varchar2
, p_header_row_from in natural
, p_header_row_till in natural
, p_data_row_from in natural
, p_data_row_till in natural
, p_determine_datatype in t_boolean
, p_object_name in varchar2
, p_action in varchar2
, p_nls_charset_name in t_nls_charset_name
)
is
  l_object_info_rec t_object_info_rec; 
begin
  l_object_info_rec.sheet_names := p_sheet_names;
  l_object_info_rec.last_excel_column_name := p_last_excel_column_name;
  l_object_info_rec.header_row_from := p_header_row_from;
  l_object_info_rec.header_row_till := p_header_row_till;
  l_object_info_rec.data_row_from := p_data_row_from;
  l_object_info_rec.data_row_till := p_data_row_till;
  l_object_info_rec.determine_datatype := p_determine_datatype;
  l_object_info_rec.object_name := p_object_name;
  l_object_info_rec.nls_charset_name := p_nls_charset_name;

  validate
  ( p_apex_file_id => p_apex_file_id
  , p_object_info_rec => l_object_info_rec
  , p_action => p_action
  );
end validate;

function load_excel
( p_object_name in varchar2
, p_column_info_tab in t_column_info_tab
, p_action in varchar2
, p_blob in blob
, p_sheet_names in varchar2
, p_header_row_from in natural
, p_header_row_till in natural
, p_data_row_from in natural
, p_data_row_till in natural
)
return integer
is
  l_ctx ExcelTable.DMLContext;
  l_nr_rows integer := null;

  l_sheet_name_list ExcelTableSheetList;
 
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'LOAD_EXCEL';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
$end

  prepare_load
  ( p_object_name => p_object_name
  , p_column_info_tab => p_column_info_tab
  , p_action => p_action
  , p_flat_file => false
  , p_ctx => l_ctx
  );

  get_sheet_name_list(p_sheet_names, l_sheet_name_list);

  l_nr_rows :=
    ExcelTable.loadData
    ( p_ctx => l_ctx
    , p_file => p_blob
    , p_sheets => l_sheet_name_list
    , p_range => case
                   when p_data_row_till is not null
                   then -- Range of rows: in this case the range of columns implicitly starts at A.
                        to_char(p_data_row_from) || ':' || to_char(p_data_row_till)
                   else -- Single cell anchor (top-left cell)
                        'A' || to_char(p_data_row_from)
                 end
    , p_dml_type => case p_action
                      when 'I' then ExcelTable.DML_INSERT
                      when 'R' then ExcelTable.DML_INSERT
                      when 'U' then ExcelTable.DML_UPDATE
                      when 'M' then ExcelTable.DML_MERGE
                      when 'D' then ExcelTable.DML_DELETE
                    end
    , p_method => g_method                
    );

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'return: %s', l_nr_rows);  
  dbug.leave;
$end

  return l_nr_rows;

$if cfg_pkg.c_debugging $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end load_excel;

function load_csv
( p_object_name in varchar2
, p_column_info_tab in t_column_info_tab
, p_action in varchar2
, p_clob in clob
, p_eol in varchar2
, p_field_separator in varchar2
, p_quote_char in varchar2
, p_header_row_from in natural
, p_header_row_till in natural
, p_data_row_from in natural
, p_data_row_till in natural
, p_nls_charset_name in t_nls_charset_name
)
return integer
is
  l_ctx ExcelTable.DMLContext;
  l_nr_rows integer := null;
 
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'LOAD_CSV';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
$end

  -- ExcelTable does not support an end for CSV files
  if p_data_row_till is not null
  then
    raise_application_error(-20000, 'p_data_row_till should be empty');
  end if;

  prepare_load
  ( p_object_name => p_object_name
  , p_column_info_tab => p_column_info_tab
  , p_action => p_action
  , p_flat_file => true
  , p_ctx => l_ctx
  );  

  l_nr_rows :=
    ExcelTable.loadData
    ( p_ctx => l_ctx
    , p_file => p_clob
    , p_skip => p_data_row_from - 1
    , p_line_term => p_eol
    , p_field_sep => p_field_separator
    , p_text_qual => p_quote_char
    , p_dml_type => case p_action
                      when 'I' then ExcelTable.DML_INSERT
                      when 'R' then ExcelTable.DML_INSERT
                      when 'U' then ExcelTable.DML_UPDATE
                      when 'M' then ExcelTable.DML_MERGE
                      when 'D' then ExcelTable.DML_DELETE
                    end
    );

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'return: %s', l_nr_rows);  
  dbug.leave;
$end

  return l_nr_rows;

$if cfg_pkg.c_debugging $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end load_csv;

function load
( p_apex_file_id in apex_application_temp_files.id%type
, p_sheet_names in varchar2
, p_last_excel_column_name in varchar2
, p_header_row_from in natural
, p_header_row_till in natural
, p_data_row_from in natural
, p_data_row_till in natural
, p_determine_datatype in t_boolean
, p_object_name in varchar2
, p_action in varchar2
, p_nls_charset_name in t_nls_charset_name
)
return integer
is
  l_nr_rows integer := null;
  l_column_info_tab t_column_info_tab;
  l_object_info_rec t_object_info_rec; 
  l_view_name user_views.view_name%type;

  l_clob clob := null;
  l_eol varchar2(2 char) := null;
  l_field_separator varchar2(1 char) := null;
  l_quote_char varchar2(1 char) := '"';

  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'LOAD';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
$end

  l_object_info_rec.sheet_names := p_sheet_names;
  l_object_info_rec.last_excel_column_name := p_last_excel_column_name;
  l_object_info_rec.header_row_from := p_header_row_from;
  l_object_info_rec.header_row_till := p_header_row_till;
  l_object_info_rec.data_row_from := p_data_row_from;
  l_object_info_rec.data_row_till := p_data_row_till;
  l_object_info_rec.determine_datatype := p_determine_datatype;
  l_object_info_rec.object_name := p_object_name;
  l_object_info_rec.nls_charset_name := p_nls_charset_name;

  validate
  ( p_apex_file_id => p_apex_file_id
  , p_object_info_rec => l_object_info_rec
  , p_action => p_action
  );

  get_column_info_tab(p_apex_file_id, l_column_info_tab);

  -- a for loop because I am too lazy to fetch this one record
  for r in
  ( -- union all works with BLOBs
    select  f.blob_content
    ,       f.filename
    ,       f.mime_type
    from    apex_application_temp_files f
    where   f.id = p_apex_file_id
    union all
    select  f.blob_content
    ,       f.filename
    ,       f.mime_type
    from    apex_application_files f
    where   f.id = p_apex_file_id
  )
  loop
    l_object_info_rec.file_name := r.filename;
    l_object_info_rec.mime_type := r.mime_type;
    
    if r.mime_type != "text/csv"
    then
      l_nr_rows :=
        load_excel
        ( p_object_name => p_object_name
        , p_column_info_tab => l_column_info_tab
        , p_action => p_action
        , p_blob => r.blob_content
        , p_sheet_names => p_sheet_names
        , p_header_row_from => p_header_row_from
        , p_header_row_till => p_header_row_till
        , p_data_row_from => p_data_row_from
        , p_data_row_till => p_data_row_till
        );
    else
      l_clob := blob2clob(r.blob_content, p_nls_charset_name);
      determine_csv_info
      ( p_csv => l_clob
      , p_quote_char => l_quote_char
      , p_eol => l_eol
      , p_field_separator => l_field_separator
      );
      l_nr_rows :=
        load_csv
        ( p_object_name => p_object_name
        , p_column_info_tab => l_column_info_tab
        , p_action => p_action
        , p_clob => l_clob
        , p_eol => l_eol
        , p_field_separator => l_field_separator
        , p_quote_char => l_quote_char
        , p_header_row_from => p_header_row_from
        , p_header_row_till => p_header_row_till
        , p_data_row_from => p_data_row_from
        , p_data_row_till => p_data_row_till
        , p_nls_charset_name => p_nls_charset_name
        );
    end if;
  end loop;

  if l_clob is not null
  then
    dbms_lob.freetemporary(l_clob);
  end if;

  set_load_file_info
  ( p_object_info_rec => l_object_info_rec
  , p_column_info_tab => l_column_info_tab
  , p_view_name => l_view_name
  );

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'return: %s', l_nr_rows);  
  dbug.leave;
$end

  return l_nr_rows;

$if cfg_pkg.c_debugging $then
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end load;

procedure load
( p_apex_file in varchar2
, p_owner in varchar2
, p_object_info_rec in out nocopy t_object_info_rec
, p_apex_file_id out nocopy apex_application_temp_files.id%type
, p_apex_file_name out nocopy apex_application_temp_files.filename%type
, p_csv_file out nocopy natural
, p_action out nocopy varchar2
, p_new_table out nocopy natural
, p_nr_rows out nocopy natural
)
is
  l_cursor integer := null; 

  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'LOAD';

  procedure ddl(p_sql_text in dbms_sql.varchar2a)
  is
  begin
$if cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'p_sql_text.count: %s', p_sql_text.count);
$end    
    
    if p_sql_text.count = 0
    then
      return;
    end if;
      
    dbms_sql.parse
    ( c => l_cursor
    , statement => p_sql_text
    , lb => p_sql_text.first
    , ub => p_sql_text.last
    , lfflg => true
    , language_flag => dbms_sql.native
    );
  end ddl;
  
  procedure ddl(p_statement in varchar2)
  is
  begin
$if cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'p_statement: %s', p_statement);
$end    
    
    dbms_sql.parse
    ( c => l_cursor
     , statement => p_statement
     , language_flag => dbms_sql.native
    );
  end ddl;
  
  procedure cleanup
  is
  begin
    if l_cursor is not null
    then
      dbms_sql.close_cursor(l_cursor);
    end if;
  end cleanup;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print(dbug."input", 'p_apex_file: %s; p_owner: %s', p_apex_file, p_owner);
  print(dbug."input", p_object_info_rec);
$end

  select  f.mime_type
  ,       f.id
  ,       f.filename
  into    p_object_info_rec.mime_type
  ,       p_apex_file_id
  ,       p_apex_file_name
  from    apex_application_temp_files f
  where   f.name = p_apex_file;

  p_csv_file := case when p_object_info_rec.mime_type = "text/csv" then 1 else 0 end;
  
  for r in
  ( select  t.column_value
    from    apex_application_temp_files f
    ,       table(ext_load_file_pkg.get_sheets(f.blob_content)) t
    where   f.name = p_apex_file
    and     f.mime_type != 'text/csv'
  )
  loop
    p_object_info_rec.sheet_names :=
      case
        when p_object_info_rec.sheet_names is not null
        then p_object_info_rec.sheet_names || ':'
      end ||
      r.column_value;
      
    exit; -- only one sheet  
  end loop;

  init
  ( p_apex_file_id => p_apex_file_id
  , p_sheet_names => p_object_info_rec.sheet_names
  , p_last_excel_column_name => p_object_info_rec.last_excel_column_name
  , p_header_row_from => p_object_info_rec.header_row_from
  , p_header_row_till => p_object_info_rec.header_row_till
  , p_data_row_from => p_object_info_rec.data_row_from
  , p_data_row_till => p_object_info_rec.data_row_till
  , p_determine_datatype => p_object_info_rec.determine_datatype
  , p_view_name => p_object_info_rec.view_name
  );

  p_object_info_rec.object_name :=
    case
      when p_csv_file = 1
      then p_apex_file_name
      else p_object_info_rec.sheet_names
    end;

  begin
    select  0
    into    p_new_table
    from    all_objects obj
    where   obj.object_type in ('TABLE', 'VIEW')
    and     obj.owner = p_owner
    and     obj.object_name = p_object_info_rec.object_name;
  exception
    when no_data_found
    then
      p_new_table := 1;
  end;

  p_object_info_rec.object_name :=
    dbms_assert.enquote_name(p_owner, false) ||
    '.' ||
    dbms_assert.enquote_name(p_object_info_rec.object_name, false);

  if p_new_table != 0
  then
    p_action := 'I'; -- insert
    
    -- no validations before creating a table
    l_cursor := dbms_sql.open_cursor;

    ddl
    ( ext_load_file_pkg.create_table_statement
      ( p_apex_file_id => p_apex_file_id
      , p_table_name => p_object_info_rec.object_name
      )
    );
    
    if dbms_assert.enquote_name(p_owner, false)
       != dbms_assert.enquote_name(ext_load_file_pkg.get_load_data_owner, false)
    then
      ddl
      ( 'grant select,insert,update,delete on ' ||
        p_object_info_rec.object_name ||
        ' to ' ||
        dbms_assert.enquote_name(ext_load_file_pkg.get_load_data_owner, false)
      );        
    end if;
  else  
    p_action := 'R'; -- replace
  end if;
  
  -- validate is called in here anyhow
  p_nr_rows := 
    ext_load_file_pkg.load
    ( p_apex_file_id => p_apex_file_id
    , p_sheet_names => p_object_info_rec.sheet_names
    , p_last_excel_column_name => p_object_info_rec.last_excel_column_name
    , p_header_row_from => p_object_info_rec.header_row_from
    , p_header_row_till => p_object_info_rec.header_row_till
    , p_data_row_from => p_object_info_rec.data_row_from
    , p_data_row_till => p_object_info_rec.data_row_till
    , p_determine_datatype => p_object_info_rec.determine_datatype
    , p_object_name => p_object_info_rec.object_name
    , p_action => p_action
    );
    
  cleanup;

$if cfg_pkg.c_debugging $then
  print(dbug."output", p_object_info_rec);
  dbug.print
  ( dbug."output"
  , 'p_apex_file_name: %s; p_csv_file: %s; p_action: %s; p_new_table: %s; p_nr_rows: %s'
  , p_apex_file_name
  , p_csv_file
  , p_action
  , p_new_table
  , p_nr_rows
  );  
  dbug.leave;
$end

exception
  when others
  then
$if cfg_pkg.c_debugging $then
    dbug.leave_on_error;
$end
    cleanup;
    raise;
end load;

procedure done
( p_apex_file_id in apex_application_temp_files.id%type
)
is
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'DONE';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print(dbug."input", 'p_apex_file_id: %s', p_apex_file_id);
$end

  apex_collection.delete_collection(to_char(p_apex_file_id));

$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end done;

procedure dml
( p_action in varchar2
, p_view_name in user_views.view_name%type -- key
, p_file_name in varchar2
, p_mime_type in t_mime_type
, p_object_name in all_objects.object_name%type
, p_sheet_names in varchar2
, p_last_excel_column_name in t_excel_column_name
, p_header_row_from in natural
, p_header_row_till in natural
, p_data_row_from in natural
, p_data_row_till in natural
, p_determine_datatype in t_boolean
)
is
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'DML';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print
  ( dbug."input"
  , 'p_action: %s; p_view_name: %s'
  , p_action
  , p_view_name
  );
$end

  -- currently only delete is allowed
  case p_action
    when 'D'
    then
      execute immediate 'drop view ' || p_view_name;
  end case;
  
$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end dml;

procedure dml
( p_action in varchar2
, p_apex_file_id in apex_application_temp_files.id%type -- key part 1
, p_seq_id in out apex_collections.seq_id%type -- key part 2
, p_excel_column_name in varchar2
, p_header_row in varchar2
, p_data_row in varchar2
, p_data_type in varchar2
, p_format_mask in varchar2
, p_in_key in integer
, p_default_value in varchar2
)
is
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'DML';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print
  ( dbug."input"
  , 'p_action: %s; p_apex_file_id: %s; p_seq_id: %s; p_excel_column_name: %s; p_header_row: %s'
  , p_action
  , p_apex_file_id
  , p_seq_id
  , p_excel_column_name
  , p_header_row
  );
  dbug.print
  ( dbug."input"
  , 'p_data_row: %s; p_data_type: %s; p_format_mask: %s; p_in_key: %s; p_default_value: %s'
  , p_data_row
  , p_data_type
  , p_format_mask
  , p_in_key
  , p_default_value
  );
$end

  case p_action
    when 'I'
    then
      p_seq_id :=
        apex_collection.add_member
        ( p_collection_name => to_char(p_apex_file_id)
        , p_c001 => p_excel_column_name
        , p_c002 => p_header_row
        , p_c003 => p_data_row
        , p_c004 => p_data_type
        , p_c005 => p_format_mask
        , p_n001 => p_in_key
        , p_c006 => p_default_value
        );

    when 'U'
    then
      apex_collection.update_member
      ( p_collection_name => to_char(p_apex_file_id)
      , p_seq => p_seq_id
      , p_c001 => p_excel_column_name
      , p_c002 => p_header_row
      , p_c003 => p_data_row
      , p_c004 => p_data_type
      , p_c005 => p_format_mask
      , p_n001 => p_in_key
      , p_c006 => p_default_value
      );
    
    when 'D'
    then
      apex_collection.delete_member
      ( p_collection_name => to_char(p_apex_file_id)
      , p_seq => p_seq_id
      );
    
  end case;

$if cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_seq_id: %s', p_seq_id);  
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end dml;

function get_sheets
( p_excel in blob
)
return sys.odcivarchar2list
pipelined
is
begin
  for r in
  ( select  t.column_value as sheet_names
    from    table(ExcelTable.getSheets(p_file => p_excel, p_method => g_method)) t
  )
  loop
    pipe row (r.sheet_names);
  end loop;
  
  return; -- essential for a pipe lined function
end get_sheets;

procedure parse_object_name
( p_fq_object_name in varchar2
, p_owner out nocopy varchar2
, p_object_name out nocopy varchar2
)
is
  l_point constant pls_integer := instr(p_fq_object_name, '.');
  
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'PARSE_OBJECT_NAME';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print(dbug."input", 'p_fq_object_name: %s', p_fq_object_name);
$end

  if l_point = 0
  then
    p_owner := get_owner;
    p_object_name := p_fq_object_name;
  else
    p_owner := substr(p_fq_object_name, 1, l_point - 1);
    p_object_name := substr(p_fq_object_name, l_point + 1);
  end if;

  p_owner := unquote(p_owner);
  p_object_name := unquote(p_object_name);

$if cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'p_owner: %s; p_object_name: %s'
  , p_owner
  , p_object_name
  );
  dbug.leave;
$end
end parse_object_name;

$if cfg_pkg.c_testing $then

procedure ut_setup
is
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'UT_SETUP';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
$end

  execute immediate 'CREATE TABLE "myobject"("Column1" VARCHAR2(5 CHAR), "Column2" NUMBER)';

  if get_load_data_owner != get_owner
  then
    execute immediate 'GRANT INSERT ON "myobject" TO ' || get_load_data_owner;
  end if;  

  g_object_info_rec.view_name := 'xyz';
  g_object_info_rec.file_name := 'abc';
  g_object_info_rec.mime_type := "text/csv";
  g_object_info_rec.object_name := '"myobject"';
  g_object_info_rec.sheet_names := 'mysheet';
  g_object_info_rec.last_excel_column_name := 'AA';
  g_object_info_rec.header_row_from := 0;
  g_object_info_rec.header_row_till := 0;
  g_object_info_rec.data_row_from := 2;
  g_object_info_rec.data_row_till := null;
  g_object_info_rec.determine_datatype := 0;

  g_column_info_tab.extend(1);

  g_column_info_tab(g_column_info_tab.last).apex_file_id := null;
  g_column_info_tab(g_column_info_tab.last).seq_id := null;
  g_column_info_tab(g_column_info_tab.last).view_name := null;
  g_column_info_tab(g_column_info_tab.last).excel_column_name := 'A';
  g_column_info_tab(g_column_info_tab.last).header_row := 'Column1';
  g_column_info_tab(g_column_info_tab.last).data_row := 'hello';
  g_column_info_tab(g_column_info_tab.last).data_type := 'VARCHAR2(5 CHAR)';
  g_column_info_tab(g_column_info_tab.last).format_mask := null;
  g_column_info_tab(g_column_info_tab.last).in_key := 1;
  g_column_info_tab(g_column_info_tab.last).default_value := null;
  
  g_column_info_tab.extend(1);

  g_column_info_tab(g_column_info_tab.last) := g_column_info_tab(g_column_info_tab.last-1);
  g_column_info_tab(g_column_info_tab.last).excel_column_name := 'B';
  g_column_info_tab(g_column_info_tab.last).header_row := 'Column2';
  g_column_info_tab(g_column_info_tab.last).data_row := '1';
  g_column_info_tab(g_column_info_tab.last).data_type := 'NUMBER';
  g_column_info_tab(g_column_info_tab.last).in_key := 0;
  g_column_info_tab(g_column_info_tab.last).default_value := '0';

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
end ut_setup;

procedure ut_teardown
is
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'UT_TEARDOWN';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
$end

  execute immediate 'drop table "myobject" purge';
  if g_view_name is not null
  then
    execute immediate 'drop view ' || g_view_name;
  end if;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
end ut_teardown;

procedure ut_excel_column_name2number
is
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'UT_EXCEL_COLUMN_NAME2NUMBER';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
$end

  ut.expect(excel_column_name2number(null                 )).to_equal(                      0);
  
  ut.expect(excel_column_name2number(min_excel_column_name)).to_equal(min_excel_column_number);
  ut.expect(excel_column_name2number(                  'B')).to_equal(                      2);
  ut.expect(excel_column_name2number(                  'Z')).to_equal(                     26);

  ut.expect(excel_column_name2number(                 'AA')).to_equal(                     27);
  ut.expect(excel_column_name2number(                 'AB')).to_equal(                     28);
  ut.expect(excel_column_name2number(                 'AZ')).to_equal(                     52);
  
  ut.expect(excel_column_name2number(                 'BA')).to_equal(                     53);
  ut.expect(excel_column_name2number(                 'BB')).to_equal(                     54);
  ut.expect(excel_column_name2number(                 'BZ')).to_equal(                     78);
  
  ut.expect(excel_column_name2number(                 'ZA')).to_equal(                    677);
  ut.expect(excel_column_name2number(                 'ZB')).to_equal(                    678);
  ut.expect(excel_column_name2number(                 'ZZ')).to_equal(                    702);

  ut.expect(excel_column_name2number(                'AAA')).to_equal(                    703);
  ut.expect(excel_column_name2number(max_excel_column_name)).to_equal(max_excel_column_number);

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
end ut_excel_column_name2number;

procedure ut_number2excel_column_name
is
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'UT_NUMBER2EXCEL_COLUMN_NAME';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
$end

  ut.expect(number2excel_column_name(0)).to_be_null();

  for i_idx in min_excel_column_number .. max_excel_column_number
  loop
    ut.expect(excel_column_name2number(number2excel_column_name(i_idx))).to_equal(i_idx);
  end loop;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
end ut_number2excel_column_name;

procedure ut_load_file_info
is
  l_object_info_rec t_object_info_rec;
  l_column_info_tab t_column_info_tab;
  l_prefix varchar2(100 char);
  
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'UT_LOAD_FILE_INFO';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
$end

  set_load_file_info
  ( p_object_info_rec => g_object_info_rec
  , p_column_info_tab => g_column_info_tab
  , p_view_name => g_view_name
  );

  ut.expect(g_view_name, 'load file view expression').to_be_like("LOAD_FILE_VIEW_EXPR", '\');

  get_object_info
  ( p_view_name => g_view_name
  , p_object_info_rec => l_object_info_rec
  );

  ut.expect(l_object_info_rec.view_name, 'object view_name').to_equal(g_view_name);
  ut.expect(l_object_info_rec.file_name, 'object file_name').to_equal(g_object_info_rec.file_name);
  ut.expect(l_object_info_rec.mime_type, 'object mime_type').to_equal(g_object_info_rec.mime_type);
  ut.expect(l_object_info_rec.object_name, 'object object_name').to_equal(g_object_info_rec.object_name);
  ut.expect(l_object_info_rec.sheet_names, 'object sheet_names').to_equal(g_object_info_rec.sheet_names);
  ut.expect(l_object_info_rec.last_excel_column_name, 'object last_excel_column_name').to_equal(g_object_info_rec.last_excel_column_name);
  ut.expect(l_object_info_rec.header_row_from, 'object header_row_from').to_equal(g_object_info_rec.header_row_from);
  ut.expect(l_object_info_rec.header_row_till, 'object header_row_till').to_equal(g_object_info_rec.header_row_till);
  ut.expect(l_object_info_rec.data_row_from, 'object data_row_from').to_equal(g_object_info_rec.data_row_from);
  ut.expect(l_object_info_rec.data_row_till, 'object data_row_till').to_be_null();
  ut.expect(l_object_info_rec.determine_datatype, 'object determine_datatype').to_equal(g_object_info_rec.determine_datatype);

  get_column_info
  ( p_view_name => g_view_name
  , p_column_info_tab => l_column_info_tab
  );

  ut.expect(l_column_info_tab.count).to_equal(g_column_info_tab.count);

  for i_idx in l_column_info_tab.first .. l_column_info_tab.last
  loop
    l_prefix := 'column ' || i_idx || ' ';
    ut.expect(l_column_info_tab(i_idx).apex_file_id, l_prefix || 'apex_file_id').to_be_null();
    ut.expect(l_column_info_tab(i_idx).seq_id, l_prefix || 'seq_id').to_be_null();
    ut.expect(l_column_info_tab(i_idx).view_name, l_prefix || 'view_name').to_equal(g_view_name);
    ut.expect(l_column_info_tab(i_idx).excel_column_name, l_prefix || 'excel_column_name').to_equal(g_column_info_tab(i_idx).excel_column_name);
    ut.expect(l_column_info_tab(i_idx).header_row, l_prefix || 'header_row').to_equal(g_column_info_tab(i_idx).header_row);
    ut.expect(l_column_info_tab(i_idx).data_row, l_prefix || 'data_row').to_be_null();
    ut.expect(l_column_info_tab(i_idx).data_type, l_prefix || 'data_type').to_equal(g_column_info_tab(i_idx).data_type);
    ut.expect(l_column_info_tab(i_idx).format_mask, l_prefix || 'format_mask').to_be_null();
    ut.expect(l_column_info_tab(i_idx).in_key, l_prefix || 'in_key').to_equal(g_column_info_tab(i_idx).in_key);
    ut.expect(l_column_info_tab(i_idx).default_value, l_prefix || 'default_value').to_equal(g_column_info_tab(i_idx).default_value);
  end loop;  

$if cfg_pkg.c_debugging $then
  dbug.leave; 
$end
end ut_load_file_info;

procedure ut_load_csv
is
  l_nr_rows integer;
  l_column1_tab sys.odcivarchar2list;
  l_column2_tab sys.odcinumberlist;
  l_prefix varchar2(100 char);
  l_cursor sys_refcursor;
 
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'UT_LOAD_CSV';
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
$end

  l_nr_rows := 
    load_csv
    ( p_object_name => get_owner || '."myobject"'
    , p_column_info_tab => g_column_info_tab
    , p_action => 'I'
    , p_clob => 'Column1;Column2
2020;2020
abcde;1
;
fghij;2
klmno;3
pqrst;4'
    , p_eol => chr(10)
    , p_field_separator => ';'
    , p_quote_char => '"'
    , p_header_row_from => 1
    , p_header_row_till => 2
    , p_data_row_from => 5 -- skip 2 header rows and first two rows thereafter
    , p_data_row_till => null
    , p_nls_charset_name => 'UTF8'
    );

  ut.expect(l_nr_rows).to_equal(3);

  open l_cursor for 'select * from "myobject" order by 1';
  fetch l_cursor bulk collect into l_column1_tab, l_column2_tab;
  close l_cursor;

  for i_idx in 1 .. l_nr_rows
  loop
    l_prefix := 'row ' || i_idx || ' ';
    ut.expect(l_column1_tab(i_idx), l_prefix || 'A').to_equal(case i_idx when 1 then 'fghij' when 2 then 'klmno' when 3 then 'pqrst' end);
    ut.expect(l_column2_tab(i_idx), l_prefix || 'B').to_equal(i_idx + 1);
  end loop;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end
end ut_load_csv;

procedure ut_get_column_info_tab
is
  l_csv constant clob := q'[account,date,description,position (EUR),running_total (EUR)
-------,----,-----------,--------------,-------------------
Expenses:Bank:CreditAgricole:Checking:Compte1:Fine,2019-03-20,STMTTRN - COM INTERVENTION - XCEBR400 2019031900029511000001 2 OPERATIONS,16.0,16.0
Expenses:Bank:CreditAgricole:Checking:Compte2:Fine,2019-05-17,STMTTRN - FRAIS ENVOI CHEQUIER - XCCCD050 2019051600009931000001 PLI SIMPLE 0000226,1.2,17.2
Expenses:Bank:CreditAgricole:Checking:Compte1:Fine,2019-05-21,STMTTRN - COM INTERVENTION - XCEBR400 2019051800033869000001 9 OPERATIONS,72.0,89.2
Expenses:Bank:CreditAgricole:Checking:Compte1:Fine,2019-06-20,STMTTRN - COM INTERVENTION - XCEBR400 2019061900028386000001 15 OPERATIONS,80.0,169.2
Expenses:Bank:CreditAgricole:Checking:Compte2:Fine,2019-07-04,"STMTTRN - ARRETE DE CPTE - 2 EME TRIMESTRE 2019 AU TAEG 18,29 %",3.45,172.65
Expenses:Bank:CreditAgricole:Checking:Compte1:Fine,2019-07-04,"STMTTRN - F ARRETE DE CPTE - 2 EME TRIMESTRE 2019 AU TAEG 18,98 %",22.44,195.09
Expenses:Bank:CreditAgricole:Checking:Compte1:Fine,2019-08-20,STMTTRN - COM INTERVENTION - XCEBR400 2019081700032259000001 1 OPERATION,8.0,203.09
Expenses:Bank:CreditAgricole:Checking:Compte3:Fine,2019-08-20,STMTTRN - COM INTERVENTION - XCEBR400 2019081700032261000001 1 OPERATION,8.0,211.09
Expenses:Bank:CreditAgricole:Checking:Compte2:Fine,2019-10-04,"STMTTRN - ARRETE DE CPTE - 3 EME TRIMESTRE 2019 AU TAEG 18,34 %",6.51,217.6
Expenses:Bank:CreditAgricole:Checking:Compte1:Fine,2019-10-04,"STMTTRN - F ARRETE DE CPTE - 3 EME TRIMESTRE 2019 AU TAEG 18,34 %",15.6,233.2
Expenses:Bank:CreditAgricole:Checking:Compte3:Fine,2019-10-18,STMTTRN - COM INTERVENTION - XCEBR400 2019101700032954000001 4 OPERATIONS,32.0,265.2
Expenses:Bank:CreditAgricole:Checking:Compte3:Fine,2019-12-19,STMTTRN - COM INTERVENTION - XCEBR400 2019121800023295000001 5 OPERATIONS,40.0,305.2
Expenses:Bank:CreditAgricole:Checking:Compte2:Fine,2020-01-07,"STMTTRN - ARRETE DE CPTE - 4 EME TRIMESTRE 2019 AU TAEG 18,59 %",5.62,310.82
Expenses:Bank:CreditAgricole:Checking:Compte1:Fine,2020-01-07,"STMTTRN - ARRETE DE CPTE - 4 EME TRIMESTRE 2019 AU TAEG 18,34 %",13.06,323.88
Expenses:Bank:CreditAgricole:Checking:Compte3:Fine,2020-02-25,STMTTRN - COM INTERVENTION XCEBR400 2020022300017029000001 1 OPERATION,8.0,331.88
Expenses:Bank:CreditAgricole:Checking:Compte2:Fine,2020-03-02,STMTTRN - FRAIS ENVOI CHEQUIER - XCCCD050 2020022800030366000001 PLI SIMPLE 0000266,1.2,333.08
Expenses:Bank:CreditAgricole:Checking:Compte3:Fine,2020-03-19,STMTTRN - COM INTERVENTION - XCEBR400 2020031800038821000001 3 OPERATIONS,24.0,357.08
Expenses:Bank:CreditAgricole:Checking:Compte2:Fine,2020-04-28,STMTTRN - FRAIS ACHAT ETRANGER DI - XCPCB200 2020042800008968000001 COMMISSION CB 270420 CHANGE.OR,0.53,357.61
Expenses:Bank:CreditAgricole:Checking:Compte3:Fine,2020-05-20,STMTTRN - COM INTERVENTION XCEBR400 2020051900036583000001 1 OPERATION,8.0,365.61
Expenses:Bank:CreditAgricole:Checking:Compte3:Fine,2020-05-20,STMTTRN - FRAIS VIREMENT IMPAYE XCEBR060 2020051900036582000001 1 REJET,12.0,377.61
]';

  l_object_info_rec t_object_info_rec;
  l_view_name user_views.view_name%type := null;
  l_cursor integer := null;
  l_sql_text dbms_sql.varchar2a;

  l_column_info_tab t_column_info_tab;
  l_header_row_tab constant sys.odcivarchar2list :=
    sys.odcivarchar2list('account|-------', 'date|----', 'description|-----------', 'position (EUR)|--------------', 'running_total (EUR)|-------------------');
  l_data_row_tab constant sys.odcivarchar2list :=
    sys.odcivarchar2list('Expenses:Bank:CreditAgricole:Checking:Compte1:Fine', '2019-03-20', 'STMTTRN - COM INTERVENTION - XCEBR400 2019031900029511000001 2 OPERATIONS', '16.0', '16.0');
  l_data_type_tab constant sys.odcivarchar2list :=
    sys.odcivarchar2list('VARCHAR2(50 CHAR)', 'VARCHAR2(10 CHAR)', 'VARCHAR2(98 CHAR)', 'VARCHAR2(5 CHAR)', 'VARCHAR2(6 CHAR)');
  l_prefix varchar2(100 char);

  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'UT_GET_COLUMN_INFO_TAB';

  procedure cleanup
  is
  begin
    if l_cursor is not null
    then
      execute immediate 'drop table ' || l_object_info_rec.object_name || ' purge';
      if l_view_name is not null
      then
        execute immediate 'drop view ' || l_view_name;
      end if;
      dbms_sql.close_cursor(l_cursor);
    end if;
  exception
    when others
    then null;
  end cleanup;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
$end

  <<try_loop>>
  for i_try in 1..2
  loop
    case i_try
      when 1
      then
        null;
        
      when 2
      then
        l_object_info_rec := g_object_info_rec;
  
        l_object_info_rec.object_name := '"myobject2"';
        l_object_info_rec.header_row_from := 1;
        l_object_info_rec.header_row_till := 2;
        l_object_info_rec.data_row_from := 3;
        l_object_info_rec.data_row_till := null;
        l_object_info_rec.determine_datatype := 1;

        l_column_info_tab(l_column_info_tab.first).in_key := 1;

        l_cursor := dbms_sql.open_cursor;

        l_sql_text := create_table_statement(l_column_info_tab, l_object_info_rec.object_name, true);

        dbms_sql.parse
        ( c => l_cursor
        , statement => l_sql_text
        , lb => l_sql_text.first
        , ub => l_sql_text.last
        , lfflg => true
        , language_flag => dbms_sql.native
        );

        set_load_file_info
        ( p_object_info_rec => l_object_info_rec
        , p_column_info_tab => l_column_info_tab
        , p_view_name => l_view_name
        );

        get_object_info
        ( p_view_name => l_view_name
        , p_object_info_rec => l_object_info_rec 
        );

        get_column_info
        ( p_view_name => l_view_name
        , p_column_info_tab => l_column_info_tab
        );
    end case;

    get_column_info_tab
    ( -- common parameters
      p_apex_file_id => null
    , p_last_excel_column_name => 'ZZ'
    , p_header_row_from => 1
    , p_header_row_till => 2
    , p_data_row_from => 3
    , p_data_row_till => null
    , p_determine_datatype => 1
    , p_format_mask => null
    , p_view_name => l_view_name
      -- CSV parameters
    , p_clob => l_csv
    , p_eol => chr(10)
    , p_field_separator => ','
    , p_quote_char => '"'
      -- Spreadsheet parameters
    , p_blob => null
    , p_sheet_names => null
    , p_column_info_tab => l_column_info_tab
    );

    ut.expect(l_column_info_tab.count).to_equal(5);

    for i_idx in l_column_info_tab.first .. l_column_info_tab.last
    loop
      l_prefix := 'try: ' || i_try || '; idx: ' || i_idx || ' ';
      ut.expect(l_column_info_tab(i_idx).apex_file_id, l_prefix || 'apex_file_id').to_be_null();
      ut.expect(l_column_info_tab(i_idx).seq_id, l_prefix || 'seq_id').to_be_null();
      ut.expect(l_column_info_tab(i_idx).view_name, l_prefix || 'view_name').to_be_null();
      ut.expect(l_column_info_tab(i_idx).excel_column_name, l_prefix || 'excel_column_name').to_equal(number2excel_column_name(i_idx));
      ut.expect(l_column_info_tab(i_idx).header_row, l_prefix || 'header_row').to_equal(l_header_row_tab(i_idx));
      ut.expect(l_column_info_tab(i_idx).data_row, l_prefix || 'data_row').to_equal(l_data_row_tab(i_idx));
      ut.expect(l_column_info_tab(i_idx).data_type, l_prefix || 'data_type').to_equal(l_data_type_tab(i_idx));
      ut.expect(l_column_info_tab(i_idx).format_mask, l_prefix || 'format_mask').to_be_null();
      ut.expect(l_column_info_tab(i_idx).in_key, l_prefix || 'in_key').to_equal(case when i_try = 2 and i_idx = l_column_info_tab.first then 1 else 0 end);
      ut.expect(l_column_info_tab(i_idx).default_value, l_prefix || 'default_value').to_be_null();
    end loop;
  end loop try_loop;

  cleanup;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end

exception
  when others
  then
    cleanup;
    raise;
end ut_get_column_info_tab;

procedure ut_determine_csv_info
is
  l_eol varchar2(2 char);
  l_field_separator varchar2(1 char);
  l_module_name constant varchar2(61 char) := g_package_name || '.' || 'UT_DETERMINE_CSV_INFO';
begin
  dbug.enter(l_module_name);

  determine_csv_info
  ( p_csv => q'[Name,Surname,Salary
John,Doe,"$2,130"
Fred;Nurk;"$1,500"
Hans;Meier;"$1,650"
Ivan;Horvat;"$3,200"]'
  , p_eol => l_eol
  , p_field_separator => l_field_separator
  );

  ut.expect(l_eol, 'eol #1').to_equal(chr(10));
  ut.expect(l_field_separator, 'separator #1').to_equal(',');

  determine_csv_info
  ( p_csv => q'[John;Doe,"let use have a multi line
 field with an embedded comma separator ,"
Fred;Nurk;"$1,500"
Hans;Meier;"$1,650"
Ivan;Horvat;"$3,200"]'
  , p_eol => l_eol
  , p_field_separator => l_field_separator
  );

  ut.expect(l_eol, 'eol #2').to_equal(chr(10));
  ut.expect(l_field_separator, 'separator #2').to_equal(';');

  determine_csv_info
  ( p_csv => 'Name|Surname|Salary' || chr(10) || chr(13) ||
'Fred|Nurk|"$1,500"' || chr(10) || chr(13) ||
'Hans|Meier|"$1,650"' || chr(10) || chr(13) ||
'Ivan|Horvat|"$3,200"'
  , p_eol => l_eol
  , p_field_separator => l_field_separator
  );

  ut.expect(l_eol, 'eol #3').to_equal(chr(10) || chr(13));
  ut.expect(l_field_separator, 'separator #3').to_equal('|');

  dbug.leave;
end ut_determine_csv_info;

$end -- $if cfg_pkg.c_testing $then

end ext_load_file_pkg;
/
