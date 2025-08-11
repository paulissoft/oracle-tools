CREATE OR REPLACE PACKAGE BODY "MSG_AQ_PKG" AS

-- private stuff

subtype queue_name_t is user_queues.name%type;

c_schema constant all_objects.owner%type := $$PLSQL_UNIT_OWNER;

"plsql://" constant varchar2(10) := 'plsql://';
"package://" constant varchar2(10) := 'package://';

subtype t_processing_method is user_subscr_registrations.location_name%type;
-- first entry is p_msg.default_processing_method() (empty, c_default_notification_processing_method or c_default_scheduler_processing_method)
$if msg_aq_pkg.c_use_default_notification_processing_method $then  
-- second entry is c_default_notification_processing_method when first entry is c_default_scheduler_processing_method
$end
subtype t_processing_method_tab is sys.odcivarchar2list; 
type t_processing_method_by_queue_tab is table of t_processing_method_tab index by user_queues.name%type;

c_empty_processing_method_tab constant t_processing_method_tab := sys.odcivarchar2list();

g_previous_processing_method_tab t_processing_method_by_queue_tab;

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
, p_max_retries in naturaln default 1
, p_retry_delay in naturaln default 0
, p_retention_time in naturaln default 24 * 60 * 60 -- 1 day
)
is
  pragma autonomous_transaction;
begin
  create_queue
  ( p_queue_name => p_queue_name
  , p_comment => p_comment
  , p_max_retries => p_max_retries
  , p_retry_delay => p_retry_delay
  , p_retention_time => p_retention_time
  );
  commit;
exception
  when others
  then
    rollback;
    raise;
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
exception
  when others
  then
    rollback;
    raise;
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
exception
  when others
  then
    rollback;
    raise;
end add_subscriber_at;  

procedure remove_subscriber_at
( p_queue_name in varchar2
, p_subscriber in varchar2
)
is
  pragma autonomous_transaction;
begin
  remove_subscriber
  ( p_queue_name => p_queue_name
  , p_subscriber => p_subscriber
  );
  commit;
exception
  when others
  then
    rollback;
    raise;
end remove_subscriber_at;  

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
exception
  when others
  then
    rollback;
    raise;
end register_at;  

procedure unregister_at
( p_queue_name in varchar2
, p_subscriber in varchar2
, p_plsql_callback in varchar2 -- schema.procedure
)
is
  pragma autonomous_transaction;
begin
  unregister
  ( p_queue_name => p_queue_name
  , p_subscriber => p_subscriber
  , p_plsql_callback => p_plsql_callback
  );
  commit;
exception
  when others
  then
    rollback;
    raise;
end unregister_at;  

procedure execute_immediate
( p_statement in varchar2
)
is
begin
  execute immediate p_statement;
$if msg_aq_pkg.c_debugging >= 2 $then
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
    ( q'[begin %s.do('%s', '%s'); end;]'
    , oracle_tools.data_api_pkg.dbms_assert$sql_object_name(replace(p_processing_method, "package://"), 'package')
    , p_command
    , $$PLSQL_UNIT
    )
  );
end run_processing_method;  

procedure ensure_queue_gets_dequeued
( p_default_processing_method in varchar2
, p_queue_name in user_queues.name%type -- a simple queue name (no owner)
)
is
  l_module_name constant varchar2(100 byte) := $$PLSQL_UNIT_OWNER|| '.' || $$PLSQL_UNIT || '.' || 'ENSURE_QUEUE_GETS_DEQUEUED';

  l_subscriber user_subscr_registrations.subscription_name%type := null;
  l_recipients all_queue_tables.recipients%type := null;
  l_previous_processing_method1 t_processing_method;
$if msg_aq_pkg.c_use_default_notification_processing_method $then  
  l_previous_processing_method2 t_processing_method;
$end  
  
  function get_subscriber
  return l_subscriber%type
  is
  begin
    if l_recipients is null -- cache result
    then
      select  qt.recipients
      into    l_recipients
      from    all_queues q
              inner join all_queue_tables qt
              on qt.owner = q.owner and qt.queue_table = q.queue_table
      where   q.owner = trim('"' from c_schema)
      and     q.queue_table = trim('"' from c_queue_table)
      and     q.name = trim('"' from p_queue_name);

      l_subscriber := case when l_recipients <> 'SINGLE' then c_default_subscriber else null end;
      
$if msg_aq_pkg.c_debugging >= 2 $then
      dbug.print(dbug."info", 'l_subscriber: %s', l_subscriber);
$end
    end if;
    
    return l_subscriber;
  end;
begin
$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.ENSURE_QUEUE_GETS_DEQUEUED');
  dbug.print
  ( dbug."input"
  , 'p_default_processing_method: %s; p_queue_name: %s'
  , p_default_processing_method
  , p_queue_name
  );
$end

  -- input check
  if p_default_processing_method is null
  or p_default_processing_method in ( c_default_notification_processing_method, c_default_scheduler_processing_method )
  then null;
  else raise value_error;
  end if;

  -- Determine the previous processing method (if not yet known) that:
  -- a) will be the location name in the user_subscr_registrations
  --    for the fully qualified queue table (with an optional subscriber) and
  --    when the location name starts with 'plsql://'
  -- b) will be the default processing method (i.e. msg_constants_pkg.get_default_processing_method)
  --    when the queue is in the job argument value (for argument P_GROUPS_TO_PROCESS_LIST and job MSG_AQ_PKG$PROCESSING_SUPERVISOR) and
  --    when the default processing method equals 'package://' || $$PLSQL_UNIT_OWNER || '.' || 'MSG_SCHEDULER_PKG' 
  if not g_previous_processing_method_tab.exists(p_queue_name)
  then
    g_previous_processing_method_tab(p_queue_name) := c_empty_processing_method_tab;
    
    declare
      l_fq_queue_name constant user_subscr_registrations.subscription_name%type :=
        msg_pkg.get_object_name(p_object_name => p_queue_name, p_what => 'queue', p_schema_name => c_schema);
      l_default_processing_method constant t_processing_method :=
        msg_constants_pkg.get_default_processing_method;
    begin
      for r in
      ( select  location_name
        from    ( select  sr.location_name
                  ,       "plsql://" as protocol
                  from    user_subscr_registrations sr -- at most 1
                  where   sr.location_name like "plsql://" || '%'
                  and     ( sr.subscription_name = l_fq_queue_name or
                            sr.subscription_name like l_fq_queue_name || ':%' -- with a subscriber
                          )
                  and     sr.location_name = c_default_notification_processing_method        
                  union
                  select  l_default_processing_method as location_name
                  ,       "package://" as protocol
                  from    user_scheduler_job_args sja -- at most 1
                  where   sja.job_name like $$PLSQL_UNIT || '$PROCESSING_SUPERVISOR' -- e.g. MSG_AQ_PKG$PROCESSING_SUPERVISOR
                  and     sja.argument_name = 'P_GROUPS_TO_PROCESS_LIST'
                  and     sja.value is not null -- value is a comma separated list of queue names
                  and     instr(','||p_queue_name||',', ','||sja.value||',') > 0
                          -- When the default processing method is (no longer) the scheduler package,
                          -- it will not be an active queue processing method.
                  and     l_default_processing_method = c_default_scheduler_processing_method
                  order by
                          protocol -- "package://" before "plsql://" as it should
                )
$if not msg_aq_pkg.c_use_default_notification_processing_method $then
        where   rownum = 1
$end        
      )
      loop
        g_previous_processing_method_tab(p_queue_name).extend(1);
        g_previous_processing_method_tab(p_queue_name)(g_previous_processing_method_tab(p_queue_name).last) := r.location_name;
      end loop;
    end; 
  end if;

  if not g_previous_processing_method_tab.exists(p_queue_name)
  then
    raise program_error;
  end if;

  l_previous_processing_method1 :=
    case
      when g_previous_processing_method_tab(p_queue_name).count >= 1
      then g_previous_processing_method_tab(p_queue_name)(1)
    end;
$if msg_aq_pkg.c_use_default_notification_processing_method $then  
  l_previous_processing_method2 :=
    case
      when g_previous_processing_method_tab(p_queue_name).count >= 2
      then g_previous_processing_method_tab(p_queue_name)(2)
    end;
$end    

  if ( p_default_processing_method is null and l_previous_processing_method1 is null )
     or
     ( p_default_processing_method = l_previous_processing_method1
$if msg_aq_pkg.c_use_default_notification_processing_method $then  
       and
       ( ( l_previous_processing_method1 = c_default_notification_processing_method
           and
           l_previous_processing_method2 is null
         ) or
         ( l_previous_processing_method1 = c_default_scheduler_processing_method
           and
           l_previous_processing_method2 = c_default_notification_processing_method -- extra
         )
       )
$end           
     )
  then
    null; -- OK, no change
  else
    -- do not use "NOT IN (l_previous_processing_method1, l_previous_processing_method2)" since when one of those is NULL you do not get what you want
    if c_default_notification_processing_method in ( l_previous_processing_method1
$if msg_aq_pkg.c_use_default_notification_processing_method $then  
                                                   , l_previous_processing_method2
$end                                                   
                                                   )
       and
       p_default_processing_method is null
    then
      -- c_default_notification_processing_method has already been registered: unregister it
      -- must unregister this old processing method first
      PRAGMA INLINE (get_subscriber, 'YES');
      l_subscriber := get_subscriber;

      unregister_at
      ( p_queue_name => p_queue_name
      , p_subscriber => l_subscriber
      , p_plsql_callback => replace(c_default_notification_processing_method, "plsql://")
      );

      if l_subscriber is not null
      then
        remove_subscriber_at
        ( p_queue_name => p_queue_name
        , p_subscriber => l_subscriber
        );
      end if;
    end if;
    
    -- clear the previous processing method(s), see NOTE below
    g_previous_processing_method_tab(p_queue_name) := c_empty_processing_method_tab;
  end if;

  if g_previous_processing_method_tab(p_queue_name).count = 0 -- NOTE: no previous processing methods or not the same
  then
$if msg_aq_pkg.c_debugging >= 2 $then
    dbug.print
    ( dbug."info"
    , 'adding default processing method %s'
    , p_default_processing_method
    );
$end

    if p_default_processing_method is not null -- hence no unregister
    then
      g_previous_processing_method_tab(p_queue_name).extend(1);
      g_previous_processing_method_tab(p_queue_name)(g_previous_processing_method_tab(p_queue_name).last) := p_default_processing_method;

$if msg_aq_pkg.c_use_default_notification_processing_method $then  
      -- add extra processing method?
      if p_default_processing_method != c_default_notification_processing_method
      then
        g_previous_processing_method_tab(p_queue_name).extend(1);
        g_previous_processing_method_tab(p_queue_name)(g_previous_processing_method_tab(p_queue_name).last) := c_default_notification_processing_method;
      end if;
$end      

      -- do not use "NOT IN (X, Y, Z)" since when one of those is NULL you do not get what you want
      if c_default_notification_processing_method in ( l_previous_processing_method1
$if msg_aq_pkg.c_use_default_notification_processing_method $then  
                                                     , l_previous_processing_method2
$end                                                     
                                                     )
      then
        null; -- c_default_notification_processing_method has already been registered (and not unregistered)
      elsif g_previous_processing_method_tab(p_queue_name)(g_previous_processing_method_tab(p_queue_name).last) = c_default_notification_processing_method
      then
        -- register c_default_notification_processing_method
        PRAGMA INLINE (get_subscriber, 'YES');
        l_subscriber := get_subscriber;
        
        -- add default subscriber for a multiple consumer queue table
        if l_subscriber is not null
        then
          add_subscriber_at
          ( p_queue_name => p_queue_name
          , p_subscriber => l_subscriber
          );
        end if;

        register_at
        ( p_queue_name => p_queue_name
        , p_subscriber => l_subscriber
        , p_plsql_callback => replace(c_default_notification_processing_method, "plsql://")
        );
      end if;
    end if;

    -- restart the jobs when anoything has changed:
    -- A) when the new processing method is c_default_scheduler_processing_method (one queue more to process)
    -- B) when a previous processing method is c_default_scheduler_processing_method (one queue less to process)
    if c_default_scheduler_processing_method in ( /* A */ p_default_processing_method
                                                , /* B1 */ l_previous_processing_method1
$if msg_aq_pkg.c_use_default_notification_processing_method $then  
                                                , /* B2 */ l_previous_processing_method2
$end                                                
                                                )
    then
      run_processing_method
      ( c_default_scheduler_processing_method
      , 'restart'
      );
    end if;
  end if;

$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.leave;
$end
end ensure_queue_gets_dequeued;

procedure listen
( p_agent_list in dbms_aq.aq$_agent_list_t
, p_wait in naturaln
, p_agent out nocopy sys.aq$_agent
, p_message_delivery_mode out nocopy pls_integer
)
is
$if msg_aq_pkg.c_debugging >= 1 $then    
  l_agent_list_descr varchar2(4000 byte) := null;
$end    
begin
  -- Use dbug.enter/dbug.leave to be able to profile this dbms_aq.listen call.
$if msg_aq_pkg.c_debugging >= 1 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'LISTEN');
$end

$if msg_aq_pkg.c_debugging >= 1 $then
  if p_agent_list.count > 0
  then
    for i_idx in p_agent_list.first .. p_agent_list.last
    loop
      l_agent_list_descr :=
        case when i_idx > p_agent_list.first then l_agent_list_descr || ', ' end ||
        '#' || to_char(i_idx) || ':' || p_agent_list(i_idx).address;
    end loop;
  end if;
  dbug.print(dbug."info", 'agent list: %s', l_agent_list_descr);
$end

  dbms_aq.listen
  ( agent_list => p_agent_list
  , wait => p_wait
  , listen_delivery_mode => case when msg_aq_pkg.c_buffered_messaging then dbms_aq.persistent_or_buffered else dbms_aq.persistent end
  , agent => p_agent
  , message_delivery_mode => p_message_delivery_mode
  );

$if msg_aq_pkg.c_debugging >= 1 $then
  dbug.print
  ( dbug."output"
  , 'p_agent.address: %s; p_message_delivery_mode: %s'
  , p_agent.address
  , delivery_mode_descr(p_message_delivery_mode)
  );
  dbug.leave;
$end
exception
  when e_listen_timeout -- normal exception
  then
    p_agent.address := null;
$if msg_aq_pkg.c_debugging >= 1 $then
    dbug.print(dbug."warning", 'listen timeout');
    dbug.leave;
$end
            
$if msg_aq_pkg.c_debugging >= 1 $then
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end listen;

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
$if msg_aq_pkg.c_debugging >= 2 $then
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

$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.leave;
$end
end create_queue_table;

procedure drop_queue_table
( p_force in boolean
)
is
  l_fq_queue_name varchar2(1000 char);
begin
$if msg_aq_pkg.c_debugging >= 2 $then
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

$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.leave;
$end
end drop_queue_table;

procedure create_queue
( p_queue_name in varchar2
, p_comment in varchar2
, p_max_retries in naturaln
, p_retry_delay in naturaln
, p_retention_time in naturaln
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CREATE_QUEUE');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_comment: %s; p_max_retries: %s; p_retry_delay: %s; p_retention_time: %s'
  , p_queue_name
  , p_comment
  , p_max_retries
  , p_retry_delay
  , p_retention_time
  );
$end

  <<try_loop>>
  for i_try in 1..2
  loop
    begin
$if msg_aq_pkg.c_debugging >= 2 $then
      dbug.print(dbug."info", 'create queue; try # %s', i_try);
$end      
      dbms_aqadm.create_queue
      ( queue_name => l_queue_name
      , queue_table => c_queue_table
      , queue_type => dbms_aqadm.normal_queue
      , max_retries => p_max_retries
      , retry_delay => p_retry_delay
      , retention_time => p_retention_time
      , comment => p_comment
      );
      exit try_loop;
    exception
      when e_queue_table_does_not_exist
      then
$if msg_aq_pkg.c_debugging >= 2 $then
        dbug.on_error;
$end      
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

$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end create_queue;

procedure drop_queue
( p_queue_name in varchar2
, p_force in boolean
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if msg_aq_pkg.c_debugging >= 2 $then
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

$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.leave;
$end
end drop_queue;

procedure start_queue
( p_queue_name in varchar2
, p_enqueue in boolean
, p_dequeue in boolean
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.START_QUEUE');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_enqueue: %s; p_dequeue: %s'
  , p_queue_name
  , dbug.cast_to_varchar2(p_enqueue)
  , dbug.cast_to_varchar2(p_dequeue)
  );
$end

  dbms_aqadm.start_queue
  ( queue_name => l_queue_name
  , enqueue => p_enqueue
  , dequeue => p_dequeue
  );

$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.leave;
$end
end start_queue;

procedure empty_queue
( p_queue_name in varchar2
, p_dequeue_and_process in boolean
)
is
  pragma autonomous_transaction;
  
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
  l_msgid raw(16);
  l_message_properties dbms_aq.message_properties_t;
  l_msg msg_typ;
begin
$if msg_aq_pkg.c_debugging >= 1 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.EMPTY_QUEUE');
  dbug.print(dbug."input", 'p_queue_name: %s', p_queue_name);
$end

  -- the loop should end by a dequeue timeout
  loop
    if p_dequeue_and_process
    then
      dequeue_and_process
      ( p_queue_name => l_queue_name
      , p_delivery_mode => null
      , p_visibility => null
      , p_subscriber => null
      , p_dequeue_mode => dbms_aq.remove
      , p_navigation => dbms_aq.next_message
      , p_wait => 0
      , p_correlation => null
      , p_deq_condition => null
      , p_force => false
      , p_commit => true
      , p_batch_size => 100
      );
    else
      -- reset in/out parameter
      l_msgid := null;
      dequeue
      ( p_queue_name => l_queue_name
      , p_delivery_mode => null
      , p_visibility => null
      , p_subscriber => null
      , p_dequeue_mode => dbms_aq.remove
      , p_navigation => dbms_aq.next_message
      , p_wait => 0
      , p_correlation => null
      , p_deq_condition => null
      , p_force => false
      , p_msgid => l_msgid
      , p_message_properties => l_message_properties
      , p_msg => l_msg
      );
      commit;
    end if;
  end loop;

  commit;

$if msg_aq_pkg.c_debugging >= 1 $then
  dbug.leave;
$end
exception
  when e_dequeue_timeout
  then
    rollback;
    
$if msg_aq_pkg.c_debugging >= 1 $then
    dbug.leave;
$end
    null; -- normal behaviour
    
$if msg_aq_pkg.c_debugging >= 1 $then
  when others
  then
    rollback;
    dbug.leave_on_error;
    raise;
$end
end empty_queue;

procedure stop_queue
( p_queue_name in varchar2
, p_wait in boolean
, p_enqueue in boolean
, p_dequeue in boolean
)
is
  l_queue_name constant all_queues.name%type := oracle_tools.data_api_pkg.dbms_assert$simple_sql_name(p_queue_name, 'queue');
begin
$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.STOP_QUEUE');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_waits: %s; p_enqueue: %s; p_dequeue: %s'
  , p_queue_name
  , dbug.cast_to_varchar2(p_wait)
  , dbug.cast_to_varchar2(p_enqueue)
  , dbug.cast_to_varchar2(p_dequeue)
  );
$end

  dbms_aqadm.stop_queue
  ( queue_name => l_queue_name
  , enqueue => p_enqueue
  , dequeue => p_dequeue
  , wait => p_wait
  );

$if msg_aq_pkg.c_debugging >= 2 $then
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
$if msg_aq_pkg.c_debugging >= 2 $then
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
  
$if msg_aq_pkg.c_debugging >= 2 $then
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
$if msg_aq_pkg.c_debugging >= 2 $then
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
  
$if msg_aq_pkg.c_debugging >= 2 $then
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
$if msg_aq_pkg.c_debugging >= 2 $then
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

$if msg_aq_pkg.c_debugging >= 2 $then
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
begin
$if msg_aq_pkg.c_debugging >= 2 $then
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

$if msg_aq_pkg.c_debugging >= 2 $then
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
begin
$if msg_aq_pkg.c_debugging >= 2 $then
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
$if msg_pkg.c_debugging >= 2 $then
  p_msg.print();
$end  
$end

  if ( p_delivery_mode = dbms_aq.persistent and p_visibility = dbms_aq.on_commit ) -- option 1 from the spec
  or ( msg_aq_pkg.c_buffered_messaging and
       p_delivery_mode = dbms_aq.buffered   and p_visibility = dbms_aq.immediate ) -- option 2 from the spec
  or ( p_delivery_mode = dbms_aq.persistent and p_visibility = dbms_aq.immediate ) -- option 3 from the spec
  then 
    l_enqueue_options.delivery_mode := p_delivery_mode;
    l_enqueue_options.visibility := p_visibility;
  else
    l_enqueue_options.delivery_mode := dbms_aq.persistent;
    l_enqueue_options.visibility := dbms_aq.on_commit;

    if msg_aq_pkg.c_buffered_messaging and p_msg.has_not_null_lob() = 0
    then
      -- prefer buffered messages
      l_enqueue_options.delivery_mode := dbms_aq.buffered;
      l_enqueue_options.visibility := dbms_aq.immediate;
    end if;

    -- give a warning when the input parameters were not default and not a correct combination

$if msg_aq_pkg.c_debugging >= 2 $then
    if ( p_delivery_mode is not null or p_visibility is not null )
    then
      dbug.print
      ( dbug."warning"
      , 'msg_aq_pkg.c_buffered_messaging: %s; delivery mode: %s => %s; visibility: %s => %s'
      , dbug.cast_to_varchar2(msg_aq_pkg.c_buffered_messaging)
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

$if msg_aq_pkg.c_debugging >= 2 $then
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
$if msg_aq_pkg.c_debugging >= 2 $then
    dbug.print(dbug."info", 'enqueue; try # %s', i_try);
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
$if msg_aq_pkg.c_debugging >= 2 $then
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
  
      when e_enqueue_disabled
      then
$if msg_aq_pkg.c_debugging >= 2 $then
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

  /*
  -- Always ensure that a message can get dequeued (not counting for queue stopped).
  -- This caters for the event that a default processing method has changed along the way.
  */
  ensure_queue_gets_dequeued(p_msg.default_processing_method(), l_queue_name);

$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.print(dbug."output", 'p_msgid: %s', rawtohex(p_msgid));
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end enqueue;

procedure enqueue_array
( p_msg_tab in msg_tab_typ -- the messages
, p_visibility in binary_integer default dbms_aq.on_commit -- dbms_aq.on_commit or dbms_aq.immediate
, p_array_size in binary_integer default null
, p_correlation_tab in sys.odcivarchar2list default null
, p_force in boolean default true -- When true, queue tables, queues, subscribers and notifications will be created/added if necessary
, p_msgid_tab out nocopy dbms_aq.msgid_array_t
)
is
  l_queue_name constant user_queues.name%type := get_queue_name(p_msg_tab(p_msg_tab.first));
  l_enqueue_enabled user_queues.enqueue_enabled%type;
  l_dequeue_enabled user_queues.dequeue_enabled%type;
  l_enqueue_options dbms_aq.enqueue_options_t;
  l_message_properties dbms_aq.message_properties_t;
  l_message_properties_tab dbms_aq.message_properties_array_t := dbms_aq.message_properties_array_t();
  l_dummy pls_integer;
  
  c_max_tries constant simple_integer := case when p_force then 2 else 1 end;
begin
$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.ENQUEUE_ARRAY');
  dbug.print
  ( dbug."input"  
  , 'queue name: %s; p_visibility: %s; p_array_size: %s; p_force: %s'
  , l_queue_name
  , visibility_descr(p_visibility)
  , p_array_size
  , dbug.cast_to_varchar2(p_force)
  );
$end

  -- check
  case p_visibility
    when dbms_aq.on_commit then null;
    when dbms_aq.immediate then null;
  end case;

  l_enqueue_options.delivery_mode := dbms_aq.persistent;
  l_enqueue_options.visibility := p_visibility;

  l_message_properties.delay := dbms_aq.no_delay;
  l_message_properties.expiration := dbms_aq.never;
    
  for i_idx in 1 .. p_msg_tab.count
  loop
    l_message_properties.correlation :=
      case
        when p_correlation_tab is not null
         and i_idx <= p_correlation_tab.count
        then p_correlation_tab(i_idx)
      end;
      
    l_message_properties_tab.extend(1);
    l_message_properties_tab(i_idx) := l_message_properties;
  end loop;

  <<try_loop>>
  for i_try in 1 .. c_max_tries
  loop
$if msg_aq_pkg.c_debugging >= 2 $then
    dbug.print(dbug."info", 'enqueue array; try # %s', i_try);
$end    
    begin
      l_dummy :=
        dbms_aq.enqueue_array
        ( queue_name => l_queue_name
        , enqueue_options => l_enqueue_options
        , array_size => nvl(p_array_size, p_msg_tab.count)
        , message_properties_array => l_message_properties_tab
        , payload_array => p_msg_tab
        , msgid_array => p_msgid_tab
        );
      exit try_loop; -- enqueue succeeded
    exception
      when e_queue_does_not_exist or e_fq_queue_does_not_exist
      then
$if msg_aq_pkg.c_debugging >= 2 $then
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
  
      when e_enqueue_disabled
      then
$if msg_aq_pkg.c_debugging >= 2 $then
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

  /*
  -- Always ensure that a message can get dequeued (not counting for queue stopped).
  -- This caters for the event that a default processing method has changed along the way.
  */
  if p_msg_tab.first is not null
  then
    ensure_queue_gets_dequeued(p_msg_tab(p_msg_tab.first).default_processing_method(), l_queue_name);
$if msg_aq_pkg.c_debugging >= 2 $then
    for i_idx in p_msgid_tab.first .. p_msgid_tab.last
    loop
      dbug.print(dbug."info", 'message # %s enqueued with msgid %s', i_idx, rawtohex(p_msgid_tab(i_idx)));
    end loop;
$end    
  end if;  

$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end enqueue_array;

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
$if msg_aq_pkg.c_debugging >= 1 $then
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
  or ( msg_aq_pkg.c_buffered_messaging and
       p_delivery_mode = dbms_aq.buffered               and p_visibility = dbms_aq.immediate ) -- option 2 from the spec
  or ( p_delivery_mode = dbms_aq.persistent             and p_visibility = dbms_aq.immediate ) -- option 3 from the spec
  or ( msg_aq_pkg.c_buffered_messaging and
       p_delivery_mode = dbms_aq.persistent_or_buffered and p_visibility = dbms_aq.immediate ) -- option 4 from the spec
  then 
    l_dequeue_options.delivery_mode := p_delivery_mode;
    l_dequeue_options.visibility := p_visibility;
  else
    -- Visibility must always be IMMEDIATE when dequeuing messages with delivery mode DBMS_AQ.BUFFERED or DBMS_AQ.PERSISTENT_OR_BUFFERED
    case
      -- try to preserve at least one of the input settings
      when msg_aq_pkg.c_buffered_messaging and
           p_delivery_mode in (dbms_aq.buffered, dbms_aq.persistent_or_buffered)
      then
        l_dequeue_options.delivery_mode := p_delivery_mode;
        l_dequeue_options.visibility := dbms_aq.immediate;

      when p_visibility in (dbms_aq.on_commit, dbms_aq.immediate)
      then
        l_dequeue_options.delivery_mode := dbms_aq.persistent;
        l_dequeue_options.visibility := p_visibility;
      
      else
        l_dequeue_options.delivery_mode := dbms_aq.persistent;
        l_dequeue_options.visibility := dbms_aq.on_commit;
    end case;

    -- give a warning when the input parameters were not default and not a correct combination

$if msg_aq_pkg.c_debugging >= 1 $then
    if ( p_delivery_mode is not null or p_visibility is not null )
    then
      dbug.print
      ( dbug."warning"
      , 'msg_aq_pkg.c_buffered_messaging: %s; delivery mode: %s => %s; visibility: %s => %s'
      , dbug.cast_to_varchar2(msg_aq_pkg.c_buffered_messaging)
      , delivery_mode_descr(p_delivery_mode)
      , delivery_mode_descr(l_dequeue_options.delivery_mode)
      , visibility_descr(p_visibility)
      , visibility_descr(l_dequeue_options.visibility)
      );
    end if;
$end
  end if;  

$if msg_aq_pkg.c_debugging >= 1 $then
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
$if msg_aq_pkg.c_debugging >= 1 $then
      dbug.print(dbug."info", 'dequeue; try # %s', i_try);
$end
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
$if msg_aq_pkg.c_debugging >= 1 $then
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
      when e_dequeue_disabled
      then
$if msg_aq_pkg.c_debugging >= 1 $then
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
    end;
  end loop try_loop;  

$if msg_aq_pkg.c_debugging >= 1 $then
  dbug.print(dbug."output", 'p_msgid: %s', rawtohex(p_msgid));
$if msg_pkg.c_debugging >= 2 $then
  p_msg.print();
$end  
  dbug.leave;
$end

exception
  when e_dequeue_timeout
  then
$if msg_aq_pkg.c_debugging >= 1 $then
    dbug.print(dbug."warning", 'dequeue timeout');
    dbug.leave;
$end
    raise;
    
$if msg_aq_pkg.c_debugging >= 1 $then
  when others
  then
    dbug.leave_on_error;
    raise;
$end    
end dequeue;

procedure dequeue_array
( p_queue_name in varchar2 -- Can be fully qualified (including schema).
, p_visibility in binary_integer
, p_subscriber in varchar2
, p_array_size in binary_integer
, p_dequeue_mode in binary_integer
, p_navigation in binary_integer
, p_wait in binary_integer
, p_correlation in varchar2
, p_deq_condition in varchar2
, p_force in boolean
, p_msgid_tab out nocopy dbms_aq.msgid_array_t
, p_message_properties_tab out nocopy dbms_aq.message_properties_array_t
, p_msg_tab out nocopy msg_tab_typ
)
is
  -- NOTE: there are rumours that dbms_aq.dequeue_array may return duplicate msg ids
  l_msgid varchar2(4000 byte);  
  type t_msgid_lookup_tab is table of boolean index by l_msgid%type;
  l_msgid_lookup_tab t_msgid_lookup_tab;
  
  l_queue_name constant user_queues.name%type := simple_queue_name(p_queue_name);
  l_dequeue_options dbms_aq.dequeue_options_t;
  l_dummy pls_integer;
  
  c_max_tries constant simple_integer := case when p_force then 2 else 1 end;
begin
$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DEQUEUE_ARRAY');
  dbug.print
  ( dbug."input"
  , 'queue name: %s; p_visibility: %s; p_subscriber: %s; p_dequeue_mode: %s'
  , l_queue_name
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
$end

  -- check
  case p_visibility
    when dbms_aq.on_commit then null;
    when dbms_aq.immediate then null;
  end case;

  l_dequeue_options.consumer_name := p_subscriber;
  l_dequeue_options.dequeue_mode := p_dequeue_mode;
  l_dequeue_options.navigation := p_navigation;
  l_dequeue_options.wait := p_wait;
  l_dequeue_options.correlation := p_correlation;
  l_dequeue_options.deq_condition := p_deq_condition;
  
  l_dequeue_options.delivery_mode := dbms_aq.persistent;
  l_dequeue_options.visibility := p_visibility;

  <<try_loop>>
  for i_try in 1 .. c_max_tries
  loop
$if msg_aq_pkg.c_debugging >= 2 $then
    dbug.print(dbug."info", 'dequeue array; try # %s', i_try);
$end    
    begin
      l_dummy :=
        dbms_aq.dequeue_array
        ( queue_name => l_queue_name
        , dequeue_options => l_dequeue_options
        , array_size => p_array_size
        , message_properties_array => p_message_properties_tab
        , payload_array => p_msg_tab
        , msgid_array => p_msgid_tab
        );
      exit try_loop; -- enqueue succeeded
    exception
      when e_queue_does_not_exist or e_fq_queue_does_not_exist
      then
$if msg_aq_pkg.c_debugging >= 2 $then
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
      when e_dequeue_disabled
      then
$if msg_aq_pkg.c_debugging >= 2 $then
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
    end;
  end loop try_loop;  

  -- see NOTE above
  if p_msgid_tab.count > 0
  then
    for i_idx in p_msgid_tab.first .. p_msgid_tab.last
    loop
      l_msgid := rawtohex(p_msgid_tab(i_idx));
      if not l_msgid_lookup_tab.exists(l_msgid)
      then
        l_msgid_lookup_tab(l_msgid) := null;
      else
        p_msg_tab(i_idx) := null;
        p_msgid_tab(i_idx) := null;
      end if;
    end loop;
  end if;

$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end dequeue_array;

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
, p_batch_size in binary_integer
)
is
  l_nr_msgs_dequeued natural;
  l_dequeue_elapsed_time oracle_tools.api_time_pkg.seconds_t;
  l_nr_msgs_processed natural;
  l_process_elapsed_time oracle_tools.api_time_pkg.seconds_t;
begin
  dequeue_and_process
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
  , p_commit => p_commit
  , p_batch_size => p_batch_size
  , p_nr_msgs_dequeued => l_nr_msgs_dequeued
  , p_dequeue_elapsed_time => l_dequeue_elapsed_time
  , p_nr_msgs_processed => l_nr_msgs_processed
  , p_process_elapsed_time => l_process_elapsed_time
  );
end dequeue_and_process;

procedure dequeue_and_process
( p_queue_name in varchar2 -- Can be fully qualified (including schema).
, p_delivery_mode in binary_integer
, p_visibility in binary_integer
, p_subscriber in varchar2
, p_dequeue_mode in binary_integer default dbms_aq.remove
, p_navigation in binary_integer default dbms_aq.next_message
, p_wait in binary_integer default dbms_aq.forever
, p_correlation in varchar2 default null
, p_deq_condition in varchar2 default null
, p_force in boolean default false -- When true, queue tables, queues will be created/added if necessary
, p_commit in boolean default true
, p_batch_size in binary_integer default 1 -- number of messages to dequeue in one batch
, p_nr_msgs_dequeued out nocopy natural
, p_dequeue_elapsed_time out nocopy oracle_tools.api_time_pkg.seconds_t
, p_nr_msgs_processed out nocopy natural
, p_process_elapsed_time out nocopy oracle_tools.api_time_pkg.seconds_t
)
is
  l_empty_message_properties dbms_aq.message_properties_t;
  -- array msg
  l_msgid_tab dbms_aq.msgid_array_t := dbms_aq.msgid_array_t(null);
  l_message_properties_tab dbms_aq.message_properties_array_t := dbms_aq.message_properties_array_t(l_empty_message_properties);
  l_msg_tab msg_tab_typ := msg_tab_typ(null);
  -- timing
  l_start_time oracle_tools.api_time_pkg.time_t := null;
begin
$if msg_aq_pkg.c_debugging >= 1 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DEQUEUE_AND_PROCESS (1)');
  dbug.print
  ( dbug."input"
  , 'p_queue_name: %s; p_delivery_mode: %s; p_visibility: %s; p_subscriber: %s; p_dequeue_mode: %s'
  , p_queue_name
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
  , 'p_commit: %s; p_batch_size: %s'
  , dbug.cast_to_varchar2(p_commit)
  , p_batch_size
  );
$end

  p_nr_msgs_dequeued := 0;
  p_dequeue_elapsed_time := null;
  p_nr_msgs_processed := 0;
  p_process_elapsed_time := null;

  l_start_time := oracle_tools.api_time_pkg.get_time;
  
  if p_batch_size = 1
  then
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
    , p_msgid => l_msgid_tab(1)
    , p_message_properties => l_message_properties_tab(1)
    , p_msg => l_msg_tab(1)
    );
    p_nr_msgs_dequeued := 1;
  else
    dequeue_array
    ( p_queue_name => p_queue_name
    , p_visibility => nvl(p_visibility, dbms_aq.on_commit)
    , p_subscriber => p_subscriber
    , p_array_size => p_batch_size
    , p_dequeue_mode => p_dequeue_mode
    , p_navigation => p_navigation
    , p_wait => p_wait
    , p_correlation => p_correlation
    , p_deq_condition => p_deq_condition
    , p_force => p_force
    , p_msgid_tab => l_msgid_tab
    , p_message_properties_tab => l_message_properties_tab
    , p_msg_tab => l_msg_tab
    );
    p_nr_msgs_dequeued := l_msg_tab.count;
  end if;

  p_dequeue_elapsed_time := oracle_tools.api_time_pkg.elapsed_time(l_start_time, oracle_tools.api_time_pkg.get_time);

  l_start_time := oracle_tools.api_time_pkg.get_time;

  if l_msg_tab is not null and l_msg_tab.count > 0
  then
    for i_idx in l_msg_tab.first .. l_msg_tab.last
    loop
      if l_msg_tab(i_idx) is not null
      then
$if msg_aq_pkg.c_debugging >= 1 $then
        dbug.print(dbug."info", 'about to process message # %s with msgid %s', i_idx, rawtohex(l_msgid_tab(i_idx)));
$end  
        msg_pkg.process_msg
        ( p_msg => l_msg_tab(i_idx)
        , p_commit => p_commit
        );
        p_nr_msgs_processed := p_nr_msgs_processed + 1;
      end if;
    end loop;
  end if;

  p_process_elapsed_time := oracle_tools.api_time_pkg.elapsed_time(l_start_time, oracle_tools.api_time_pkg.get_time);

$if msg_aq_pkg.c_debugging >= 1 $then
  dbug.print
  ( dbug."output"
  , 'p_nr_msgs_dequeued: %s; p_dequeue_elapsed_time: %s; p_nr_msgs_processed: %s; p_process_elapsed_time: %s'
  , p_nr_msgs_dequeued
  , p_dequeue_elapsed_time
  , p_nr_msgs_processed
  , p_process_elapsed_time
  );
  dbug.leave;
$end  
exception
  when e_dequeue_timeout
  then
$if msg_aq_pkg.c_debugging >= 1 $then
    dbug.leave;
$end
    raise;
    
$if msg_aq_pkg.c_debugging >= 1 $then
  when others
  then
    dbug.leave_on_error;
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
$if msg_aq_pkg.c_debugging >= 2 $then
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

$if msg_aq_pkg.c_debugging >= 2 $then
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
      case
        when msg_aq_pkg.c_buffered_messaging and
             p_descr.msg_prop.delivery_mode in ( dbms_aq.buffered, dbms_aq.persistent_or_buffered )
        then dbms_aq.immediate
        else dbms_aq.on_commit
      end
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

$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.print(dbug."output", 'p_msgid: %s', rawtohex(p_msgid));
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
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
$if msg_aq_pkg.c_debugging >= 2 $then
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

$if msg_aq_pkg.c_debugging >= 1 $then
  dbug.print(dbug."info", 'about to process message with msgid %s', rawtohex(l_msgid));
$end  
  msg_pkg.process_msg
  ( p_msg => l_msg
  , p_commit => p_commit
  );

$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
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
  l_fq_queue_name_tab sys.odcivarchar2list;
begin
$if msg_aq_pkg.c_debugging >= 2 $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.GET_GROUPS_TO_PROCESS');
  dbug.print(dbug."input", 'p_processing_method: %s', p_processing_method);
$end

  select  msg_pkg.get_object_name(p_object_name => q.name, p_what => 'queue') as fq_queue_name
  bulk collect
  into    l_fq_queue_name_tab  
  from    user_queues q
  where   q.queue_type = 'NORMAL_QUEUE'
  and     q.queue_table = trim('"' from c_queue_table)
  and     trim(q.dequeue_enabled) = 'YES'
$if not msg_aq_pkg.c_use_default_notification_processing_method $then  
  minus
  select  case
            when sr.subscription_name like '%:%'
            then substr(sr.subscription_name, 1, instr(sr.subscription_name, ':', -1) - 1)
            else sr.subscription_name
          end as fq_queue_name -- "OWNER"."QUEUE"
  from    user_subscr_registrations sr
$end  
  order by
          fq_queue_name;

$if msg_aq_pkg.c_debugging >= 2 $then

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
  
  if l_fq_queue_name_tab.count is not null and l_fq_queue_name_tab.count > 0
  then
    for i_idx in l_fq_queue_name_tab.first .. l_fq_queue_name_tab.last
    loop
      dbug.print(dbug."info", '[%s] normal queue open for dequeue: %s', i_idx, l_fq_queue_name_tab(i_idx));
    end loop;
  end if;

$end -- $if msg_aq_pkg.c_debugging >= 2 $then

  select  distinct
          t.group$
  bulk collect
  into    l_groups_to_process_tab
  from    ( select t.column_value as fq_queue_name from table(l_fq_queue_name_tab) t ) q
          inner join table(l_msg_tab) t
          on q.fq_queue_name = msg_pkg.get_object_name(p_object_name => msg_aq_pkg.get_queue_name(value(t)), p_what => 'queue')
  where   ( t.default_processing_method() = p_processing_method
$if not msg_aq_pkg.c_use_default_notification_processing_method $then
            or
            t.default_processing_method() like "plsql://" || '%'
$end            
          )
  and     t.group$ is not null;

$if msg_aq_pkg.c_debugging >= 2 $then
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
  -- In order to prevent starvation (i.e. you always get the first queue when all queues are ready),
  -- it is necesary to do a round-robin.
  type agent_list_by_group_t is table of dbms_aq.aq$_agent_list_t index by binary_integer; -- will start with index 0
  type t_batch_size_tab is table of binary_integer index by user_queues.name%type; -- batch size per queue
  
  l_agent_list_by_group agent_list_by_group_t;
  l_agent_list_by_group_idx natural := null;  
  l_start_date constant oracle_tools.api_time_pkg.timestamp_t := oracle_tools.api_time_pkg.get_timestamp;
  l_next_heartbeat oracle_tools.api_time_pkg.timestamp_t := l_start_date;
  l_now oracle_tools.api_time_pkg.timestamp_t;
  l_ttl constant positiven := oracle_tools.api_time_pkg.delta(l_start_date, p_end_date);
  l_elapsed_time oracle_tools.api_time_pkg.seconds_t := 0;
  l_queue_name_tab sys.odcivarchar2list := sys.odcivarchar2list();
  l_agent sys.aq$_agent :=
    sys.aq$_agent(null, get_queue_name(p_groups_to_process_tab(p_groups_to_process_tab.first)), null); -- no subscriber, just a queue address
  l_message_delivery_mode pls_integer := case when msg_aq_pkg.c_buffered_messaging then dbms_aq.persistent_or_buffered else dbms_aq.persistent end; -- when there is just one queue
  l_timestamp_tab oracle_tools.api_heartbeat_pkg.timestamp_tab_t;
  l_silent_worker_tab oracle_tools.api_heartbeat_pkg.silent_worker_tab_t;
  l_wait naturaln := 0;
  l_wait_orig naturaln := 0;
  l_navigation pls_integer;
  l_batch_size_tab t_batch_size_tab;
  l_nr_msgs_dequeued natural;
  l_dequeue_elapsed_time oracle_tools.api_time_pkg.seconds_t;
  l_nr_msgs_processed natural;
  l_process_elapsed_time oracle_tools.api_time_pkg.seconds_t;

  l_procedure constant varchar2(100) := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESSING';
  
  procedure init
  is
    l_agent_list dbms_aq.aq$_agent_list_t;
    l_queue_name_idx positiven := 1;
  begin
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

    <<agent_list_by_group_loop>>
    for agent_list_by_group_idx in 0 .. l_queue_name_tab.count - 1
    loop
      -- i_idx can be from
      -- a) 1 .. l_queue_name_tab.count     (<=> 1 .. l_queue_name_tab.count + (1) - 1)
      -- b) 2 .. l_queue_name_tab.count + 1 (<=> 2 .. l_queue_name_tab.count + (2) - 1)
      -- z) l_queue_name_tab.count .. l_queue_name_tab.count + (l_queue_name_tab.count) - 1
      <<agent_loop>>
      for i_idx in agent_list_by_group_idx + 1 ..
                   agent_list_by_group_idx + l_queue_name_tab.count
      loop
        l_queue_name_idx := mod(i_idx - 1, l_queue_name_tab.count) + 1; -- between 1 and l_queue_name_tab.count
        
        if l_queue_name_tab(l_queue_name_idx) is null
        then
          raise program_error;
        end if;

        -- assume single consumer queues
        l_agent_list(l_agent_list.count+1) :=
          sys.aq$_agent(null, l_queue_name_tab(l_queue_name_idx), null);

$if msg_aq_pkg.c_debugging >= 1 $then
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

        -- Only the last round we check that all queues have been used
        if agent_list_by_group_idx = l_queue_name_tab.count - 1
        then
          l_queue_name_tab(l_queue_name_idx) := null;
        end if;
      end loop agent_loop;
      l_agent_list_by_group(agent_list_by_group_idx) := l_agent_list;
      l_agent_list.delete;
    end loop agent_list_loop;
  end init;
  
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
        l_next_heartbeat := l_next_heartbeat + numtodsinterval(msg_constants_pkg.get_time_between_heartbeats, 'SECOND');
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
$if msg_aq_pkg.c_debugging >= 1 $then
  dbug.enter(l_procedure);
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

  init;
    
  <<process_loop>>
  loop
    l_navigation := dbms_aq.first_message;
    -- don't use 0 but 1 second as minimal timeout since 0 seconds may kill your server
    l_wait := least(msg_constants_pkg.get_time_between_heartbeats, greatest(1, trunc(l_ttl - l_elapsed_time)));
    l_wait_orig := l_wait;
    l_now := oracle_tools.api_time_pkg.get_timestamp;
    l_elapsed_time := oracle_tools.api_time_pkg.elapsed_time(l_start_date, l_now);

$if msg_aq_pkg.c_debugging >= 1 $then
    dbug.print
    ( dbug."info"
    , 'wait time: %s; elapsed time: %s (s); ttl: %s; finished (elapsed >= ttl)?: %s'
    , to_char(l_wait)
    , to_char(l_elapsed_time)
    , to_char(l_ttl)
    , dbug.cast_to_varchar2(l_elapsed_time >= l_ttl)
    );
$end

    /* Test whether we must end? */
    exit process_loop when l_elapsed_time >= l_ttl;

    /* Test whether we must send a heartbeat? */
    PRAGMA INLINE (send_next_heartbeat, 'YES');
    send_next_heartbeat;

    if l_agent.address is null
    then
      -- initialisation each listen and deqeueue round
      -- remember: round-robin fashion
      if l_agent_list_by_group_idx is null
      then
        l_agent_list_by_group_idx := mod(p_worker_nr - 1, l_queue_name_tab.count);
      else
        l_agent_list_by_group_idx := mod(l_agent_list_by_group_idx + 1, l_queue_name_tab.count);
      end if;

      PRAGMA INLINE (listen, 'YES');
      listen
      ( p_agent_list => l_agent_list_by_group(l_agent_list_by_group_idx)
      , p_wait => l_wait
      , p_agent => l_agent
      , p_message_delivery_mode => l_message_delivery_mode
      );    
    else
      <<dequeue_loop>>
      loop
        begin
$if msg_aq_pkg.c_debugging >= 1 $then
          dbug.print(dbug."info", 'trying to process a message from queue %s with timeout %s', l_agent.address, l_wait);
$end

          if not l_batch_size_tab.exists(l_agent.address)
          then
            l_batch_size_tab(l_agent.address) := 1;
          end if;
          
          msg_aq_pkg.dequeue_and_process
          ( p_queue_name => l_agent.address
          , p_delivery_mode => l_message_delivery_mode
          , p_visibility => dbms_aq.immediate
          , p_subscriber => l_agent.name
          , p_dequeue_mode => dbms_aq.remove
          , p_navigation => l_navigation -- may be better for performance when concurrent messages arrive
          -- Although a message should be there and a timeout of 0 should be okay, we will just specify a wait time of 1 second
          -- since I saw a few times time-outs here.
          , p_wait => l_wait
          , p_correlation => null
          , p_deq_condition => null
          , p_force => false -- queue should be there
          , p_commit => true
          , p_batch_size => l_batch_size_tab(l_agent.address)
          , p_nr_msgs_dequeued => l_nr_msgs_dequeued
          , p_dequeue_elapsed_time => l_dequeue_elapsed_time
          , p_nr_msgs_processed => l_nr_msgs_processed
          , p_process_elapsed_time => l_process_elapsed_time
          );

$if msg_aq_pkg.c_debugging >= 1 $then
          dbug.print(dbug."info", '%s message(s) processed', l_nr_msgs_processed);
$end

          exit dequeue_loop when l_nr_msgs_dequeued < l_batch_size_tab(l_agent.address);
          
          -- try to adjust the batch size in a smart way
          if l_nr_msgs_processed = l_batch_size_tab(l_agent.address)
          then
            l_batch_size_tab(l_agent.address) :=
              case
                -- it took more than the wait interval
                when l_dequeue_elapsed_time + l_process_elapsed_time > l_wait_orig
                then greatest(1, l_batch_size_tab(l_agent.address) - 1) -- must be > 0
                -- we have some more room within the wait interval
                else l_batch_size_tab(l_agent.address) + 1
              end;
$if msg_aq_pkg.c_debugging >= 1 $then
            dbug.print(dbug."info", 'batch size: %s => %s', l_nr_msgs_processed, l_batch_size_tab(l_agent.address));
$end
          end if;
            
          if l_wait != 0 -- first dequeue and process in this loop
          then
            l_navigation := dbms_aq.next_message;
            l_wait := 0;
          end if;
        exception
          when e_dequeue_timeout -- stop this loop and try again with listen first (if applicable)
          then
$if msg_aq_pkg.c_debugging >= 1 $then
            dbug.print(dbug."info", 'timeout while waiting for a message to process');
$end
            exit dequeue_loop;
        end;    
      end loop dequeue_loop;
    end if;
  end loop process_loop;

  cleanup;
  
$if msg_aq_pkg.c_debugging >= 1 $then
  dbug.print(dbug."info", 'Stopped processing messages after %s seconds', to_char(l_elapsed_time));
  dbug.leave;
$end  
exception
  when others
  then
    cleanup;
$if msg_aq_pkg.c_debugging >= 1 $then
    dbug.leave_on_error;
$end
    raise;
end processing;

end msg_aq_pkg;
/

