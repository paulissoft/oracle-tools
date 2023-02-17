CREATE OR REPLACE PACKAGE BODY "MSG_AQ_PKG" AS

-- private stuff

c_schema constant all_objects.owner%type := $$PLSQL_UNIT_OWNER;

-- three values:
-- 1) TRUE (a callback)
-- 2) FALSE (no callback but someone else (job?) handles it)
-- 3) UNKNOWN or not existing
g_fq_queue_has_callback_tab msg_pkg.t_boolean_lookup_tab;

function simple_queue_name
( p_queue_name in varchar2
)
return varchar2
is
begin
  return oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_queue_name, 'queue');
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
           else 'UNKNOWN delivey mode (' || to_char(p_delivery_mode) || ')'
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

$if msg_aq_pkg.c_multiple_consumers $then

procedure add_subscriber_at
( p_queue_name in varchar2
, p_subscriber in varchar2 default c_default_subscriber
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

$end

procedure register_at
( p_queue_name in varchar2
, p_subscriber in varchar2 default c_default_subscriber -- the name of the subscriber already added via add_subscriber (for multi-consumer queues only)
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

procedure run_job_to_dequeue_at
( p_fq_queue_name in varchar2
)
is
  pragma autonomous_transaction;

  l_include_group_list varchar2(4000 char) := '%';
  l_job_name_suffix all_objects.object_name%type := null;
  l_repeat_interval varchar2(4000 char) := null;
begin
  -- Does job supervisor exist?
  -- a) If true, we must create a one-off job to dequeue the new queue.
  --    When that one-off job finishes, subsequent runs of the normal supervisor job job will take over.
  -- b) If not, we just create the supervisor job that will dequeue all queues.
  if msg_pkg.does_job_supervisor_exist
  then
    -- Case a
    l_include_group_list := replace(p_fq_queue_name, '_', '\_');
    l_job_name_suffix := trim('"' from p_fq_queue_name);
  else
    -- Case b
    l_repeat_interval := 'FREQ=DAILY';
  end if;

  msg_pkg.submit_processing_supervisor
  ( p_include_group_list => l_include_group_list
  , p_nr_workers_each_group => 1
    -- job parameters
  , p_job_name_suffix => l_job_name_suffix
  , p_repeat_interval => l_repeat_interval
  );

  g_fq_queue_has_callback_tab(p_fq_queue_name) := false;
end run_job_to_dequeue_at;

-- public routines

function queue_name
( p_msg in msg_typ
)
return varchar2
is
begin
  return oracle_tools.data_api_pkg.dbms_assert$enquote_name(replace(p_msg.group$, '.', '$'), 'queue');
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
/*      
      if c_multiple_consumers
      then
        remove_subscriber
        ( p_queue_name => rq.queue_name
        );
      end if;
*/      
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

  if p_plsql_callback is null
  then
    raise value_error;
  end if;

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

  g_fq_queue_has_callback_tab(simple_queue_name(p_queue_name)) := true;

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

  if g_fq_queue_has_callback_tab.exists(simple_queue_name(p_queue_name))
  then
    g_fq_queue_has_callback_tab.delete(simple_queue_name(p_queue_name));
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
, p_plsql_callback in varchar2
, p_msgid out nocopy raw
)
is
  l_queue_name constant user_queues.name%type := simple_queue_name(queue_name(p_msg));
  l_enqueue_enabled user_queues.enqueue_enabled%type;
  l_dequeue_enabled user_queues.dequeue_enabled%type;
  l_enqueue_options dbms_aq.enqueue_options_t;
  l_message_properties dbms_aq.message_properties_t;
  c_max_tries constant simple_integer := case when p_force then 2 else 1 end;

  procedure ensure_queue_gets_dequeued
  is
    l_processing_group_tab sys.odcivarchar2list;
  begin
    if g_fq_queue_has_callback_tab.exists(l_queue_name) and
       g_fq_queue_has_callback_tab(l_queue_name) is not null
    then
      -- there is either a callback or a job
      null; -- OK
    elsif p_plsql_callback is not null
    then
$if msg_aq_pkg.c_multiple_consumers $then
      add_subscriber_at
      ( p_queue_name => l_queue_name
      );
$end
      register_at
      ( p_queue_name => l_queue_name
      , p_plsql_callback => p_plsql_callback
      );
    else
      -- This one excludes the web service response queue
      get_groups_for_processing
      ( p_include_group_tab => sys.odcivarchar2list(l_queue_name)
      , p_exclude_group_tab => sys.odcivarchar2list(replace(web_service_response_typ.default_group, '_', '\_'))
      , p_processing_group_tab => l_processing_group_tab
      );
      -- l_queue_name is a simple enquoted queue name
      if l_processing_group_tab.count > 0
      then
        -- Create and run a job to process this queue.
        run_job_to_dequeue_at
        ( p_fq_queue_name => l_queue_name
        );
      else
        g_fq_queue_has_callback_tab(l_queue_name) := false;
      end if;
    end if;
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
  dbug.print
  ( dbug."input"  
  , 'p_plsql_callback: %s'
  , p_plsql_callback
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
        if i_try != c_max_tries
        then
          create_queue_at
          ( p_queue_name => l_queue_name
          , p_comment => 'Queue for table ' || replace(l_queue_name, '$', '.')
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

  -- now ensure that the message is dequeued by either registering a callback or starting a job
  ensure_queue_gets_dequeued;
  
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
  l_queue_name constant user_queues.name%type := simple_queue_name(nvl(p_queue_name, queue_name(p_msg)));
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
    dbug.leave_on_error;
    raise;
$end
end dequeue_and_process;

-- will be invoked by MSG_PKG
procedure get_groups_for_processing
( p_include_group_tab in sys.odcivarchar2list
, p_exclude_group_tab in sys.odcivarchar2list
, p_processing_group_tab out nocopy sys.odcivarchar2list
)
is
  l_schema_owner constant all_objects.owner%type := dbms_assert.enquote_name($$PLSQL_UNIT_OWNER); -- ensure correct case
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.GET_GROUPS_FOR_PROCESSING');
  dbug.print
  ( dbug."input"
  , 'p_include_group_tab.count: %s; p_exclude_group_tab.count: %s'
  , case when p_include_group_tab is not null then p_include_group_tab.count end
  , case when p_exclude_group_tab is not null then p_exclude_group_tab.count end
  );
$end

  -- determine the normal queues matching one of the input queues (that may have wildcards)
  select  dbms_assert.enquote_name(substr(fq_queue_name, 1 + length(l_schema_owner || '.'))) as queue_name
  bulk collect
  into    p_processing_group_tab
  from    ( select  l_schema_owner || '.' || dbms_assert.enquote_name(q.name) as fq_queue_name
            from    user_queues q
                    inner join table(p_include_group_tab) qni
                    on q.name like qni.column_value escape '\'
                    inner join table(p_exclude_group_tab) qne
                    on q.name not like qne.column_value escape '\'
            where   q.queue_type = 'NORMAL_QUEUE'
            and     trim(q.dequeue_enabled) = 'YES'
            minus
            select  sr.subscription_name as fq_queue_name -- "OWNER"."QUEUE"
            from    user_subscr_registrations sr
            order by
                    fq_queue_name
          );


$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'p_processing_group_tab.count: %s'
  , case when p_processing_group_tab is not null then p_processing_group_tab.count end
  );
  dbug.leave;
$end
end get_groups_for_processing;

-- will be invoked by MSG_PKG
procedure processing
( p_processing_group_tab in sys.odcivarchar2list
, p_worker_nr in positiven
, p_ttl in positiven
, p_job_name_supervisor in varchar2
)
is
  l_queue_name_tab sys.odcivarchar2list := p_processing_group_tab;
  l_agent_list dbms_aq.aq$_agent_list_t;
  l_queue_name_idx positiven := 1;
  l_agent sys.aq$_agent;
  l_message_delivery_mode pls_integer;
  l_start constant number := dbms_utility.get_time;
  l_elapsed_time number;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESSING');
  dbug.print
  ( dbug."input"
  , 'p_processing_group_tab.count: %s; p_worker_nr; %s; p_ttl: %s; p_job_name_supervisor: %s'
  , case when p_processing_group_tab is not null then p_processing_group_tab.count end
  , p_worker_nr
  , p_ttl
  , p_job_name_supervisor
  );
$end

  if l_queue_name_tab is not null and l_queue_name_tab.first = 1
  then
    null;
  else
    raise value_error;
  end if;

  -- i_idx can be from
  -- a) 1 .. l_queue_name_tab.count     (<=> 1 .. l_queue_name_tab.count + (1) - 1)
  -- b) 2 .. l_queue_name_tab.count + 1 (<=> 2 .. l_queue_name_tab.count + (2) - 1)
  -- z) l_queue_name_tab.count .. l_queue_name_tab.count + (l_queue_name_tab.count) - 1
  for i_idx in mod(p_worker_nr - 1, l_queue_name_tab.count) + 1 ..
               mod(p_worker_nr - 1, l_queue_name_tab.count) + l_queue_name_tab.count
  loop
    l_queue_name_idx := mod(i_idx - 1, l_queue_name_tab.count) + 1; -- between 1 and l_queue_name_tab.count
    
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."input", 'i_idx: %s; l_queue_name_tab(%s): %s', i_idx, l_queue_name_idx, l_queue_name_tab(l_queue_name_idx));
$end

    if l_queue_name_tab(l_queue_name_idx) is null
    then
      raise program_error;
    end if;
    
    l_agent_list(l_agent_list.count+1) :=
      sys.aq$_agent(null, l_queue_name_tab(l_queue_name_idx), null);
    l_queue_name_tab(l_queue_name_idx) := null;
  end loop;

  loop
    l_elapsed_time := msg_pkg.elapsed_time(l_start, dbms_utility.get_time);

$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'elapsed time: %s seconds', to_char(l_elapsed_time));
$end

    exit when l_elapsed_time >= p_ttl;

    -- to be able to profile this call
    dbms_aq.listen
    ( agent_list => l_agent_list
    , wait => greatest(1, trunc(p_ttl - l_elapsed_time)) -- don't use 0 but 1 second as minimal timeout since 0 seconds may kill your server
    , listen_delivery_mode => dbms_aq.persistent_or_buffered
    , agent => l_agent
    , message_delivery_mode => l_message_delivery_mode
    );

    l_elapsed_time := msg_pkg.elapsed_time(l_start, dbms_utility.get_time);

$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'elapsed time: %s seconds', to_char(l_elapsed_time));
$end

    exit when l_elapsed_time >= p_ttl;

    msg_aq_pkg.dequeue_and_process
    ( p_queue_name => l_agent.address
    , p_delivery_mode => l_message_delivery_mode
    , p_visibility => dbms_aq.immediate
    , p_subscriber => l_agent.name
    , p_dequeue_mode => dbms_aq.remove
    , p_navigation => dbms_aq.first_message -- may be better for performance when concurrent messages arrive
    , p_wait => 0 -- message should be there so there is no need to wait
    , p_correlation => null
    , p_deq_condition => null
    , p_force => false -- queue should be there
    , p_commit => true
    );
  end loop;
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'Stopped processing messages after %s seconds', to_char(l_elapsed_time));
$end

  -- OK
  msg_pkg.send_worker_status
  ( p_job_name_supervisor => p_job_name_supervisor
  , p_worker_nr => p_worker_nr
  , p_sqlcode => 0
  , p_sqlerrm => null
  , p_timeout => 0
  );
exception
  when msg_pkg.e_dbms_pipe_error
  then
    raise;
    
  when others
  then
    msg_pkg.send_worker_status
    ( p_job_name_supervisor => p_job_name_supervisor
    , p_worker_nr => p_worker_nr
    , p_sqlcode => sqlcode
    , p_sqlerrm => sqlerrm
    , p_timeout => 0
    );
    raise;
end processing;

end msg_aq_pkg;
/

