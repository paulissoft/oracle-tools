CREATE OR REPLACE PACKAGE BODY "DATA_DML_EVENT_MGR_PKG" AS

-- private stuff

function sql_object_name
( p_schema in varchar2
, p_object_name in varchar2
)
return varchar2
is
begin
  return case when instr(p_object_name, '.') = 0 then p_schema || '.' end || p_object_name;
end sql_object_name;

procedure create_queue_table_at
( p_schema in varchar2
)
is
  pragma autonomous_transaction;
begin
  create_queue_table(p_schema);
end create_queue_table_at;

procedure create_queue_at
( p_schema in varchar2
, p_queue_name in varchar2
, p_comment in varchar2
)
is
  pragma autonomous_transaction;
begin
  create_queue
  ( p_schema => p_schema
  , p_queue_name => p_queue_name
  , p_comment => p_comment
  );
  commit;
end create_queue_at;

procedure start_queue_at
( p_schema in varchar2
, p_queue_name in varchar2
)
is
  pragma autonomous_transaction;
begin
  start_queue
  ( p_schema => p_schema
  , p_queue_name => p_queue_name
  );
  commit;
end start_queue_at;

procedure add_subscriber_at
( p_schema in varchar2
, p_queue_name in varchar2
, p_subscriber in varchar2
, p_rule in varchar2 default null
, p_delivery_mode in pls_integer default dbms_aqadm.persistent_or_buffered
)
is
  pragma autonomous_transaction;
begin
  add_subscriber
  ( p_schema => p_schema
  , p_queue_name => p_queue_name
  , p_subscriber => p_subscriber
  , p_rule => p_rule
  , p_delivery_mode => p_delivery_mode
  );
  commit;
end add_subscriber_at;  

procedure register_at
( p_schema in varchar2
, p_queue_name in varchar2
, p_subscriber in varchar2 -- the name of the subscriber already added via add_subscriber (for multi-consumer queues only)
, p_plsql_callback in varchar -- schema.procedure
)
is
  pragma autonomous_transaction;
begin
  register
  ( p_schema => p_schema
  , p_queue_name => p_queue_name
  , p_subscriber => p_subscriber
  , p_plsql_callback => p_plsql_callback
  );
  commit;
end register_at;  

-- public routines

function queue_name
( p_data_row in oracle_tools.data_row_t
)
return varchar2
is
begin
  return data_api_pkg.dbms_assert$enquote_name(p_data_row.table_owner || '$' || p_data_row.table_name, 'queue');
end queue_name;

procedure create_queue_table
( p_schema in varchar2
)
is
  l_schema constant all_queues.owner%type := data_api_pkg.dbms_assert$enquote_name(p_schema, 'schema');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CREATE_QUEUE_TABLE');
  dbug.print(dbug."input", 'p_schema: %s', p_schema);
$end

  dbms_aqadm.create_queue_table
  ( queue_table => sql_object_name(l_schema, c_queue_table)
  , queue_payload_type => sql_object_name($$PLSQL_UNIT_OWNER, 'DATA_ROW_T')
--, storage_clause       IN      VARCHAR2        DEFAULT NULL
--, sort_list            IN      VARCHAR2        DEFAULT NULL
  , multiple_consumers => true
  , message_grouping => dbms_aqadm.none
  , comment => 'Queue table containing DML events'
--, auto_commit          IN      BOOLEAN         DEFAULT TRUE
--, primary_instance     IN      BINARY_INTEGER  DEFAULT 0
--, secondary_instance   IN      BINARY_INTEGER  DEFAULT 0
--, compatible           IN      VARCHAR2        DEFAULT NULL
--, secure               IN      BOOLEAN         DEFAULT FALSE
--, replication_mode     IN      BINARY_INTEGER  DEFAULT NONE
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end create_queue_table;

procedure drop_queue_table
( p_schema in varchar2
, p_force in boolean
)
is
  l_schema constant all_queues.owner%type := data_api_pkg.dbms_assert$enquote_name(p_schema, 'schema');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DROP_QUEUE_TABLE');
  dbug.print(dbug."input", 'p_schema: %s; p_force: %s', p_schema, dbug.cast_to_varchar2(p_force));
$end

  dbms_aqadm.drop_queue_table
  ( queue_table => sql_object_name(l_schema, c_queue_table)
  , force => p_force
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end drop_queue_table;

procedure create_queue
( p_schema in varchar2
, p_queue_name in varchar2
, p_comment in varchar2
)
is
  l_schema constant all_queues.owner%type := data_api_pkg.dbms_assert$enquote_name(p_schema, 'schema');
  l_queue_name constant all_queues.name%type := data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CREATE_QUEUE');
  dbug.print(dbug."input", 'p_schema: %s; p_queue_name: %s; p_comment: %s', p_schema, p_queue_name, p_comment);
$end

  <<try_loop>>
  for i_try in 1..2
  loop
    begin
      dbms_aqadm.create_queue
      ( queue_name => sql_object_name(l_schema, l_queue_name)
      , queue_table => sql_object_name(l_schema, c_queue_table)
      , queue_type => dbms_aqadm.normal_queue
      , max_retries => 0 -- no retries
      , retry_delay => 0
      , retention_time => 0
      , comment => p_comment
      );
      exit try_loop;
    exception
      when e_queue_table_does_not_exist
      then
        if i_try = 1
        then
          create_queue_table(p_schema);
        else
          raise;
        end if;      
    end;
  end loop try_loop;

  start_queue
  ( p_schema => p_schema
  , p_queue_name => p_queue_name
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end create_queue;

procedure drop_queue
( p_schema in varchar2
, p_queue_name in varchar2
, p_force in boolean
)
is
  l_schema constant all_queues.owner%type := data_api_pkg.dbms_assert$enquote_name(p_schema, 'schema');
  l_queue_name constant all_queues.name%type := data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DROP_QUEUE');
  dbug.print
  ( dbug."input"
  , 'p_schema: %s; p_queue_name: %s; p_force: %s'
  , p_schema
  , p_queue_name
  , dbug.cast_to_varchar2(p_force)
  );
$end

  if p_force
  then
    stop_queue
    ( p_schema => p_schema
    , p_queue_name => p_queue_name
    , p_wait => true
    );
  end if;

  dbms_aqadm.drop_queue
  ( queue_name => sql_object_name(l_schema, l_queue_name)
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end drop_queue;

procedure start_queue
( p_schema in varchar2
, p_queue_name in varchar2
)
is
  l_schema constant all_queues.owner%type := data_api_pkg.dbms_assert$enquote_name(p_schema, 'schema');
  l_queue_name constant all_queues.name%type := data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.START_QUEUE');
  dbug.print(dbug."input", 'p_schema: %s; p_queue_name: %s', p_schema, p_queue_name);
$end

  dbms_aqadm.start_queue
  ( queue_name => sql_object_name(l_schema, l_queue_name)
  , enqueue => true
  , dequeue => true
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end start_queue;

procedure stop_queue
( p_schema in varchar2
, p_queue_name in varchar2
, p_wait in boolean
)
is
  l_schema constant all_queues.owner%type := data_api_pkg.dbms_assert$enquote_name(p_schema, 'schema');
  l_queue_name constant all_queues.name%type := data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.STOP_QUEUE');
  dbug.print
  ( dbug."input"
  , 'p_schema: %s; p_queue_name: %s; p_waits: %s'
  , p_schema
  , p_queue_name
  , dbug.cast_to_varchar2(p_wait)
  );
$end

  dbms_aqadm.stop_queue
  ( queue_name => sql_object_name(l_schema, l_queue_name)
  , enqueue => true
  , dequeue => true
  , wait => p_wait
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end stop_queue;

procedure add_subscriber
( p_schema in varchar2
, p_queue_name in varchar2
, p_subscriber in varchar2
, p_rule in varchar2
, p_delivery_mode in pls_integer
)
is
  l_schema constant all_queues.owner%type := data_api_pkg.dbms_assert$enquote_name(p_schema, 'schema');
  l_queue_name constant all_queues.name%type := data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.ADD_SUBSCRIBER');
  dbug.print
  ( dbug."input"
  , 'p_schema: %s; p_queue_name: %s; p_subscriber: %s; p_rule: %s; p_delivery_mode: %s'
  , p_schema
  , p_queue_name
  , p_subscriber
  , p_rule
  , p_delivery_mode
  );
$end

  dbms_aqadm.add_subscriber
  ( queue_name => sql_object_name(l_schema, l_queue_name)
  , subscriber => sys.aq$_agent(p_subscriber, null, null)
  , rule => p_rule
  , delivery_mode => p_delivery_mode
  );
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end add_subscriber;

procedure remove_subscriber
( p_schema in varchar2
, p_queue_name in varchar2
, p_subscriber in varchar2
)
is
  l_schema constant all_queues.owner%type := data_api_pkg.dbms_assert$enquote_name(p_schema, 'schema');
  l_queue_name constant all_queues.name%type := data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.REMOVE_SUBSCRIBER');
  dbug.print
  ( dbug."input"
  , 'p_schema: %s; p_queue_name: %s; p_subscriber: %s'
  , p_schema
  , p_queue_name
  , p_subscriber
  );
$end

  dbms_aqadm.remove_subscriber
  ( queue_name => sql_object_name(l_schema, l_queue_name)
  , subscriber => sys.aq$_agent(p_subscriber, null, null)
  );
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end remove_subscriber;

procedure register
( p_schema in varchar2
, p_queue_name in varchar2
, p_subscriber in varchar2
, p_plsql_callback in varchar
)
is
  l_schema constant all_queues.owner%type := data_api_pkg.dbms_assert$enquote_name(p_schema, 'schema');
  l_queue_name constant all_queues.name%type := data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.REGISTER');
  dbug.print
  ( dbug."input"
  , 'p_schema: %s; p_queue_name: %s; p_subscriber: %s; p_plsql_callback: %s'
  , p_schema
  , p_queue_name
  , p_subscriber
  , p_plsql_callback
  );
$end

  dbms_aq.register
  ( reg_list => sys.aq$_reg_info_list
                ( sys.aq$_reg_info
                  ( name => sql_object_name(l_schema, l_queue_name) || case when p_subscriber is not null then ':' || p_subscriber end
                  , namespace => dbms_aq.namespace_aq
                  , callback => 'plsql://' || p_plsql_callback
                  , context => hextoraw('FF')
                  )
                )
  , reg_count => 1
  );
end register;

procedure unregister
( p_schema in varchar2
, p_queue_name in varchar2
, p_subscriber in varchar2
, p_plsql_callback in varchar
)
is
  l_schema constant all_queues.owner%type := data_api_pkg.dbms_assert$enquote_name(p_schema, 'schema');
  l_queue_name constant all_queues.name%type := data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UNREGISTER');
  dbug.print
  ( dbug."input"
  , 'p_schema: %s; p_queue_name: %s; p_subscriber: %s; p_plsql_callback: %s'
  , p_schema
  , p_queue_name
  , p_subscriber
  , p_plsql_callback
  );
$end

  dbms_aq.unregister
  ( reg_list => sys.aq$_reg_info_list
                ( sys.aq$_reg_info
                  ( name => sql_object_name(l_schema, l_queue_name) || case when p_subscriber is not null then ':' || p_subscriber end
                  , namespace => dbms_aq.namespace_aq
                  , callback => 'plsql://' || p_plsql_callback
                  , context => hextoraw('FF')
                  )
                )
  , reg_count => 1
  );
end unregister;

procedure dml
( p_schema in varchar2
, p_data_row in oracle_tools.data_row_t
, p_force in boolean
)
is
  l_schema constant all_queues.owner%type := data_api_pkg.dbms_assert$enquote_name(p_schema, 'schema');
  l_queue_name constant user_queues.name%type := queue_name(p_data_row);
  l_enqueue_enabled user_queues.enqueue_enabled%type;
  l_dequeue_enabled user_queues.dequeue_enabled%type;
  l_enqueue_options dbms_aq.enqueue_options_t;
  l_message_properties dbms_aq.message_properties_t;
  l_msgid raw(16);
  c_max_tries constant simple_integer := case when p_force then 2 else 1 end;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DML');
  dbug.print
  ( dbug."input"
  , 'p_schema: %s; p_force: %s'
  , p_schema
  , dbug.cast_to_varchar2(p_force)
  );
$end

  if p_data_row.has_non_empty_lob() != 0
  then
    -- payload with a non-empty LOB can not be a buffered message
    l_enqueue_options.visibility := dbms_aq.on_commit;
    l_enqueue_options.delivery_mode := dbms_aq.persistent;
  else
    -- buffered messages
    l_enqueue_options.visibility := dbms_aq.immediate;
    l_enqueue_options.delivery_mode := dbms_aq.buffered;
  end if;

  l_message_properties.delay := dbms_aq.no_delay;
  l_message_properties.expiration := dbms_aq.never;

  <<try_loop>>
  for i_try in 1 .. c_max_tries
  loop
    begin
      dbms_aq.enqueue
      ( queue_name => sql_object_name(l_schema, l_queue_name)
      , enqueue_options => l_enqueue_options
      , message_properties => l_message_properties
      , payload => p_data_row
      , msgid => l_msgid
      );
      exit try_loop; -- enqueue succeeded
    exception
      when e_queue_does_not_exist
      then
        if i_try != c_max_tries
        then
          create_queue_at
          ( p_schema => p_schema
          , p_queue_name => l_queue_name
          , p_comment => 'Queue for table ' || replace(l_queue_name, '$', '.')
          );
          add_subscriber_at
          ( p_schema => p_schema
          , p_queue_name => l_queue_name
          , p_subscriber => 'DEFAULT'
          );
          register_at
          ( p_schema => p_schema
          , p_queue_name => l_queue_name
          , p_subscriber => 'DEFAULT'
          , p_plsql_callback => sql_object_name(p_schema, 'DATA_ROW_NOTIFICATION_PRC')
          );
        else
          raise;
        end if;
      when e_enqueue_disabled
      then
        if i_try != c_max_tries
        then
          start_queue_at
          ( p_schema => p_schema
          , p_queue_name => l_queue_name
          );
        else
          raise;
        end if;
      when others
      then raise;
    end;
  end loop try_loop;  

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end dml;

end data_dml_event_mgr_pkg;
/

