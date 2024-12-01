CREATE OR REPLACE PACKAGE "API_PKG" AUTHID CURRENT_USER -- needed to invoke procedures from the calling schema without grants
is

-- for conditional compiling
c_debugging constant pls_integer := 0;

type t_rec is record
( id integer
);

type t_tab is table of t_rec;

type t_cur is ref cursor return t_rec;

/**
This package contains routines for:
- returning IDs from a cursor
- translating error messages
- convert a collection to/from a list
- convert an Excel date to an Oracle date
- handling DBMS_OUTPUT via a database link
**/

function get_data_owner
return all_objects.owner%type; -- Returns DATA_API_PKG.GET_OWNER
/** Return the owner of the package DATA_API_PKG. **/

function show_cursor
( p_cursor in t_cur -- A query cursor
)
return t_tab -- The IDs returned
pipelined;
/** Show IDs using a query. **/

function translate_error
( p_sqlerrm in varchar2 -- May be something like 'ORA-20001: #<error code>#<p1>#<p2>#<p3>
, p_function in varchar2 default 'get_error_text' -- The function that gets the text for error <error code>.
)
return varchar2; -- If p_sqlerrm starts with ORA-20001 translate it using p_function, otherwise return p_sqlerrm.
/**
Translate a generic application error, otherwise return the error.

The default translation function (get_error_text) is a stand alone function that 
does not exist by default. This is on purpose since it is system specific.
**/

function list2collection
( p_value_list in varchar2 -- A separated list of values
, p_sep in varchar2 default ',' -- The list separator
, p_ignore_null in naturaln default 1 -- Ignore null values (when set, value list "|" returns 0 elements instead of 2)
)
return sys.odcivarchar2list -- The collection of values
deterministic;
/** Convert a separated list into a collection. **/

function collection2list
( p_value_tab in sys.odcivarchar2list -- The table of values
, p_sep in varchar2 default ',' -- The list separator
, p_ignore_null in naturaln default 1 -- Ignore null values (when set, value list "|" returns 0 elements instead of 2)
)
return varchar2 -- The values separated by p_sep
deterministic;
/** Convert a collection into a separated list. **/

function excel_date_number2date
( p_date_number in integer
)
return date
deterministic;
/** Convert an Excel date into an Oracle date. **/

procedure ut_expect_violation
( p_br_name in varchar2
, p_sqlcode in integer -- default sqlcode
, p_sqlerrm in varchar2 -- default sqlerrm
, p_data_owner in all_tables.owner%type -- default get_data_owner
);
/** Used in unit testing. **/

procedure dbms_output_enable
( p_db_link in varchar2 -- The database link.
, p_buffer_size in integer default null -- The buffer size
);
/**
Enable the DBMS_OUTPUT buffer for a database link session.

Usefull while debugging a remote session using dbms_output.

Will issue:

```sql
execute immediate
  'call ' || dbms_assert.qualified_sql_name('dbms_output.enable@' || p_db_link) || '(:b1)'
  using p_buffer_size
```    
**/

procedure dbms_output_clear
( p_db_link in varchar2 -- The database link.
);
/**
Clear the DBMS_OUTPUT buffer for a database link session.

Usefull while debugging a remote session using dbms_output.

Will issue:

```sql
execute immediate
  utl_lms.format_message
  ( 'declare 
       l_line varchar2(32767 char); 
       l_status integer; 
     begin 
       dbms_output.get_line@%s(l_line, l_status);
     end;'
  , dbms_assert.simple_sql_name(p_db_link)
  ) 
```

NOTE from the Oracle documentation: 

> After calling GET_LINE or GET_LINES, any lines not retrieved before the next call to
> PUT, PUT_LINE, or NEW_LINE are discarded to avoid confusing them with the next
> message. 

So this means that a single call to get_line is enough.
**/

procedure dbms_output_flush
( p_db_link in varchar2 -- The database link.
);
/**
Flush the DBMS_OUTPUT buffer for a database link session.

Usefull while debugging a remote session using dbms_output.

The general idea is to invoke dbms_output_enable and dbms_output_clear before the
remote call and to invoke dbms_output_flush after the call.

This procedure will issue:

```sql
execute immediate
  utl_lms.format_message
  ( 'declare
       l_line varchar2(32767 char);
       l_status integer;
     begin
       loop
         dbms_output.get_line@%s(line => l_line, status => l_status);
         exit when l_status != 0;
         dbms_output.put_line(l_line);
       end loop;
     end;'
  , dbms_assert.simple_sql_name(p_db_link)
  )
```
**/

subtype t_object is varchar2(500 byte);

type t_object_natural_tab is table of natural /* >= 0 */
index by t_object;

type t_object_dependency_tab is table of t_object_natural_tab index by t_object;

subtype t_graph is t_object_dependency_tab;

procedure dsort
( p_graph in out nocopy t_graph
, p_result out nocopy dbms_sql.varchar2_table /* I */
);
/**

Sort the graph.

See depth-first search algorithm in https://en.wikipedia.org/wiki/Topological_sorting

**/

$if cfg_pkg.c_testing $then

--%suitepath(API)
--%suite

-- for unit testing
procedure ut_setup
( p_autonomous_transaction in boolean
, p_br_package_tab in data_br_pkg.t_br_package_tab
, p_init_procedure in all_procedures.object_name%type default null
, p_insert_procedure in all_procedures.object_name%type default 'UT_INSERT'
);

procedure ut_teardown
( p_autonomous_transaction in boolean
, p_br_package_tab in data_br_pkg.t_br_package_tab
, p_init_procedure in all_procedures.object_name%type default null
, p_delete_procedure in all_procedures.object_name%type default 'UT_DELETE'
);

--%test
procedure ut_excel_date_number2date;

$end

end API_PKG;
/

