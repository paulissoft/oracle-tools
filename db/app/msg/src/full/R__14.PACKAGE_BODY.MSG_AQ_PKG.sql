CREATE OR REPLACE PACKAGE BODY "MSG_AQ_PKG" AS

-- private stuff

c_schema constant all_objects.owner%type := $$PLSQL_UNIT_OWNER;

function sql_object_name
( p_schema in varchar2
, p_object_name in varchar2
)
return varchar2
is
begin
  return p_schema || '.' || p_object_name;
end sql_object_name;

procedure create_queue_table_at
is
  pragma autonomous_transaction;
begin
  create_queue_table;
end create_queue_table_at;

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
, p_subscriber in varchar2 default c_default_subscriber
, p_rule in varchar2 default null
, p_delivery_mode in pls_integer default dbms_aqadm.persistent
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
, p_subscriber in varchar2 default c_default_subscriber -- the name of the subscriber already added via add_subscriber (for multi-consumer queues only)
, p_plsql_callback in varchar -- schema.procedure
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

-- public routines

function queue_name
( p_msg in msg_typ
)
return varchar2
is
begin
  return oracle_tools.data_api_pkg.dbms_assert$enquote_name(replace(p_msg.source$, '.', '$'), 'queue');
end queue_name;

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
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DROP_QUEUE_TABLE');
  dbug.print(dbug."input", 'p_force: %s', dbug.cast_to_varchar2(p_force));
$end

  if p_force
  then
    for rq in
    ( select  q.name as queue_name
      from    all_queues q
      where   q.owner = trim('"' from c_schema)
      and     q.queue_table = trim('"' from c_queue_table)
      and     'NO' in ( trim(q.enqueue_enabled), trim(q.dequeue_enabled) )
    )
    loop
      for rsr in
      ( select  location_name
        from    user_subscr_registrations sr
        where   sr.subscription_name = c_schema || '.' || oracle_tools.data_api_pkg.dbms_assert$enquote_name(rq.queue_name, 'queue')
      )
      loop
        unregister
        ( p_queue_name => rq.queue_name
        , p_plsql_callback => rsr.location_name
        );
      end loop;
      if c_multiple_consumers
      then
        remove_subscriber
        ( p_queue_name => rq.queue_name
        );
      end if;
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
, p_delivery_mode in pls_integer
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
  , p_delivery_mode
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
, p_plsql_callback in varchar
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
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

  dbms_aq.register
  ( reg_list => sys.aq$_reg_info_list
                ( sys.aq$_reg_info
                  ( name => sql_object_name(c_schema, l_queue_name) || case when p_subscriber is not null then ':' || p_subscriber end
                  , namespace => dbms_aq.namespace_aq
                  , callback => 'plsql://' || p_plsql_callback
                  , context => hextoraw('FF')
                  )
                )
  , reg_count => 1
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
end register;

procedure unregister
( p_queue_name in varchar2
, p_subscriber in varchar2
, p_plsql_callback in varchar
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
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

  dbms_aq.unregister
  ( reg_list => sys.aq$_reg_info_list
                ( sys.aq$_reg_info
                  ( name => sql_object_name(c_schema, l_queue_name) || case when p_subscriber is not null then ':' || p_subscriber end
                  , namespace => dbms_aq.namespace_aq
                  , callback => 'plsql://' || p_plsql_callback
                  , context => hextoraw('FF')
                  )
                )
  , reg_count => 1
  );
end unregister;

procedure enqueue
( p_msg in msg_typ
, p_force in boolean default true -- When true, queue tables, queues, subscribers and notifications will be created/added if necessary.
, p_msgid out nocopy raw
)
is
  l_queue_name constant user_queues.name%type := queue_name(p_msg);
  l_enqueue_enabled user_queues.enqueue_enabled%type;
  l_dequeue_enabled user_queues.dequeue_enabled%type;
  l_enqueue_options dbms_aq.enqueue_options_t;
  l_message_properties dbms_aq.message_properties_t;
  c_max_tries constant simple_integer := case when p_force then 2 else 1 end;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.ENQUEUE');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_force: %s'
  , p_queue_name
  , dbug.cast_to_varchar2(p_force)
  );
$end

  if not(c_buffered_messaging_ok) or p_msg.has_non_empty_lob() != 0 -- GJP 2023-01-30 temporarily disable buffered messaging
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
      ( queue_name => l_queue_name
      , enqueue_options => l_enqueue_options
      , message_properties => l_message_properties
      , payload => p_msg
      , msgid => p_msgid
      );
      exit try_loop; -- enqueue succeeded
    exception
      when e_queue_does_not_exist
      then
        if i_try != c_max_tries
        then
          create_queue_at
          ( p_queue_name => l_queue_name
          , p_comment => 'Queue for table ' || replace(l_queue_name, '$', '.')
          );
          if c_multiple_consumers
          then
            add_subscriber_at
            ( p_queue_name => l_queue_name
            );
          end if;
          register_at
          ( p_queue_name => l_queue_name
          , p_plsql_callback => c_default_plsql_callback
          );
        else
          raise;
        end if;
      when e_enqueue_disabled
      then
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
, p_subscriber in varchar2 default c_default_subscriber
, p_dequeue_mode in binary_integer default dbms_aq.remove
, p_navigation in binary_integer default dbms_aq.next_message
, p_visibility in binary_integer default dbms_aq.on_commit
, p_wait in binary_integer default dbms_aq.forever
, p_deq_condition in varchar2 default null
, p_msgid in out nocopy raw
, p_message_properties out nocopy dbms_aq.message_properties_t
, p_msg out nocopy msg_typ
)
is
  l_queue_name constant user_queues.name%type := nvl(p_queue_name, queue_name(p_msg));
  l_dequeue_options dbms_aq.dequeue_options_t;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DEQUEUE');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_subscriber: %s; p_dequeue_mode: %s; p_navigation: %s'
  , p_queue_name
  , p_subscriber
  , p_dequeue_mode
  , p_navigation
  );
  dbug.print
  ( dbug."input"
  , 'p_visibility: %s; p_wait: %s; p_deq_condition: %s; p_msgid: %s'
  , p_visibility
  , p_wait
  , p_deq_condition
  , hextoraw(p_msgid)
  );
$end

  l_dequeue_options.consumer_name := p_subscriber;
  l_dequeue_options.dequeue_mode := p_dequeue_mode;
  l_dequeue_options.navigation := p_navigation;
  l_dequeue_options.visibility := p_visibility;
  l_dequeue_options.wait := p_wait;
  l_dequeue_options.deq_condition := p_deq_condition;
  l_dequeue_options.msgid := p_msgid;

  -- Visibility must always be IMMEDIATE when dequeuing messages with delivery mode DBMS_AQ.BUFFERED or DBMS_AQ.PERSISTENT_OR_BUFFERED.
  l_dequeue_options.visibility :=
    case
      when c_delivery_mode in ( dbms_aq.buffered, dbms_aq.persistent_or_buffered )
      then dbms_aq.immediate
      else dbms_aq.on_commit
    end;

  dbms_aq.dequeue
  ( queue_name => l_queue_name
  , dequeue_options => l_dequeue_options
  , message_properties => p_message_properties
  , payload => p_msg
  , msgid => p_msgid
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_msgid: %s', rawtohex(p_msgid));
  dbug.leave;
$end
end dequeue;

procedure dequeue_notification
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
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DEQUEUE_NOTIFICATION');
  dbug.print
  ( dbug."input"
  , 'p_context: %s; p_descr.msg_id: %s; p_descr.consumer_name: %s; p_descr.queue_name: %s; p_payloadl: %s'
  , p_context
  , rawtohex(p_descr.msg_id)
  , p_descr.consumer_name
  , p_descr.queue_name
  , p_payloadl
  );
$end

  p_msgid := p_descr.msg_id;

  dequeue
  ( p_queue_name => p_descr.queue_name
  , p_subscriber => p_descr.consumer_name
  , p_msgid => p_msgid
  , p_message_properties => p_message_properties
  , p_msg => p_msg
  );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_msgid: %s', rawtohex(p_msgid));
  dbug.leave;
$end
end dequeue_notification;

end msg_aq_pkg;
/

