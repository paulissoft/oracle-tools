CREATE OR REPLACE PACKAGE BODY "MSG_AQ_PKG" AS

-- private stuff

subtype queue_name_t is user_queues.name%type;

c_schema constant all_objects.owner%type := $$PLSQL_UNIT_OWNER;

"plsql://" constant varchar2(10) := 'plsql://';
"package://" constant varchar2(10) := 'package://';

function simple_queue_name
( p_queue_name in varchar2
)
return varchar2
is
begin
  return msg_pkg.get_object_name(p_object_name => p_queue_name, p_what => 'queue', p_fq => 0);
end simple_queue_name;

function visibility_descr
( p_visibility in binary_integer
)
return varchar2
is
begin
  return case p_visibility
           when dbms_aq.on_commit then 'ON_COMMIT'
           when dbms_aq.immediate then 'IMMEDIATE'
           else 'UNKNOWN visibility (' || to_char(p_visibility) || ')'
         end;
end visibility_descr;

function delivery_mode_descr
( p_delivery_mode in binary_integer
)
return varchar2
is
begin
  return case p_delivery_mode
           when dbms_aq.persistent then 'PERSISTENT'
           when dbms_aq.buffered then 'BUFFERED'
           when dbms_aq.persistent_or_buffered then 'PERSISTENT_OR_BUFFERED'
           else 'UNKNOWN delivery mode (' || to_char(p_delivery_mode) || ')'
         end;
end delivery_mode_descr;

function dequeue_mode_descr
( p_dequeue_mode in binary_integer
)
return varchar2
is
begin
  return case p_dequeue_mode
           when dbms_aq.browse then 'BROWSE'
           when dbms_aq.locked then 'LOCKED'
           when dbms_aq.remove then 'REMOVE'
           when dbms_aq.remove_nodata then 'REMOVE_NODATA'
           else 'UNKNOWN dequeue mode (' || to_char(p_dequeue_mode) || ')'
         end;
end dequeue_mode_descr;

function navigation_descr
( p_navigation in binary_integer
)
return varchar2
is
begin
  return case p_navigation
           when dbms_aq.next_message then 'NEXT_MESSAGE'
           when dbms_aq.next_transaction then 'NEXT_TRANSACTION'
           when dbms_aq.first_message then 'FIRST_MESSAGE'
           when dbms_aq.first_message_multi_group then 'FIRST_MESSAGE_MULTI_GROUP'
           when dbms_aq.next_message_multi_group then 'NEXT_MESSAGE_MULTI_GROUP'
           else 'UNKNOWN navigation (' || to_char(p_navigation) || ')'
         end;
end navigation_descr;

function state_descr
( p_state in binary_integer
)
return varchar2
is
begin
  return case p_state
           when dbms_aq.ready then 'READY'
           when dbms_aq.waiting then 'WAITING'
           when dbms_aq.processed then 'PROCESSED'
           when dbms_aq.expired then 'EXPIRED'
           else 'UNKNOWN state (' || to_char(p_state) || ')'
         end;
end state_descr;

function sql_object_name
( p_schema in varchar2
, p_object_name in varchar2
)
return varchar2
is
begin
  return p_schema || '.' || p_object_name;
end sql_object_name;

procedure create_queue_at
( p_queue_name in varchar2
, p_comment in varchar2
)
is
  pragma autonomous_transaction;
begin
  create_queue
  ( p_queue_name => p_queue_name
  , p_comment => p_comment
  );
  commit;
end create_queue_at;

procedure start_queue_at
( p_queue_name in varchar2
)
is
  pragma autonomous_transaction;
begin
  start_queue
  ( p_queue_name => p_queue_name
  );
  commit;
end start_queue_at;

procedure add_subscriber_at
( p_queue_name in varchar2
, p_subscriber in varchar2
, p_rule in varchar2 default null
, p_delivery_mode in binary_integer default c_subscriber_delivery_mode
)
is
  pragma autonomous_transaction;
begin
  add_subscriber
  ( p_queue_name => p_queue_name
  , p_subscriber => p_subscriber
  , p_rule => p_rule
  , p_delivery_mode => p_delivery_mode
  );
  commit;
end add_subscriber_at;  

procedure register_at
( p_queue_name in varchar2
, p_subscriber in varchar2
, p_plsql_callback in varchar2 -- schema.procedure
)
is
  pragma autonomous_transaction;
begin
  register
  ( p_queue_name => p_queue_name
  , p_subscriber => p_subscriber
  , p_plsql_callback => p_plsql_callback
  );
  commit;
end register_at;  

procedure execute_immediate
( p_statement in varchar2
)
is
begin
  execute immediate p_statement;
$if oracle_tools.cfg_pkg.c_debugging $then
exception
  when others
  then
    dbug.print(dbug."error", 'statement: %s', p_statement);
    dbug.on_error;
    raise;
$end
end execute_immediate;

procedure run_processing_method
( p_processing_method in varchar2
, p_command in varchar2
)
is
begin
  PRAGMA INLINE (execute_immediate, 'YES');
  execute_immediate
  ( utl_lms.format_message
    ( q'[call %s.do('%s', '%s')]'
    , oracle_tools.data_api_pkg.dbms_assert$sql_object_name(replace(p_processing_method, "package://"), 'package')
    , p_command
    , $$PLSQL_UNIT
    )
  );
end run_processing_method;  

-- public routines

function get_queue_name
( p_group_name in varchar2
)
return varchar2
is
begin
  return msg_pkg.get_object_name(p_object_name => replace(p_group_name, '.', '$'), p_what => 'queue', p_fq => 0);
end get_queue_name;

function get_queue_name
( p_msg in msg_typ
)
return varchar2
is
begin
  PRAGMA INLINE (get_queue_name, 'YES');
  return get_queue_name(p_msg.group$);
end get_queue_name;

procedure create_queue_table
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CREATE_QUEUE_TABLE');
$end

  dbms_aqadm.create_queue_table
  ( queue_table => c_queue_table
  , queue_payload_type => sql_object_name(c_schema, 'MSG_TYP')
--, storage_clause       IN      VARCHAR2        DEFAULT NULL
--, sort_list            IN      VARCHAR2        DEFAULT NULL
  , multiple_consumers => c_multiple_consumers
  , message_grouping => dbms_aqadm.none
  , comment => 'Queue table containing messages'
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
( p_force in boolean
)
is
  l_fq_queue_name varchar2(1000 char);
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DROP_QUEUE_TABLE');
  dbug.print(dbug."input", 'p_force: %s', dbug.cast_to_varchar2(p_force));
$end

  if p_force
  then
    -- remove subscribers and callbacks for a possibly multiple consumer queue table
    for rq in
    ( select  q.name as queue_name
      ,       qt.recipients -- SINGLE or ...
      from    all_queues q
              inner join all_queue_tables qt
              on qt.owner = q.owner and qt.queue_table = q.queue_table
      where   q.owner = trim('"' from c_schema)
      and     q.queue_table = trim('"' from c_queue_table)
      and     'NO' in ( trim(q.enqueue_enabled), trim(q.dequeue_enabled) )
    )
    loop
      l_fq_queue_name := msg_pkg.get_object_name(p_object_name => rq.queue_name, p_what => 'queue', p_schema_name => c_schema);
      
      for rsr in
      ( select  sr.location_name
        ,       case
                  when sr.subscription_name like l_fq_queue_name || ':%'
                  then trim('"' from substr(sr.subscription_name, 1 + length(l_fq_queue_name) + 1))
                end as subscriber
        from    user_subscr_registrations sr
                -- sr.subscription_name is in "SCHEMA"."QUEUE" format
        where   ( sr.subscription_name = l_fq_queue_name /* single consumer */ or
                  sr.subscription_name like l_fq_queue_name || ':%' /* multiple consumer, consumer after the : */
                )
        and     sr.location_name like "plsql://" || '%'
      )
      loop
        unregister
        ( p_queue_name => rq.queue_name
        , p_subscriber => rsr.subscriber
        , p_plsql_callback => replace(rsr.location_name, "plsql://")
        );
        if rsr.subscriber is not null
        then
          remove_subscriber
          ( p_queue_name => rq.queue_name
          , p_subscriber => rsr.subscriber
          );
        end if;
      end loop;

      drop_queue
      ( p_queue_name => rq.queue_name
      , p_force => p_force
      );
    end loop;
  end if;

  dbms_aqadm.drop_queue_table
  ( queue_table => c_queue_table
  , force => p_force
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end drop_queue_table;

procedure create_queue
( p_queue_name in varchar2
, p_comment in varchar2
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CREATE_QUEUE');
  dbug.print(dbug."input", 'p_queue_name: %s; p_comment: %s', p_queue_name, p_comment);
$end

  <<try_loop>>
  for i_try in 1..2
  loop
    begin
      dbms_aqadm.create_queue
      ( queue_name => l_queue_name
      , queue_table => c_queue_table
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
          create_queue_table;
        else
          raise;
        end if;      
    end;
  end loop try_loop;

  start_queue
  ( p_queue_name => p_queue_name
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end create_queue;

procedure drop_queue
( p_queue_name in varchar2
, p_force in boolean
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DROP_QUEUE');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_force: %s'
  , p_queue_name
  , dbug.cast_to_varchar2(p_force)
  );
$end

  if p_force
  then
    stop_queue
    ( p_queue_name => p_queue_name
    , p_wait => true
    );
  end if;

  dbms_aqadm.drop_queue
  ( queue_name => l_queue_name
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end drop_queue;

procedure start_queue
( p_queue_name in varchar2
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.START_QUEUE');
  dbug.print(dbug."input", 'p_queue_name: %s', p_queue_name);
$end

  dbms_aqadm.start_queue
  ( queue_name => l_queue_name
  , enqueue => true
  , dequeue => true
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end start_queue;

procedure stop_queue
( p_queue_name in varchar2
, p_wait in boolean
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.STOP_QUEUE');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_waits: %s'
  , p_queue_name
  , dbug.cast_to_varchar2(p_wait)
  );
$end

  dbms_aqadm.stop_queue
  ( queue_name => l_queue_name
  , enqueue => true
  , dequeue => true
  , wait => p_wait
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end stop_queue;

procedure add_subscriber
( p_queue_name in varchar2
, p_subscriber in varchar2
, p_rule in varchar2
, p_delivery_mode in binary_integer
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.ADD_SUBSCRIBER');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_subscriber: %s; p_rule: %s; p_delivery_mode: %s'
  , p_queue_name
  , p_subscriber
  , p_rule
  , delivery_mode_descr(p_delivery_mode)
  );
$end

  dbms_aqadm.add_subscriber
  ( queue_name => l_queue_name
  , subscriber => sys.aq$_agent(p_subscriber, null, null)
  , rule => p_rule
  , delivery_mode => p_delivery_mode
  );
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end add_subscriber;

procedure remove_subscriber
( p_queue_name in varchar2
, p_subscriber in varchar2
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.REMOVE_SUBSCRIBER');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_subscriber: %s'
  , p_queue_name
  , p_subscriber
  );
$end

  dbms_aqadm.remove_subscriber
  ( queue_name => l_queue_name
  , subscriber => sys.aq$_agent(p_subscriber, null, null)
  );
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end remove_subscriber;

procedure register
( p_queue_name in varchar2
, p_subscriber in varchar2
, p_plsql_callback in varchar2
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
  -- Since we add a callback for a queue the number of queues to listen to may change.
  -- If so, the MSG_SCHEDULER_PKG has to restart.
  l_groups_to_process_before sys.odcivarchar2list;
  l_groups_to_process_after sys.odcivarchar2list;
  -- see MSG_CONSTANTS_PKG
  l_processing_method constant varchar2(100) := "package://" || $$PLSQL_UNIT_OWNER || '.' || 'MSG_SCHEDULER_PKG';
  l_count pls_integer;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.REGISTER');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_subscriber: %s; p_plsql_callback: %s'
  , p_queue_name
  , p_subscriber
  , p_plsql_callback
  );
$end

  if p_plsql_callback is null or p_plsql_callback like "plsql://" || '%'
  then
    raise value_error;
  end if;

  l_groups_to_process_before := get_groups_to_process(l_processing_method);

  dbms_aq.register
  ( reg_list => sys.aq$_reg_info_list
                ( sys.aq$_reg_info
                  ( name => sql_object_name(c_schema, l_queue_name) || case when p_subscriber is not null then ':' || p_subscriber end
                  , namespace => dbms_aq.namespace_aq
                  , callback => "plsql://" || p_plsql_callback
                  , context => hextoraw('FF')
                  )
                )
  , reg_count => 1
  );

  l_groups_to_process_after := get_groups_to_process(l_processing_method);

  select  count(*)
  into    l_count
  from    ( select  b.column_value
            from    table(l_groups_to_process_before) b
            intersect
            select  a.column_value
            from    table(l_groups_to_process_after) a
          );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."info"
  , 'l_groups_to_process_before.count: %s; l_groups_to_process_after.count: %s; l_count: %s'
  , l_groups_to_process_before.count
  , l_groups_to_process_after.count
  , l_count);
$end

  if l_groups_to_process_before.count = l_groups_to_process_after.count and
     l_count = l_groups_to_process_before.count
  then
    null; -- no changes
  else
    run_processing_method
    ( l_processing_method
    , case when l_groups_to_process_after.count = 0 then 'stop' else 'restart' end
    );
  end if;  

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end register;

procedure unregister
( p_queue_name in varchar2
, p_subscriber in varchar2
, p_plsql_callback in varchar2
)
is
  -- user_subscr_registrations.subscription_name is in "SCHEMA"."QUEUE" or "SCHEMA"."QUEUE":"SUBSCRIBER" format
  l_subscription_name constant user_subscr_registrations.subscription_name%type :=
    msg_pkg.get_object_name(p_object_name => p_queue_name, p_what => 'queue', p_schema_name => c_schema) ||
    case
      when p_subscriber is not null
      then ':' || msg_pkg.get_object_name(p_object_name => p_subscriber, p_what => 'subscriber', p_fq => 0)
    end;
  -- Since we remove a callback for a queue the number of queues to listen to may change.
  -- If so, the MSG_SCHEDULER_PKG has to restart.
  l_groups_to_process_before sys.odcivarchar2list;
  l_groups_to_process_after sys.odcivarchar2list;
  -- see MSG_CONSTANTS_PKG
  l_processing_method constant varchar2(100) := "package://" || $$PLSQL_UNIT_OWNER || '.' || 'MSG_SCHEDULER_PKG';
  l_count pls_integer;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.UNREGISTER');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_subscriber: %s; p_plsql_callback: %s'
  , p_queue_name
  , p_subscriber
  , p_plsql_callback
  );
$end

  if p_plsql_callback is null or p_plsql_callback like "plsql://" || '%'
  then
    raise value_error;
  end if;

  l_groups_to_process_before := get_groups_to_process(l_processing_method);
      
  for rsr in
  ( select  sr.subscription_name
    ,       sr.location_name
    from    user_subscr_registrations sr
    where   sr.subscription_name = l_subscription_name
    and     sr.location_name like "plsql://" || p_plsql_callback escape '\'
  )
  loop
    dbms_aq.unregister
    ( reg_list => sys.aq$_reg_info_list
                  ( sys.aq$_reg_info
                    ( name => rsr.subscription_name
                    , namespace => dbms_aq.namespace_aq
                    , callback => rsr.location_name
                    , context => hextoraw('FF')
                    )
                  )
    , reg_count => 1
    );
  end loop;

  l_groups_to_process_after := get_groups_to_process(l_processing_method);

  select  count(*)
  into    l_count
  from    ( select  b.column_value
            from    table(l_groups_to_process_before) b
            intersect
            select  a.column_value
            from    table(l_groups_to_process_after) a
          );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."info"
  , 'l_groups_to_process_before.count: %s; l_groups_to_process_after.count: %s; l_count: %s'
  , l_groups_to_process_before.count
  , l_groups_to_process_after.count
  , l_count);
$end

  if l_groups_to_process_before.count = l_groups_to_process_after.count and
     l_count = l_groups_to_process_before.count
  then
    null; -- no changes
  else
    run_processing_method
    ( l_processing_method
    , case when l_groups_to_process_after.count = 0 then 'stop' else 'restart' end
    );
  end if;  

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end unregister;

procedure enqueue
( p_msg in msg_typ
, p_delivery_mode in binary_integer
, p_visibility in binary_integer
, p_correlation in varchar2
, p_force in boolean
, p_msgid out nocopy raw
)
is
  l_queue_name constant user_queues.name%type := get_queue_name(p_msg);
  l_enqueue_enabled user_queues.enqueue_enabled%type;
  l_dequeue_enabled user_queues.dequeue_enabled%type;
  l_enqueue_options dbms_aq.enqueue_options_t;
  l_message_properties dbms_aq.message_properties_t;
  c_max_tries constant simple_integer := case when p_force then 2 else 1 end;
  l_recipients all_queue_tables.recipients%type;

  procedure ensure_queue_gets_dequeued
  is
  begin
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.ENQUEUE.ENSURE_QUEUE_GETS_DEQUEUED');
    dbug.print
    ( dbug."info"
    , 'p_msg.default_processing_method(): %s; l_queue_name: %s'
    , p_msg.default_processing_method()
    , l_queue_name
    );
$end

    if p_msg.default_processing_method() like "plsql://" || '%'
    then
      select  qt.recipients
      into    l_recipients
      from    all_queues q
              inner join all_queue_tables qt
              on qt.owner = q.owner and qt.queue_table = q.queue_table
      where   q.owner = trim('"' from c_schema)
      and     q.queue_table = trim('"' from c_queue_table)
      and     q.name = trim('"' from l_queue_name);

$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'l_recipients: %s', l_recipients);
$end

      -- add default subscriber for a multiple consumer queue table
      if l_recipients <> 'SINGLE'
      then
        add_subscriber_at
        ( p_queue_name => l_queue_name
        , p_subscriber => c_default_subscriber
        );
      end if;
      
      register_at
      ( p_queue_name => l_queue_name
      , p_subscriber => case when l_recipients <> 'SINGLE' then c_default_subscriber end
      , p_plsql_callback => replace(p_msg.default_processing_method(), "plsql://")
      );
    elsif p_msg.default_processing_method() like "package://" || '%'
    then
      run_processing_method
      ( p_msg.default_processing_method()
      , 'restart'
      );
    end if;
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.leave;
$end
  end ensure_queue_gets_dequeued;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.ENQUEUE');
  dbug.print
  ( dbug."input"  
  , 'queue name: %s; p_delivery_mode: %s; p_visibility: %s; p_correlation: %s; p_force: %s'
  , l_queue_name
  , delivery_mode_descr(p_delivery_mode)
  , visibility_descr(p_visibility)
  , p_correlation
  , dbug.cast_to_varchar2(p_force)
  );
  p_msg.print();
$end

  if ( p_delivery_mode = dbms_aq.persistent and p_visibility = dbms_aq.on_commit ) -- option 1 from the spec
$if msg_aq_pkg.c_buffered_messaging $then
  or ( p_delivery_mode = dbms_aq.buffered   and p_visibility = dbms_aq.immediate ) -- option 2 from the spec
$end     
  or ( p_delivery_mode = dbms_aq.persistent and p_visibility = dbms_aq.immediate ) -- option 3 from the spec
  then 
    l_enqueue_options.delivery_mode := p_delivery_mode;
    l_enqueue_options.visibility := p_visibility;
  else
    l_enqueue_options.delivery_mode := dbms_aq.persistent;
    l_enqueue_options.visibility := dbms_aq.on_commit;

$if msg_aq_pkg.c_buffered_messaging $then
    if p_msg.has_not_null_lob() = 0
    then
      -- prefer buffered messages
      l_enqueue_options.delivery_mode := dbms_aq.buffered;
      l_enqueue_options.visibility := dbms_aq.immediate;
    end if;
$end    

    -- give a warning when the input parameters were not default and not a correct combination

$if oracle_tools.cfg_pkg.c_debugging $then
    if ( p_delivery_mode is not null or p_visibility is not null )
    then
      dbug.print
      ( dbug."warning"
      , 'delivery mode: %s => %s; visibility: %s => %s'
      , delivery_mode_descr(p_delivery_mode)
      , delivery_mode_descr(l_enqueue_options.delivery_mode)
      , visibility_descr(p_visibility)
      , visibility_descr(l_enqueue_options.visibility)
      );
    end if;
$end

  end if;

  l_message_properties.delay := dbms_aq.no_delay;
  l_message_properties.correlation := p_correlation;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."info"
  , 'l_enqueue_options.visibility: %s; l_enqueue_options.delivery_mode: %s; l_message_properties.delay: %s'
  , visibility_descr(l_enqueue_options.visibility)
  , delivery_mode_descr(l_enqueue_options.delivery_mode)
  , l_message_properties.delay
  );
$end

  l_message_properties.expiration := dbms_aq.never;

  <<try_loop>>
  for i_try in 1 .. c_max_tries
  loop
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'i_try: %s', i_try);
$end    
    begin
      dbms_aq.enqueue
      ( queue_name => l_queue_name
      , enqueue_options => l_enqueue_options
      , message_properties => l_message_properties
      , payload => p_msg
      , msgid => p_msgid
      );
      exit try_loop; -- enqueue succeeded
    exception
      when e_queue_does_not_exist or e_fq_queue_does_not_exist
      then
$if oracle_tools.cfg_pkg.c_debugging $then
        dbug.on_error;
$end
        if i_try != c_max_tries
        then
          create_queue_at
          ( p_queue_name => l_queue_name
          , p_comment => 'Queue for table ' || replace(l_queue_name, '$', '.')
          );
        else
          raise;
        end if;
        -- now ensure that the message is dequeued by either registering a callback or starting a job
        ensure_queue_gets_dequeued;
  
      when e_enqueue_disabled
      then
$if oracle_tools.cfg_pkg.c_debugging $then
        dbug.on_error;
$end
        if i_try != c_max_tries
        then
          start_queue_at
          ( p_queue_name => l_queue_name
          );
        else
          raise;
        end if;
      when others
      then raise;
    end;
  end loop try_loop;  

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_msgid: %s', rawtohex(p_msgid));
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end enqueue;

procedure dequeue
( p_queue_name in varchar2 -- Can be fully qualified (including schema).
, p_delivery_mode in binary_integer
, p_visibility in binary_integer
, p_subscriber in varchar2
, p_dequeue_mode in binary_integer
, p_navigation in binary_integer
, p_wait in binary_integer
, p_correlation in varchar2
, p_deq_condition in varchar2
, p_force in boolean
, p_msgid in out nocopy raw
, p_message_properties out nocopy dbms_aq.message_properties_t
, p_msg out nocopy msg_typ
)
is
  l_queue_name constant user_queues.name%type := nvl(simple_queue_name(p_queue_name), get_queue_name(p_msg));
  l_dequeue_options dbms_aq.dequeue_options_t;
  c_max_tries constant simple_integer := case when p_force then 2 else 1 end;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DEQUEUE (1)');
  dbug.print
  ( dbug."input"
  , 'queue name: %s; p_delivery_mode: %s; p_visibility: %s; p_subscriber: %s; p_dequeue_mode: %s'
  , l_queue_name
  , delivery_mode_descr(p_delivery_mode)
  , visibility_descr(p_visibility)
  , p_subscriber
  , dequeue_mode_descr(p_dequeue_mode)
  );
  dbug.print
  ( dbug."input"
  , 'p_navigation: %s; p_wait: %s; p_correlation: %s; p_deq_condition: %s; p_force: %s'
  , navigation_descr(p_navigation)
  , p_wait
  , p_correlation
  , p_deq_condition
  , dbug.cast_to_varchar2(p_force)
  );
  dbug.print
  ( dbug."input"
  , 'p_msgid: %s'
  , hextoraw(p_msgid)
  );
$end

  l_dequeue_options.consumer_name := p_subscriber;
  l_dequeue_options.dequeue_mode := p_dequeue_mode;
  l_dequeue_options.navigation := p_navigation;
  l_dequeue_options.wait := p_wait;
  l_dequeue_options.correlation := p_correlation;
  l_dequeue_options.deq_condition := p_deq_condition;
  l_dequeue_options.msgid := p_msgid;

  if ( p_delivery_mode = dbms_aq.persistent             and p_visibility = dbms_aq.on_commit ) -- option 1 from the spec
$if msg_aq_pkg.c_buffered_messaging $then
  or ( p_delivery_mode = dbms_aq.buffered               and p_visibility = dbms_aq.immediate ) -- option 2 from the spec
$end     
  or ( p_delivery_mode = dbms_aq.persistent             and p_visibility = dbms_aq.immediate ) -- option 3 from the spec
$if msg_aq_pkg.c_buffered_messaging $then
  or ( p_delivery_mode = dbms_aq.persistent_or_buffered and p_visibility = dbms_aq.immediate ) -- option 4 from the spec
$end     
  then 
    l_dequeue_options.delivery_mode := p_delivery_mode;
    l_dequeue_options.visibility := p_visibility;
  else
    -- Visibility must always be IMMEDIATE when dequeuing messages with delivery mode DBMS_AQ.BUFFERED or DBMS_AQ.PERSISTENT_OR_BUFFERED
    case
$if msg_aq_pkg.c_buffered_messaging $then
      -- try to preserve at least one of the input settings
      when p_delivery_mode in (dbms_aq.buffered, dbms_aq.persistent_or_buffered)
      then
        l_dequeue_options.delivery_mode := p_delivery_mode;
        l_dequeue_options.visibility := dbms_aq.immediate;
$end

      when p_visibility = dbms_aq.on_commit
      then
        l_dequeue_options.delivery_mode := dbms_aq.persistent;
        l_dequeue_options.visibility := p_visibility;
      
      else
        l_dequeue_options.delivery_mode := dbms_aq.persistent;
        l_dequeue_options.visibility := dbms_aq.on_commit;
    end case;

    -- give a warning when the input parameters were not default and not a correct combination

$if oracle_tools.cfg_pkg.c_debugging $then
    if ( p_delivery_mode is not null or p_visibility is not null )
    then
      dbug.print
      ( dbug."warning"
      , 'delivery mode: %s => %s; visibility: %s => %s'
      , delivery_mode_descr(p_delivery_mode)
      , delivery_mode_descr(l_dequeue_options.delivery_mode)
      , visibility_descr(p_visibility)
      , visibility_descr(l_dequeue_options.visibility)
      );
    end if;
$end
  end if;  

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."info"
  , 'l_dequeue_options.visibility: %s; l_dequeue_options.delivery_mode: %s'
  , visibility_descr(l_dequeue_options.visibility)
  , delivery_mode_descr(l_dequeue_options.delivery_mode)
  );
$end

  <<try_loop>>
  for i_try in 1 .. c_max_tries
  loop
    begin
      dbms_aq.dequeue
      ( queue_name => l_queue_name
      , dequeue_options => l_dequeue_options
      , message_properties => p_message_properties
      , payload => p_msg
      , msgid => p_msgid
      );
      exit try_loop; -- enqueue succeeded
    exception
      when e_queue_does_not_exist or e_fq_queue_does_not_exist
      then
        if i_try != c_max_tries
        then
          create_queue_at
          ( p_queue_name => l_queue_name
          , p_comment => 'Queue for table ' || replace(l_queue_name, '$', '.')
          );
        else
          raise;
        end if;
      when e_dequeue_disabled
      then
        if i_try != c_max_tries
        then
          start_queue_at
          ( p_queue_name => l_queue_name
          );
        else
          raise;
        end if;
    end;
  end loop try_loop;  

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_msgid: %s', rawtohex(p_msgid));
  p_msg.print();
  dbug.leave;
exception
  when others
  then
    dbug.leave;
    raise;
$end
end dequeue;

procedure dequeue_and_process
( p_queue_name in varchar2 -- Can be fully qualified (including schema).
, p_delivery_mode in binary_integer
, p_visibility in binary_integer
, p_subscriber in varchar2
, p_dequeue_mode in binary_integer
, p_navigation in binary_integer
, p_wait in binary_integer
, p_correlation in varchar2
, p_deq_condition in varchar2
, p_force in boolean
, p_commit in boolean
)
is
  l_msgid raw(16) := null;
  l_message_properties dbms_aq.message_properties_t;
  l_msg msg_typ;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DEQUEUE_AND_PROCESS (1)');
  dbug.print(dbug."input", 'p_commit: %s', p_commit);
$end

  dequeue
  ( p_queue_name => p_queue_name
  , p_delivery_mode => p_delivery_mode
  , p_visibility => p_visibility
  , p_subscriber => p_subscriber
  , p_dequeue_mode => p_dequeue_mode
  , p_navigation => p_navigation
  , p_wait => p_wait
  , p_correlation => p_correlation
  , p_deq_condition => p_deq_condition
  , p_force => p_force
  , p_msgid => l_msgid
  , p_message_properties => l_message_properties
  , p_msg => l_msg
  );

  msg_pkg.process_msg
  ( p_msg => l_msg
  , p_commit => p_commit
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave;
    raise;
$end
end dequeue_and_process;

procedure dequeue
( p_context in raw
, p_reginfo in sys.aq$_reg_info
, p_descr in sys.aq$_descriptor
, p_payload in raw
, p_payloadl in number
, p_msgid out nocopy raw
, p_message_properties out nocopy dbms_aq.message_properties_t
, p_msg out nocopy msg_typ
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DEQUEUE (2)');
  dbug.print
  ( dbug."input"
  , 'p_context: %s; p_descr.msg_id: %s; p_descr.consumer_name: %s; p_descr.queue_name: %s; p_payloadl: %s'
  , p_context
  , rawtohex(p_descr.msg_id)
  , p_descr.consumer_name
  , p_descr.queue_name
  , p_payloadl
  );
  dbug.print
  ( dbug."input"
  , 'p_descr.msg_prop.state: %s; p_descr.msg_prop.delivery_mode: %s'
  , state_descr(p_descr.msg_prop.state)
  , delivery_mode_descr(p_descr.msg_prop.delivery_mode)
  );
$end

  p_msgid := p_descr.msg_id;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."info"
  , 'USERENV: SESSIONID: %s; APEX$SESSION.APP_SESSION|CLIENT_IDENTIFIER: %s; CURRENT_USER: %s; SESSION_USER: %s; PROXY_USER: %s'
  , sys_context('USERENV', 'SESSIONID') ||
      case
        when sys_context('USERENV', 'BG_JOB_ID') is not null
        then ' (BG_JOB_ID=' || sys_context('USERENV', 'BG_JOB_ID') || ')'
        when sys_context('USERENV', 'FG_JOB_ID') is not null
        then ' (FG_JOB_ID=' || sys_context('USERENV', 'FG_JOB_ID') || ')'
      end
  , nvl(sys_context('APEX$SESSION', 'APP_SESSION'), sys_context('USERENV', 'CLIENT_IDENTIFIER'))
  , sys_context('USERENV', 'CURRENT_USER')
  , sys_context('USERENV', 'SESSION_USER')
  , sys_context('USERENV', 'PROXY_USER')
  );
$end

  dequeue
  ( p_queue_name => p_descr.queue_name
  , p_delivery_mode => p_descr.msg_prop.delivery_mode
  , p_visibility =>
      -- to suppress a warning
$if msg_aq_pkg.c_buffered_messaging $then
      case
        when p_descr.msg_prop.delivery_mode in ( dbms_aq.buffered, dbms_aq.persistent_or_buffered )
        then dbms_aq.immediate
        else dbms_aq.on_commit
      end
$else
      dbms_aq.on_commit
$end        
  , p_subscriber => p_descr.consumer_name 
  , p_dequeue_mode => dbms_aq.remove
  , p_navigation => dbms_aq.next_message
  , p_wait => dbms_aq.no_wait -- message is there
  , p_correlation => null
  , p_deq_condition => null
  , p_msgid => p_msgid
  , p_message_properties => p_message_properties
  , p_msg => p_msg
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_msgid: %s', rawtohex(p_msgid));
  dbug.leave;
exception
  when others
  then
    dbug.leave;
    raise;
$end
end dequeue;

procedure dequeue_and_process
( p_context in raw
, p_reginfo in sys.aq$_reg_info
, p_descr in sys.aq$_descriptor
, p_payload in raw
, p_payloadl in number
, p_commit in boolean
)
is
  l_msgid raw(16);
  l_message_properties dbms_aq.message_properties_t;
  l_msg msg_typ;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DEQUEUE_AND_PROCESS (2)');
  dbug.print(dbug."input", 'p_commit: %s', p_commit);
$end

  msg_aq_pkg.dequeue
  ( p_context => p_context
  , p_reginfo => p_reginfo
  , p_descr => p_descr
  , p_payload => p_payload
  , p_payloadl => p_payloadl
  , p_msgid => l_msgid
  , p_message_properties => l_message_properties
  , p_msg => l_msg
  );

  msg_pkg.process_msg
  ( p_msg => l_msg
  , p_commit => p_commit
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave;
    raise;
$end
end dequeue_and_process;

function get_groups_to_process
( p_processing_method in varchar2
)
return sys.odcivarchar2list
is
  l_msg_tab constant msg_pkg.msg_tab_t := msg_pkg.get_msg_tab;
  l_groups_to_process_tab sys.odcivarchar2list := sys.odcivarchar2list();
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.GET_GROUPS_TO_PROCESS');
  dbug.print(dbug."input", 'p_processing_method: %s', p_processing_method);
$end

$if oracle_tools.cfg_pkg.c_debugging $then

  if l_msg_tab is not null and l_msg_tab.count > 0
  then
    for i_idx in l_msg_tab.first .. l_msg_tab.last
    loop
      dbug.print
      ( dbug."info"
      , 'msg type: %s; group$: %s; default processing method: %s; queue name: %s'
      , l_msg_tab(i_idx).get_type()
      , l_msg_tab(i_idx).group$
      , l_msg_tab(i_idx).default_processing_method()
      , msg_pkg.get_object_name(p_object_name => msg_aq_pkg.get_queue_name(l_msg_tab(i_idx)), p_what => 'queue')
      );
    end loop;
  end if;
  
  for r in
  ( select  sr.subscription_name
    from    user_subscr_registrations sr
  )
  loop
    dbug.print(dbug."info", 'subscription registration name: %s', r.subscription_name);
  end loop;

  for r in
  ( select  msg_pkg.get_object_name(p_object_name => q.name, p_what => 'queue') as fq_queue_name
    from    user_queues q
    where   q.queue_type = 'NORMAL_QUEUE'
    and     q.queue_table = trim('"' from c_queue_table)
    and     trim(q.dequeue_enabled) = 'YES'
    minus
    select  case
              when sr.subscription_name like '%:%'
              then substr(sr.subscription_name, 1, instr(sr.subscription_name, ':', -1) - 1)
              else sr.subscription_name
            end as fq_queue_name -- "OWNER"."QUEUE"
    from    user_subscr_registrations sr
    order by
            fq_queue_name
  )
  loop
    dbug.print(dbug."info", 'fq queue name: %s', r.fq_queue_name);
  end loop;

$end

  select  distinct
          t.group$
  bulk collect
  into    l_groups_to_process_tab
  from    ( select  msg_pkg.get_object_name(p_object_name => q.name, p_what => 'queue') as fq_queue_name
            from    user_queues q
            where   q.queue_type = 'NORMAL_QUEUE'
            and     q.queue_table = trim('"' from c_queue_table)
            and     trim(q.dequeue_enabled) = 'YES'
            minus
            select  case
                      when sr.subscription_name like '%:%'
                      then substr(sr.subscription_name, 1, instr(sr.subscription_name, ':', -1) - 1)
                      else sr.subscription_name
                    end as fq_queue_name -- "OWNER"."QUEUE"
            from    user_subscr_registrations sr
            order by
                    fq_queue_name
          ) q
          inner join table(l_msg_tab) t
          on q.fq_queue_name = msg_pkg.get_object_name(p_object_name => msg_aq_pkg.get_queue_name(value(t)), p_what => 'queue')
  where   ( t.default_processing_method() = p_processing_method or t.default_processing_method() like "plsql://" || '%' )
  and     t.group$ is not null;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'l_groups_to_process_tab.count: %s'
  , case when l_groups_to_process_tab is not null then l_groups_to_process_tab.count end
  );
  if l_groups_to_process_tab is not null and l_groups_to_process_tab.count > 0
  then
    for i_idx in l_groups_to_process_tab.first .. l_groups_to_process_tab.last
    loop
      dbug.print(dbug."output", 'l_groups_to_process_tab(%s): %s', i_idx, l_groups_to_process_tab(i_idx));
    end loop;
  end if;  
  dbug.leave;
$end

  return l_groups_to_process_tab;
end get_groups_to_process;

procedure processing
( p_controlling_package in varchar2
, p_groups_to_process_tab in sys.odcivarchar2list
, p_worker_nr in positiven
, p_end_date in timestamp with time zone
, p_silence_threshold in number
)
is
  l_start_date constant oracle_tools.api_time_pkg.timestamp_t := oracle_tools.api_time_pkg.get_timestamp;
  l_next_heartbeat oracle_tools.api_time_pkg.timestamp_t := l_start_date;
  l_now oracle_tools.api_time_pkg.timestamp_t;
  l_elapsed_time oracle_tools.api_time_pkg.seconds_t;
  l_ttl constant positiven := oracle_tools.api_time_pkg.delta(l_start_date, p_end_date);
  l_queue_name_tab sys.odcivarchar2list := sys.odcivarchar2list();
  l_agent_list dbms_aq.aq$_agent_list_t;
  l_queue_name_idx positiven := 1;
  l_agent sys.aq$_agent;
  l_message_delivery_mode pls_integer;
  l_timestamp_tab oracle_tools.api_heartbeat_pkg.timestamp_tab_t;
  l_silent_worker_tab oracle_tools.api_heartbeat_pkg.silent_worker_tab_t;

  -- Use a simple procedure and dbug.enter/dbug.leave to be able to profile this dbms_aq.listen call.
  procedure dbms_aq_listen
  is
  begin
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.enter('DBMS_AQ.LISTEN');
$end

    dbms_aq.listen
    ( agent_list => l_agent_list
    , wait => least(msg_constants_pkg.c_time_between_heartbeats, greatest(1, trunc(l_ttl - l_elapsed_time))) -- don't use 0 but 1 second as minimal timeout since 0 seconds may kill your server
    , listen_delivery_mode => dbms_aq.persistent
    , agent => l_agent
    , message_delivery_mode => l_message_delivery_mode
    );

$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.leave;
$end
  exception
    when e_listen_timeout
    then
      l_agent := sys.aq$_agent(null, null, null);
      l_message_delivery_mode := null;
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.leave;
$end
        
    when others
    then
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.leave;
$end      
      raise;
  end dbms_aq_listen;

  procedure send_next_heartbeat
  is
  begin
    if l_now >= l_next_heartbeat
    then
      oracle_tools.api_heartbeat_pkg.send
      ( p_supervisor_channel => p_controlling_package
      , p_worker_nr => p_worker_nr
      , p_silence_threshold => p_silence_threshold
      , p_first_recv_timeout => 0 -- non-blocking
      , p_timestamp_tab => l_timestamp_tab
      , p_silent_worker_tab => l_silent_worker_tab
      );
      if l_silent_worker_tab.count > 0
      then
        raise_application_error
        ( oracle_tools.api_heartbeat_pkg.c_silent_workers_found
        , 'The supervisor is silent since at least ' || p_silence_threshold || ' seconds.'
        );
      end if;
      
      loop
        l_next_heartbeat := l_next_heartbeat + numtodsinterval(msg_constants_pkg.c_time_between_heartbeats, 'SECOND');
        exit when l_next_heartbeat > l_now;
      end loop;
    end if;
  end send_next_heartbeat;
  
  procedure cleanup
  is
  begin
    oracle_tools.api_heartbeat_pkg.done
    ( p_supervisor_channel => p_controlling_package
    , p_worker_nr => p_worker_nr
    );
  end cleanup;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESSING');
  dbug.print
  ( dbug."input"
  , 'p_controlling_package: %s; p_groups_to_process_tab.count: %s; p_worker_nr; %s; p_end_date: %s; p_silence_threshold: %s'
  , p_controlling_package
  , case when p_groups_to_process_tab is not null then p_groups_to_process_tab.count end
  , p_worker_nr
  , to_char(p_end_date, 'yyyy-mm-dd hh24:mi:ss')
  , p_silence_threshold
  );
$end

  if p_groups_to_process_tab is not null and p_groups_to_process_tab.first = 1
  then
    null;
  else
    raise value_error;
  end if;

  oracle_tools.api_heartbeat_pkg.init
  ( p_supervisor_channel => p_controlling_package
  , p_worker_nr => p_worker_nr
  , p_max_worker_nr => 0
  , p_timestamp_tab => l_timestamp_tab
  );

  <<queue_loop>>
  for i_idx in p_groups_to_process_tab.first .. p_groups_to_process_tab.last
  loop
    l_queue_name_tab.extend(1);
    l_queue_name_tab(l_queue_name_tab.last) := get_queue_name(p_groups_to_process_tab(i_idx));
  end loop queue_loop;

  -- i_idx can be from
  -- a) 1 .. l_queue_name_tab.count     (<=> 1 .. l_queue_name_tab.count + (1) - 1)
  -- b) 2 .. l_queue_name_tab.count + 1 (<=> 2 .. l_queue_name_tab.count + (2) - 1)
  -- z) l_queue_name_tab.count .. l_queue_name_tab.count + (l_queue_name_tab.count) - 1
  <<agent_loop>>
  for i_idx in mod(p_worker_nr - 1, l_queue_name_tab.count) + 1 ..
               mod(p_worker_nr - 1, l_queue_name_tab.count) + l_queue_name_tab.count
  loop
    l_queue_name_idx := mod(i_idx - 1, l_queue_name_tab.count) + 1; -- between 1 and l_queue_name_tab.count
    
    if l_queue_name_tab(l_queue_name_idx) is null
    then
      raise program_error;
    end if;

    -- assume single consumer queues
    l_agent_list(l_agent_list.count+1) :=
      sys.aq$_agent(null, l_queue_name_tab(l_queue_name_idx), null);

$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print
    ( dbug."info"
    , 'i_idx: %s; l_queue_name_tab(%s): %s; l_agent_list(%s).address: %s'
    , i_idx
    , l_queue_name_idx
    , l_queue_name_tab(l_queue_name_idx)
    , l_agent_list.count
    , l_agent_list(l_agent_list.count).address
    );
$end

    l_queue_name_tab(l_queue_name_idx) := null;
  end loop agent_loop;

  <<process_loop>>
  loop
    <<listen_then_dequeue_loop>>
    for i_step in 1..2
    loop        
      l_now := oracle_tools.api_time_pkg.get_timestamp;      

      l_elapsed_time := oracle_tools.api_time_pkg.elapsed_time(l_start_date, l_now);

$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print
      ( dbug."info"
      , 'elapsed time: %s (s); finished?: %s'
      , to_char(l_elapsed_time)
      , dbug.cast_to_varchar2(l_elapsed_time >= l_ttl)
      );
$end

      /* Test whether we must end? */
      exit process_loop when l_elapsed_time >= l_ttl;

      /* Test whether we must send a heartbeat? */
      send_next_heartbeat;

      case i_step
        when 1
        then
          dbms_aq_listen;
          -- Did we get a timeout? If so continue with the next listen action
          exit listen_then_dequeue_loop when l_agent is null or l_agent.address is null;
          
        when 2
        then
          begin
            msg_aq_pkg.dequeue_and_process
            ( p_queue_name => l_agent.address
            , p_delivery_mode => l_message_delivery_mode
            , p_visibility => dbms_aq.immediate
            , p_subscriber => l_agent.name
            , p_dequeue_mode => dbms_aq.remove
            , p_navigation => dbms_aq.first_message -- may be better for performance when concurrent messages arrive
            -- Although a message should be and a timeout of 0 should be okay, we will just specify a wait time of 1 second
            -- since I saw a few times time-outs here.
            , p_wait => 1
            , p_correlation => null
            , p_deq_condition => null
            , p_force => false -- queue should be there
            , p_commit => true
            );
          exception
            when e_dequeue_timeout -- something strange happened, just log the error
            then
$if oracle_tools.cfg_pkg.c_debugging $then
              dbug.on_error;
$end
              null; 
          end;
      end case;
    end loop listen_then_dequeue_loop;
  end loop process_loop;

  cleanup;
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'Stopped processing messages after %s seconds', to_char(l_elapsed_time));
  dbug.leave;
$end  
exception
  when oracle_tools.api_heartbeat_pkg.e_shutdown_request_received
  then
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.on_error;
$end
    cleanup;
    -- no re-raise
    
  when others
  then
    cleanup;
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.leave_on_error;
$end
    raise;
end processing;

end msg_aq_pkg;
/

