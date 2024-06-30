CREATE OR REPLACE PACKAGE BODY "MSG_SCHEDULER_PKG" AS

-- TYPEs

subtype job_name_t is user_scheduler_jobs.job_name%type;
subtype dbug_channel_tab_t is msg_pkg.boolean_lookup_tab_t;
--subtype job_info_rec_t is user_scheduler_jobs%rowtype;
subtype command_t is varchar2(4000 byte);

/*
--
-- Schedules
--
*/
type schedule_rec_t is record
( start_date user_scheduler_schedules.start_date%type
, repeat_interval user_scheduler_schedules.repeat_interval%type
, end_date user_scheduler_schedules.end_date%type
, comments user_scheduler_schedules.comments%type
);

-- key is schedule name
type schedule_tab_t is table of schedule_rec_t index by user_scheduler_schedules.schedule_name%type;

/*
--
-- Programs and their arguments
--
*/
type program_argument_rec_t is record
( argument_position user_scheduler_program_args.argument_position%type
, argument_type user_scheduler_program_args.argument_type%type
, default_value user_scheduler_program_args.default_value%type
);

-- key is program argument name
type program_argument_tab_t is table of program_argument_rec_t index by user_scheduler_program_args.argument_name%type;

type program_rec_t is record
( program_type user_scheduler_programs.program_type%type
, program_action user_scheduler_programs.program_action%type
, number_of_arguments user_scheduler_programs.number_of_arguments%type
, enabled boolean -- user_scheduler_programs.enabled%type
, comments user_scheduler_programs.comments%type
, program_arguments program_argument_tab_t
);

-- key is program name
type program_tab_t is table of program_rec_t index by user_scheduler_programs.program_name%type;

/*
--
-- Jobs and their arguments
--
*/
type job_argument_rec_t is record
( argument_value user_scheduler_job_args.value%type
);

-- key is job argument name
type job_argument_tab_t is table of job_argument_rec_t index by user_scheduler_job_args.argument_name%type;

type job_rec_t is record
( program_name user_scheduler_jobs.program_name%type
, schedule_name user_scheduler_jobs.schedule_name%type
, start_date user_scheduler_jobs.start_date%type
, repeat_interval user_scheduler_jobs.repeat_interval%type
, end_date user_scheduler_jobs.end_date%type
, enabled boolean -- user_scheduler_jobs.enabled%type
, auto_drop boolean -- user_scheduler_jobs.auto_drop%type
, comments user_scheduler_jobs.comments%type
, state user_scheduler_jobs.state%type default 'DISABLED' -- not filled by create_job
, job_arguments job_argument_tab_t
);

-- key is job name
type job_tab_t is table of job_rec_t index by user_scheduler_jobs.job_name%type;

-- CONSTANTs

"yyyymmddhh24miss" constant varchar2(16) := 'yyyymmddhh24miss';
"yyyy-mm-dd hh24:mi:ss" constant varchar2(40) := oracle_tools.api_time_pkg.c_timestamp_format; -- 'yyyy-mm-dd hh24:mi:ss';

-- let the launcher program (that is used for job names too) start with LAUNCHER so a wildcard search for worker group jobs does not return the launcher job
c_program_launcher constant user_scheduler_programs.program_name%type := 'PROCESSING_LAUNCHER';
c_program_supervisor constant user_scheduler_programs.program_name%type := 'PROCESSING_SUPERVISOR';
c_program_worker constant user_scheduler_programs.program_name%type := 'PROCESSING_WORKER';
c_program_do constant user_scheduler_programs.program_name%type := 'DO';

c_schedule_launcher constant user_scheduler_programs.program_name%type := 'SCHEDULE_LAUNCHER';

c_session_id constant user_scheduler_running_jobs.session_id%type := to_number(sys_context('USERENV', 'SID'));

-- check schedule related attributes
c_attribute_tab constant sys.odcivarchar2list :=
  sys.odcivarchar2list
  ( 'end_date'
  , 'schedule_name'
  , 'start_date'
  , 'repeat_interval'
  );

c_dry_run constant boolean := false;

-- VARIABLES

g_dry_run$ boolean := c_dry_run; -- only set it in the function do()
g_show_comments$ boolean := null;
g_processing_package$ all_objects.object_name%type := null;

g_commands sys.odcivarchar2list := sys.odcivarchar2list();

g_schedules schedule_tab_t;
g_programs program_tab_t;
g_jobs job_tab_t;

-- EXCEPTIONs

-- ORA-27476: "MSG_AQ_PKG$PROCESSING_LAUNCHER#1" does not exist
e_procobj_does_not_exist exception;
pragma exception_init(e_procobj_does_not_exist, -27476);

-- ORA-27477: "MSG_AQ_PKG$PROCESSING" already exists
e_procobj_already_exists exception;
pragma exception_init(e_procobj_already_exists, -27477);

-- ORA-27475: unknown job "BC_API"."MSG_AQ_PKG$PROCESSING_LAUNCHER#1"
e_job_unknown exception;
pragma exception_init(e_job_unknown, -27475);

-- ORA-27483: "MSG_AQ_PKG$PROCESSING" has an invalid END_DATE
e_invalid_end_date exception;
pragma exception_init(e_invalid_end_date, -27483);

-- ORA-27481: "MSG_AQ_PKG$PROCESSING" has an invalid schedule
e_invalid_schedule exception;
pragma exception_init(e_invalid_schedule, -27481);

-- ORA-27468: "MSG_AQ_PKG$PROCESSING" is locked by another process
e_procobj_locked exception;
pragma exception_init(e_procobj_locked, -27468);

-- ROUTINEs

procedure init
( p_dbug_channel_tab out nocopy dbug_channel_tab_t
)
is
$if oracle_tools.cfg_pkg.c_debugging $then
  l_dbug_channel_active_tab constant sys.odcivarchar2list := msg_constants_pkg.get_dbug_channel_active_tab;
  l_dbug_channel_inactive_tab constant sys.odcivarchar2list := msg_constants_pkg.get_dbug_channel_inactive_tab;
$end    
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  for i_idx in l_dbug_channel_active_tab.first .. l_dbug_channel_active_tab.last
  loop
    p_dbug_channel_tab(l_dbug_channel_active_tab(i_idx)) := dbug.active(l_dbug_channel_active_tab(i_idx));

    dbug.activate
    ( l_dbug_channel_active_tab(i_idx)
    , true
    );
  end loop;

  for i_idx in l_dbug_channel_inactive_tab.first .. l_dbug_channel_inactive_tab.last
  loop
    p_dbug_channel_tab(l_dbug_channel_inactive_tab(i_idx)) := dbug.active(l_dbug_channel_inactive_tab(i_idx));

    dbug.activate
    ( l_dbug_channel_inactive_tab(i_idx)
    , false
    );
  end loop;
$end

  msg_pkg.init;
end init;

function dyn_sql_parm(p_val in varchar2)
return varchar2
is
begin
  return case when p_val is null then 'null' else '''' || replace(p_val, '''', '''''') || '''' end;
end;

function dyn_sql_parm(p_val in number)
return varchar2
is
begin
  return case when p_val is null then 'null' else to_char(p_val) end;
end;

function dyn_sql_parm(p_val in boolean)
return varchar2
is
begin
  return case p_val when true then 'true' when false then 'false' else 'null' end;
end;  

function dyn_sql_parm(p_val in oracle_tools.api_time_pkg.timestamp_t)
return varchar2
is
begin
  return case
           when p_val is null
           then 'null'
           else utl_lms.format_message
                ( q'[oracle_tools.api_time_pkg.str2timestamp('%s')]'
                , oracle_tools.api_time_pkg.timestamp2str(p_val)
                )
         end;
end;

$if oracle_tools.cfg_pkg.c_debugging $then

procedure profiler_report
is
begin
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.' || 'PROFILER_REPORT');

  for r in
  ( select  t.module_name
    ,       t.nr_calls
    ,       t.elapsed_time
    ,       t.avg_time
    from    table(dbug_profiler.show) t
  )
  loop
    dbug.print
    ( dbug."info"
    , 'module: %s; # calls: %s, elapsed time: %s; avg_time: %s'
    , r.module_name
    , r.nr_calls
    , r.elapsed_time
    , r.avg_time
    );
  end loop;

  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    null; -- do not re-raise
end profiler_report;

$end -- $if oracle_tools.cfg_pkg.c_debugging $then

procedure done
( p_dbug_channel_tab in dbug_channel_tab_t
)
is
$if oracle_tools.cfg_pkg.c_debugging $then
  l_dbug_channel all_objects.object_name%type := p_dbug_channel_tab.first;
$end  
begin
$if oracle_tools.cfg_pkg.c_debugging $then
/* GJP 2023-03-13 Getting dbug errors. */
--/*
  if dbug.active('PROFILER')
  then
    profiler_report;
  end if;
--*/  
$end  

  msg_pkg.done;

$if oracle_tools.cfg_pkg.c_debugging $then
/* GJP 2023-03-13 Do not change dbug settings anymore. */
--/*
  while l_dbug_channel is not null
  loop
    dbug.activate(l_dbug_channel, p_dbug_channel_tab(l_dbug_channel));
    
    l_dbug_channel := p_dbug_channel_tab.next(l_dbug_channel);
  end loop;
--*/  
$end -- $if oracle_tools.cfg_pkg.c_debugging $then  
end done;

function join_job_name
( p_processing_package in varchar2
, p_program_name in varchar2
, p_worker_nr in positive default null
, p_check in boolean default true
)
return job_name_t
is
  l_job_name job_name_t;
begin
  if p_check and
     ( ( p_program_name = c_program_worker and p_worker_nr is null ) or
       ( p_program_name <> c_program_worker and p_worker_nr is not null ) )
  then
    raise program_error;
  end if;

  l_job_name :=
    p_processing_package ||
    '$' ||
    p_program_name ||
    case when p_worker_nr is not null then '#' || to_char(p_worker_nr) end;

$if oracle_tools.cfg_pkg.c_debugging and msg_scheduler_pkg.c_debugging >= 2 $then
  dbug.print(dbug."info", 'join_job_name: %s', l_job_name);
$end

  return l_job_name;
end join_job_name;

procedure split_job_name
( p_job_name in job_name_t
, p_processing_package out nocopy varchar2
, p_program_name out nocopy varchar2
, p_worker_nr out nocopy positive
)
is
  l_pos$ pls_integer;
  l_pos# pls_integer;
begin
  p_processing_package := null;
  p_program_name := null;
  p_worker_nr := null;
  
  l_pos$ := instr(p_job_name, '$'); -- first $
  if l_pos$ > 0
  then
    p_processing_package := substr(p_job_name, 1, l_pos$ - 1);
    p_program_name := substr(p_job_name, l_pos$ + 1); -- rest of the job name
    
    l_pos# := instr(p_program_name, '#'); -- first #
    case
      when l_pos# is null -- p_program_name is null
      then
        null;
        
      when l_pos# = 0
      then
        null;
        
      when l_pos# > 0
      then
        p_worker_nr := to_number(substr(p_program_name, l_pos# + 1));
        p_program_name := substr(p_program_name, 1, l_pos# - 1);
    end case;
  end if;

  if ( p_program_name = c_program_worker and p_worker_nr is null ) or
     ( p_program_name <> c_program_worker and p_worker_nr is not null )
  then
    raise program_error;
  end if;

$if oracle_tools.cfg_pkg.c_debugging and msg_scheduler_pkg.c_debugging >= 2 $then
  dbug.print
  ( dbug."info"
  , q'[split_job_name(p_job_name => %s, p_processing_package => %s, p_program_name => %s, p_worker_nr => %s)]'
  , dyn_sql_parm(p_job_name)
  , dyn_sql_parm(p_processing_package)
  , dyn_sql_parm(p_program_name)
  , dyn_sql_parm(p_worker_nr)
  );
$end  

end split_job_name;

function to_like_expr
( p_expr in varchar2
)
return varchar2
is
  l_expr constant varchar2(4000 char) := replace(replace(p_expr, '_', '\_'), '\\_', '\_');
begin
  return l_expr;
end to_like_expr;

function get_jobs
( p_job_name_expr in varchar2
, p_state in user_scheduler_jobs.state%type default null
)
return sys.odcivarchar2list
is
  l_job_names sys.odcivarchar2list;
  l_job_name_expr constant job_name_t := to_like_expr(p_job_name_expr);
  l_job_name job_name_t;
begin
  if g_dry_run$
  then
    l_job_names := sys.odcivarchar2list(); -- no jobs
    l_job_name := g_jobs.first;
    while l_job_name is not null
    loop
      if l_job_name like l_job_name_expr escape '\'
         and
         ( p_state is null or g_jobs(l_job_name).state = p_state )
      then
        l_job_names.extend(1);
        l_job_names(l_job_names.last) := l_job_name;
      end if;
      l_job_name := g_jobs.next(l_job_name);
    end loop;

    -- order them
    select  j.column_value as job_name
    bulk collect
    into    l_job_names
    from    table(l_job_names) j
    order by
            job_name -- permanent launcher first, then its workers jobs, next temporary launchers and their workers
    ;

  else
    select  j.job_name
    bulk collect
    into    l_job_names
    from    user_scheduler_jobs j
    where   j.job_name like l_job_name_expr escape '\'
    and     ( p_state is null or j.state = p_state )
    order by
            job_name -- permanent launcher first, then its workers jobs, next temporary launchers and their workers
    ;
  end if;

  return l_job_names;
end get_jobs;

$if oracle_tools.cfg_pkg.c_debugging $then

procedure show_jobs
is
begin
  for r in
  ( select  j.job_name
    ,       j.state
    ,       j.enabled
    from    user_scheduler_jobs j
    order by
            job_name
  )
  loop
    dbug.print(dbug."info", 'all jobs; job name: %s; state: %s; enabled: %s', r.job_name, r.state, r.enabled);
  end loop;

  for r in
  ( select  j.job_name
    from    user_scheduler_running_jobs j
    order by
            job_name
  )
  loop
    dbug.print(dbug."info", 'all running jobs; job name: %s', r.job_name);
  end loop;

  dbug.print
  ( dbug."info"
  , q'[get_jobs(p_job_name_expr => '%s'): '%s']'
  , '%'
  , oracle_tools.api_pkg.collection2list(p_value_tab => get_jobs('%'), p_sep => ' ', p_ignore_null => 1)
  );
end show_jobs;

$end

function does_job_exist
( p_job_name in job_name_t
)
return boolean
is
  l_job_names sys.odcivarchar2list;
  l_result boolean;
begin
  if g_dry_run$
  then
    l_result := g_jobs.exists(p_job_name);
  else
    PRAGMA INLINE (get_jobs, 'YES');
    l_job_names := get_jobs(p_job_name);
    l_result := l_job_names.count = 1;
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."info"
  , q'[does_job_exist(p_job_name => %s) = %s]'
  , dyn_sql_parm(p_job_name)
  , dyn_sql_parm(l_result)
  );
$end

  return l_result;
end does_job_exist;

function is_job_running
( p_job_name in job_name_t
)
return boolean
is
  l_result boolean;
begin
  if g_dry_run$
  then
    l_result := g_jobs.exists(p_job_name) and g_jobs(p_job_name).state = 'RUNNING';
  else
    PRAGMA INLINE (get_jobs, 'YES');
    l_result := get_jobs(p_job_name, 'RUNNING').count = 1;
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."info"
  , q'[is_job_running(p_job_name => %s) = %s]'
  , dyn_sql_parm(p_job_name)
  , dyn_sql_parm(l_result)
  );
$end

  return l_result;
end is_job_running;

function does_program_exist
( p_program_name in varchar2
)
return boolean
is
  l_result boolean;
  l_found pls_integer;
begin
  if g_dry_run$
  then
    l_result := g_programs.exists(p_program_name);
  else
    begin
      select  1
      into    l_found
      from    user_scheduler_programs p
      where   p.program_name = p_program_name;
      l_result := true;
    exception
      when no_data_found
      then
        l_result := false;
    end;
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."info"
  , q'[does_program_exist(p_program_name => %s) = %s]'
  , dyn_sql_parm(p_program_name)
  , dyn_sql_parm(l_result)
  );
$end

  return l_result;
end does_program_exist;

function does_schedule_exist
( p_schedule_name in varchar2
)
return boolean
is
  l_result boolean;
  l_found pls_integer;
begin
  if g_dry_run$
  then
    l_result := g_schedules.exists(p_schedule_name);
  else    
    begin
      select  1
      into    l_found
      from    user_scheduler_schedules p
      where   p.schedule_name = p_schedule_name;
      l_result := true;
    exception
      when no_data_found
      then
        l_result := false;
    end;
  end if;    

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."info"
  , q'[does_schedule_exist(p_schedule_name => %s) = %s]'
  , dyn_sql_parm(p_schedule_name)
  , dyn_sql_parm(l_result)
  );
$end

  return l_result;
end does_schedule_exist;

function session_job_name
( p_session_id in varchar2 default c_session_id
)
return job_name_t
is
  l_job_name job_name_t;
begin
  -- oracle_tools.api_call_stack_pkg.show_stack('session_job_name');
  
  if g_dry_run$
  then
    l_job_name := null; -- don't know
  else
    -- Is this session running as a job?
    -- If not, just create a job name launcher to be used by the worker jobs.
    begin
      select  j.job_name
      into    l_job_name
      from    user_scheduler_running_jobs j
      where   j.session_id = p_session_id;
    exception
      when no_data_found
      then
        l_job_name := null;
    end;
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."info"
  , 'session_job_name(p_session_id => %s) = %s'
  , dyn_sql_parm(p_session_id)
  , dyn_sql_parm(l_job_name)
  );
$end

  return l_job_name;
end session_job_name;

/*1*/

procedure add_comment
( p_comment in varchar2
)
is
begin
  if g_dry_run$
  then
    null;
  else
    raise program_error;
  end if;

  if g_show_comments$
  then
    g_commands.extend(1);
    g_commands(g_commands.last) := '-- ' || p_comment;
  end if;  
end;  

procedure process_command
( p_command in command_t
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."info", 'process_command(p_command => %s)', dyn_sql_parm(p_command));
$end

  if g_dry_run$
  then
    g_commands.extend(1);
    g_commands(g_commands.last) := p_command;
  else
    begin
      execute immediate 'call ' || p_command;
    exception
      when others
      then
        raise_application_error(-20000, p_command, true);
    end;
  end if;
end;

-- invoked by:
-- * create_program
procedure dbms_scheduler$create_program
( program_name in varchar2
, program_type in varchar2
, program_action in varchar2
, number_of_arguments in pls_integer
, enabled in boolean
, comments in varchar2
)
is
  l_program_rec program_rec_t;
begin
  if g_dry_run$
  then
    l_program_rec.program_type := program_type;
    l_program_rec.program_action := program_action;
    l_program_rec.number_of_arguments := number_of_arguments;
    l_program_rec.enabled := enabled;
    l_program_rec.comments := comments;
    g_programs(program_name) := l_program_rec;
  end if;
  process_command
  ( utl_lms.format_message
    ( q'[dbms_scheduler.create_program(program_name => %s, program_type => %s, program_action => %s, number_of_arguments => %s, enabled => %s, comments => %s)]'
    , dyn_sql_parm(program_name)
    , dyn_sql_parm(program_type)
    , dyn_sql_parm(program_action)
    , dyn_sql_parm(number_of_arguments)
    , dyn_sql_parm(enabled)
    , dyn_sql_parm(comments)
    )
  );
end;

-- invoked by:
-- * do
procedure dbms_scheduler$drop_program
( program_name in varchar2
)
is
begin
  if g_dry_run$
  then
    g_programs.delete(program_name);
  end if;
  process_command
  ( utl_lms.format_message
    ( q'[dbms_scheduler.drop_program(program_name => %s)]'
    , dyn_sql_parm(program_name)
    )
  );
end;

-- invoked by:
-- * create_program
procedure dbms_scheduler$define_program_argument
( program_name in varchar2
, argument_name in varchar2
, argument_position in pls_integer
, argument_type in varchar2
, default_value in varchar2
)
is
  l_program_argument program_argument_rec_t;
begin
  if g_dry_run$
  then
    l_program_argument.argument_position := argument_position;
    l_program_argument.argument_type := argument_type;
    l_program_argument.default_value := default_value;
    g_programs(program_name).program_arguments(argument_name) := l_program_argument;
  end if;
  process_command
  ( utl_lms.format_message
    ( q'[dbms_scheduler.define_program_argument(program_name => %s, argument_name => %s, argument_position => %s, argument_type => %s, default_value => %s)]'
    , dyn_sql_parm(program_name)
    , dyn_sql_parm(argument_name)
    , dyn_sql_parm(argument_position)
    , dyn_sql_parm(argument_type)
    , dyn_sql_parm(default_value)
    )
  );
end;

-- invoked by:
-- * change_job
procedure dbms_scheduler$disable
( name in varchar2
)
is
begin
  process_command
  ( utl_lms.format_message
    ( q'[dbms_scheduler.disable(name => %s)]'
    , dyn_sql_parm(name)
    )
  );
end;

procedure disable_job
( p_job_name in varchar2
)
is
begin
  dbms_scheduler$disable(p_job_name);
  if g_dry_run$
  then
    if not g_jobs.exists(p_job_name)
    then
      raise program_error;
    end if;
    g_jobs(p_job_name).enabled := false;
  end if;
end;  
  
-- invoked by:
-- * create_program
-- * change_job
procedure dbms_scheduler$enable
( name in varchar2
)
is
begin
  process_command
  ( utl_lms.format_message
    ( q'[dbms_scheduler.enable(name => %s)]'
    , dyn_sql_parm(name)
    )
  );
end;

-- invoked by:
-- * create_job
procedure dbms_scheduler$create_job
( job_name in varchar2
, program_name in varchar2
, start_date in oracle_tools.api_time_pkg.timestamp_t
, repeat_interval in varchar2
, end_date in oracle_tools.api_time_pkg.timestamp_t
, enabled in boolean
, auto_drop in boolean
, comments in varchar2
)
is
  l_job_rec job_rec_t;
begin
  if g_dry_run$
  then
    l_job_rec.program_name := program_name;
    l_job_rec.start_date := start_date;
    l_job_rec.repeat_interval := repeat_interval;
    l_job_rec.end_date := end_date;
    l_job_rec.enabled := enabled;
    l_job_rec.auto_drop := auto_drop;
    l_job_rec.comments := comments;
    g_jobs(job_name) := l_job_rec;
  end if;
  process_command
  ( utl_lms.format_message
    ( q'[dbms_scheduler.create_job(job_name => %s, program_name => %s, start_date => %s, repeat_interval => %s, end_date => %s, enabled => %s, auto_drop => %s, comments => %s)]'
    , dyn_sql_parm(job_name)
    , dyn_sql_parm(program_name)
    , dyn_sql_parm(start_date)
    , dyn_sql_parm(repeat_interval)
    , dyn_sql_parm(end_date)
    , dyn_sql_parm(enabled)
    , dyn_sql_parm(auto_drop)
    , dyn_sql_parm(comments)
    )
  );
end;
   
-- invoked by:
-- * create_job
procedure dbms_scheduler$create_job
( job_name in varchar2
, program_name in varchar2
, schedule_name in varchar2
, enabled in boolean
, auto_drop in boolean
, comments in varchar2
)
is
  l_job_rec job_rec_t;
begin
  if g_dry_run$
  then
    l_job_rec.program_name := program_name;
    l_job_rec.schedule_name := schedule_name;
    l_job_rec.enabled := enabled;
    l_job_rec.auto_drop := auto_drop;
    l_job_rec.comments := comments;
    g_jobs(job_name) := l_job_rec;
  end if;
  process_command
  ( utl_lms.format_message
    ( q'[dbms_scheduler.create_job(job_name => %s, program_name => %s, schedule_name => %s, enabled => %s, auto_drop => %s, comments => %s)]'
    , dyn_sql_parm(job_name)
    , dyn_sql_parm(program_name)
    , dyn_sql_parm(schedule_name)
    , dyn_sql_parm(enabled)
    , dyn_sql_parm(auto_drop)
    , dyn_sql_parm(comments)
    )
  );
end;

-- invoked by:
-- * submit_processing
-- * submit_do
-- * submit_processing_launcher
procedure dbms_scheduler$set_job_argument_value
( job_name in varchar2
, argument_name in varchar2
, argument_value in varchar2
)
is
begin
  if g_dry_run$
  then
    g_jobs(job_name).job_arguments(argument_name).argument_value := argument_value;
  end if;
  process_command
  ( utl_lms.format_message
    ( q'[dbms_scheduler.set_job_argument_value(job_name => %s, argument_name => %s, argument_value => %s)]'
    , dyn_sql_parm(job_name)
    , dyn_sql_parm(argument_name)
    , dyn_sql_parm(argument_value)
    )
  );
end;  

-- invoked by:
-- * create_job
procedure dbms_scheduler$create_schedule
( schedule_name in varchar2
, start_date in oracle_tools.api_time_pkg.timestamp_t
, repeat_interval in varchar2
, end_date in oracle_tools.api_time_pkg.timestamp_t
, comments in varchar2
)
is
  l_schedule_rec schedule_rec_t;
begin
  if g_dry_run$
  then
    l_schedule_rec.start_date := start_date;
    l_schedule_rec.repeat_interval := repeat_interval;
    l_schedule_rec.end_date := end_date;
    l_schedule_rec.comments := comments;
    g_schedules(schedule_name) := l_schedule_rec;
  end if;
  process_command
  ( utl_lms.format_message
    ( q'[dbms_scheduler.create_schedule(schedule_name => %s, start_date => %s, repeat_interval => %s, end_date => %s, comments => %s)]'
    , dyn_sql_parm(schedule_name)
    , dyn_sql_parm(start_date)
    , dyn_sql_parm(repeat_interval)
    , dyn_sql_parm(end_date)
    , dyn_sql_parm(comments)
    )
  );
end;

-- invoked by:
-- * do
procedure dbms_scheduler$drop_schedule
( schedule_name in varchar2
)
is
begin
  if g_dry_run$
  then
    g_schedules.delete(schedule_name);
  end if;
  process_command
  ( utl_lms.format_message
    ( q'[dbms_scheduler.drop_schedule(schedule_name => %s)]'
    , dyn_sql_parm(schedule_name)
    )
  );
end;

procedure admin_scheduler_pkg$stop_job
( p_job_name in varchar2
, p_force in boolean
)
is
begin
  process_command
  ( utl_lms.format_message
    ( q'[admin_scheduler_pkg.stop_job(p_job_name => %s, p_force => %s)]'
    , dyn_sql_parm(p_job_name)
    , dyn_sql_parm(p_force)
    )
  );
end;

procedure admin_scheduler_pkg$drop_job
( p_job_name in varchar2
, p_force in boolean
)
is
begin
  if g_dry_run$ and p_force
  then
    g_jobs.delete(p_job_name);
  end if;
  process_command
  ( utl_lms.format_message
    ( q'[admin_scheduler_pkg.drop_job(p_job_name => %s, p_force => %s)]'
    , dyn_sql_parm(p_job_name)
    , dyn_sql_parm(p_force)
    )
  );
end;

procedure enable_program
( p_program_name in varchar2
)
is
begin
  dbms_scheduler$enable(name => p_program_name);
  if g_dry_run$ 
  then
    if not g_programs.exists(p_program_name)
    then
      raise program_error;
    end if;
    g_programs(p_program_name).enabled := true;
  end if;
end;  

procedure enable_job
( p_job_name in varchar2
, p_run_job in boolean default true -- run job in this session in order to determine jobs created by this job
)
is
begin
  dbms_scheduler$enable(name => p_job_name);
  -- From Oracle docs:
  -- If a job was disabled and you enable it, the Scheduler begins to automatically run the job according to its schedule. 
  if g_dry_run$
  then
    if not g_jobs.exists(p_job_name)
    then
      raise program_error;
    end if;

    if not(g_jobs(p_job_name).enabled)
    then
      g_jobs(p_job_name).enabled := true;

      if p_run_job
      then
        add_comment
        ( utl_lms.format_message
          ( q'[dbms_scheduler.run_job(job_name => %s, use_current_session => true) -- start]'
          , dyn_sql_parm(p_job_name)
          )
        );
        -- execute the command to get more commands now when USE CURRENT SESSION, DRY RUN and CHECK PROCOBJ EXISTS are true

        -- only run procedures that create jobs
        case 
          when p_job_name = 'MSG_AQ_PKG$PROCESSING_LAUNCHER'
           and g_programs(g_jobs(p_job_name).program_name).program_type = 'STORED_PROCEDURE'
           and g_programs(g_jobs(p_job_name).program_name).program_action = 'MSG_SCHEDULER_PKG.PROCESSING_LAUNCHER'
          then
            declare
              l_processing_package constant all_objects.object_name%type :=
                case
                  when g_jobs(p_job_name).job_arguments.exists('P_PROCESSING_PACKAGE')
                  then g_jobs(p_job_name).job_arguments('P_PROCESSING_PACKAGE').argument_value
                  else nvl(g_programs(g_jobs(p_job_name).program_name).program_arguments('P_PROCESSING_PACKAGE').default_value, g_processing_package$)
                end;
              l_nr_workers_each_group constant pls_integer :=
                case
                  when g_jobs(p_job_name).job_arguments.exists('P_NR_WORKERS_EACH_GROUP')
                  then g_jobs(p_job_name).job_arguments('P_NR_WORKERS_EACH_GROUP').argument_value
                  else g_programs(g_jobs(p_job_name).program_name).program_arguments('P_NR_WORKERS_EACH_GROUP').default_value
                end;
              l_nr_workers_exact constant pls_integer :=
                case
                  when g_jobs(p_job_name).job_arguments.exists('P_NR_WORKERS_EXACT')
                  then g_jobs(p_job_name).job_arguments('P_NR_WORKERS_EXACT').argument_value
                  else g_programs(g_jobs(p_job_name).program_name).program_arguments('P_NR_WORKERS_EXACT').default_value
                end;
            begin
              msg_scheduler_pkg.processing_launcher -- program_action
              ( p_processing_package => l_processing_package
              , p_nr_workers_each_group => l_nr_workers_each_group
              , p_nr_workers_exact => l_nr_workers_exact
              );
            end;
            
          when p_job_name = 'MSG_AQ_PKG$PROCESSING_SUPERVISOR'
            or p_job_name like 'MSG_AQ_PKG$PROCESSING_WORKER#%'
          then
            null;
        end case;
        
        add_comment
        ( utl_lms.format_message
          ( q'[dbms_scheduler.run_job(job_name => %s, use_current_session => true) -- end]'
          , dyn_sql_parm(p_job_name)
          )
        );
      end if;
    end if;
  end if;
end enable_job;

/*2*/

procedure create_program
( p_program_name in varchar2
)
is
  l_program_name constant all_objects.object_name%type := upper(p_program_name);
begin
  case 
    when l_program_name = c_program_launcher
    then
      dbms_scheduler$create_program
      ( program_name => l_program_name
      , program_type => 'STORED_PROCEDURE'
      , program_action => $$PLSQL_UNIT || '.' || p_program_name -- program name is the same as module name
      , number_of_arguments => 3
      , enabled => false
      , comments => 'Main program for processing messages by spawning worker jobs.'
      );

      for i_par_idx in 1..3
      loop
        dbms_scheduler$define_program_argument
        ( program_name => l_program_name
        , argument_name => case i_par_idx
                             when 1 then 'P_PROCESSING_PACKAGE'
                             when 2 then 'P_NR_WORKERS_EACH_GROUP'
                             when 3 then 'P_NR_WORKERS_EXACT'
                           end
        , argument_position => i_par_idx
        , argument_type => case 
                             when i_par_idx = 1
                             then 'VARCHAR2'
                             else 'NUMBER'
                           end
        , default_value => case i_par_idx
                             when 2 then to_char(msg_constants_pkg.get_nr_workers_each_group)
                             when 3 then to_char(msg_constants_pkg.get_nr_workers_exact)
                             else null
                           end
        );
      end loop;

    when l_program_name in ( c_program_supervisor, c_program_worker )
    then
      dbms_scheduler$create_program
      ( program_name => l_program_name
      , program_type => 'STORED_PROCEDURE'
      , program_action => $$PLSQL_UNIT || '.' || 'PROCESSING' -- they share the same stored procedure
      , number_of_arguments => 5
      , enabled => false
      , comments => case when l_program_name = c_program_supervisor then 'Supervisor' else 'Worker' end || ' program for processing messages.'
      );
  
      for i_par_idx in 1..5
      loop
        dbms_scheduler$define_program_argument
        ( program_name => l_program_name
        , argument_name => case i_par_idx
                             when 1 then 'P_PROCESSING_PACKAGE'
                             when 2 then 'P_GROUPS_TO_PROCESS_LIST'
                             when 3 then 'P_NR_WORKERS'
                             when 4 then 'P_WORKER_NR'
                             when 5 then 'P_END_DATE'
                           end
        , argument_position => i_par_idx
        , argument_type => -- informational only
                           case 
                             when i_par_idx <= 2
                             then 'VARCHAR2'
                             when i_par_idx <= 4
                             then 'NUMBER'
                             else 'VARCHAR2'
                           end
        , default_value => null
        );
      end loop;
      
    when l_program_name = c_program_do
    then
      dbms_scheduler$create_program
      ( program_name => l_program_name
      , program_type => 'STORED_PROCEDURE'
      , program_action => $$PLSQL_UNIT || '.' || p_program_name -- program name is the same as module name
      , number_of_arguments => 2
      , enabled => false
      , comments => 'Main program for executing commands.'
      );

      for i_par_idx in 1..2
      loop
        dbms_scheduler$define_program_argument
        ( program_name => l_program_name
        , argument_name => case i_par_idx
                             when 1 then 'P_COMMAND'
                             when 2 then 'P_PROCESSING_PACKAGE'
                           end
        , argument_position => i_par_idx
        , argument_type => 'VARCHAR2'
        , default_value => null
        );
      end loop;
  end case;
      
  enable_program(p_program_name => l_program_name);
end create_program;

procedure get_job_info
( p_job_name in job_name_t
, p_job_info_rec out nocopy job_info_rec_t
)
is
begin
  select  j.job_name 
  ,       j.program_name
  ,       j.schedule_owner
  ,       j.schedule_name
  ,       j.repeat_interval
  ,       j.enabled
  ,       j.state
  ,       j.start_date
  ,       j.end_date
  ,       j.last_start_date
  ,       j.last_run_duration
  ,       j.next_run_date
  ,       j.run_count
  ,       j.failure_count
  ,       j.retry_count
  ,       null as procedure_call
  into    p_job_info_rec
  from    user_scheduler_jobs j
  where   j.job_name = p_job_name;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."info"
  , 'get_job_info (1); job_name: %s; schedule: %s; start date: %s; repeat interval: %s; end date: %s'
  , p_job_info_rec.job_name
  , p_job_info_rec.schedule_name
  , to_char(p_job_info_rec.start_date, "yyyy-mm-dd hh24:mi:ss")
  , p_job_info_rec.repeat_interval
  , to_char(p_job_info_rec.end_date  , "yyyy-mm-dd hh24:mi:ss")
  );
  dbug.print
  ( dbug."info"
  , 'get_job_info (2); enabled: %s; state: %s; last start date: %s; next run date: %s; run count: %s'
  , p_job_info_rec.enabled
  , p_job_info_rec.state
  , to_char(p_job_info_rec.last_start_date, "yyyy-mm-dd hh24:mi:ss")
  , to_char(p_job_info_rec.next_run_date, "yyyy-mm-dd hh24:mi:ss")
  , p_job_info_rec.run_count
  );
$end
end get_job_info;  

procedure get_next_end_date
( p_job_name_launcher in job_name_t
, p_end_date out nocopy user_scheduler_jobs.end_date%type
)
is
  l_job_info_rec job_info_rec_t;
  l_end_date user_scheduler_jobs.end_date%type;
  l_interval oracle_tools.api_time_pkg.timestamp_diff_t;
  l_now constant user_scheduler_jobs.end_date%type := current_timestamp();
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.GET_NEXT_END_DATE');
  dbug.print
  ( dbug."input"
  , 'p_job_name_launcher: %s; now: %s'
  , p_job_name_launcher
  , to_char(l_now, "yyyy-mm-dd hh24:mi:ss")
  );
$end

  get_job_info
  ( p_job_name => p_job_name_launcher 
  , p_job_info_rec => l_job_info_rec
  );

  -- the next run date for a scheduled job is supposed to be okay (at least when it is in the future)
  if l_job_info_rec.next_run_date > l_now
  then
    null; -- OK
  else
    -- to start with
    l_job_info_rec.next_run_date := l_now;
    
    if l_job_info_rec.repeat_interval is null and
       l_job_info_rec.schedule_owner is not null and
       l_job_info_rec.schedule_name is not null
    then
      select  s.repeat_interval
      into    l_job_info_rec.repeat_interval
      from    all_scheduler_schedules s
      where   s.owner = l_job_info_rec.schedule_owner
      and     s.schedule_name = l_job_info_rec.schedule_name;
    end if;

    if l_job_info_rec.repeat_interval is not null
    then
      -- next_run_date is an out parameter, hence no dbms_scheduler$evaluate_calendar_string
      dbms_scheduler.evaluate_calendar_string
      ( calendar_string => l_job_info_rec.repeat_interval
      , start_date => l_job_info_rec.start_date -- date at which the schedule became active
      , return_date_after => l_job_info_rec.next_run_date
      , next_run_date => l_job_info_rec.next_run_date
      );
    else
      -- Final resort: check last two log entries for the interval between runs.      
      -- Add interval between last two start dates, i.e. the interval between runs.
      select  max(d.req_start_date) - min(d.req_start_date)
      into    l_interval
      from    ( select  d.req_start_date
                from    user_scheduler_job_run_details d
                where   d.job_name = p_job_name_launcher
                order by
                        log_date desc
              ) d
      where   rownum <= 2 -- get the last two entries and the time between them is the interval to add
      ;

      l_job_info_rec.next_run_date := l_job_info_rec.next_run_date + l_interval;
    end if;
  end if;

  p_end_date := greatest
                ( l_now + numtodsinterval(1, 'SECOND')
                , nvl(l_job_info_rec.next_run_date, l_now) - numtodsinterval(msg_constants_pkg.get_time_between_runs, 'SECOND')
                );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_end_date: %s', to_char(p_end_date, "yyyy-mm-dd hh24:mi:ss"));
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end get_next_end_date;  

procedure change_job
( p_job_name in job_name_t
, p_enabled in boolean
)
is
  l_job_info_rec job_info_rec_t;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CHANGE_JOB');
  dbug.print(dbug."input", 'p_job_name: %s; p_enabled: %s', p_job_name, dbug.cast_to_varchar2(p_enabled));
$end

  get_job_info(p_job_name, l_job_info_rec);

  case
    when p_enabled is null
    then raise value_error;
    
    when p_enabled and l_job_info_rec.enabled = 'TRUE'
    then null;
    
    when p_enabled
    then enable_job(p_job_name => p_job_name);
    
    when not(p_enabled) and l_job_info_rec.enabled = 'FALSE'
    then null;
    
    when not(p_enabled)
    then disable_job(p_job_name => p_job_name);
  end case;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end change_job;

procedure create_job
( p_job_name in job_name_t
)
is
  l_processing_package all_objects.object_name%type;
  l_program_name user_scheduler_programs.program_name%type;
  l_worker_nr positive;
  l_end_date user_scheduler_jobs.end_date%type := null;
  l_job_names sys.odcivarchar2list;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.CREATE_JOB');
  dbug.print
  ( dbug."input"
  , 'p_job_name: %s'
  , p_job_name
  );
$end

  PRAGMA INLINE (split_job_name, 'YES');
  split_job_name
  ( p_job_name => p_job_name
  , p_processing_package => l_processing_package
  , p_program_name => l_program_name
  , p_worker_nr => l_worker_nr
  );

  PRAGMA INLINE (get_jobs, 'YES');
  l_job_names := get_jobs(p_job_name, 'RUNNING');
  if l_job_names.count > 0
  then
    raise_application_error
    ( c_there_are_running_jobs
    , utl_lms.format_message
      ( c_there_are_running_jobs_msg
      , p_job_name
      , ' ' || oracle_tools.api_pkg.collection2list(p_value_tab => l_job_names, p_sep => ' ', p_ignore_null => 1)
      )
    );
  end if;

  PRAGMA INLINE (does_job_exist, 'YES');
  if does_job_exist(p_job_name)
  then  
    change_job(p_job_name => p_job_name, p_enabled => false);
  else
    PRAGMA INLINE (does_program_exist, 'YES');
    if not(does_program_exist(l_program_name))
    then
      create_program(l_program_name);
    end if;

    case 
      when l_program_name in ( c_program_supervisor, c_program_worker )
      then
        dbms_scheduler$create_job
        ( job_name => p_job_name
        , program_name => l_program_name
        , start_date => null
        , repeat_interval => null
        , end_date => l_end_date
        , enabled => false -- so we can set job arguments
        , auto_drop => false
        , comments => case when l_program_name = c_program_supervisor then 'Supervisor' else 'Worker' end || ' job for processing messages.'
        );
        
      when l_program_name = c_program_do
      then
        dbms_scheduler$create_job
        ( job_name => p_job_name
        , program_name => l_program_name
        , start_date => null
        , repeat_interval => null
        , end_date => null
        , enabled => false -- so we can set job arguments
        , auto_drop => false
        , comments => 'A job for executing commands.'
        );
        
      when l_program_name = c_program_launcher
      then
        -- a repeating job
        if not(does_schedule_exist(c_schedule_launcher))
        then
          dbms_scheduler$create_schedule
          ( schedule_name => c_schedule_launcher
          , start_date => null
          , repeat_interval => msg_constants_pkg.get_repeat_interval
          , end_date => null
          , comments => 'Launcher job schedule'
          );
        end if;

        dbms_scheduler$create_job
        ( job_name => p_job_name
        , program_name => l_program_name
        , schedule_name => c_schedule_launcher
        , enabled => false -- so we can set job arguments
        , auto_drop => false
        , comments => 'Repeating job for processing messages.'
        );
    end case;
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end create_job;

procedure set_processing_job_arguments
( p_job_name in job_name_t
, p_processing_package in varchar2
, p_groups_to_process_list in varchar2
, p_nr_workers in positiven
, p_worker_nr in positive
, p_end_date in user_scheduler_jobs.end_date%type
)
is
  l_argument_name user_scheduler_program_args.argument_name%type;
  
  function argument_value
  ( p_argument_name in varchar2
  )
  return varchar2
  is
  begin
    return
      case p_argument_name
        when 'P_PROCESSING_PACKAGE'
        then p_processing_package
        when 'P_GROUPS_TO_PROCESS_LIST'
        then p_groups_to_process_list
        when 'P_NR_WORKERS'
        then to_char(p_nr_workers)
        when 'P_WORKER_NR'
        then to_char(p_worker_nr)
        when 'P_END_DATE'
        then oracle_tools.api_time_pkg.timestamp2str(p_end_date)
        else to_char(1/0) -- trick in order not to forget something
      end;
  end;    
begin
  -- Set the actual arguments for the next run
  if g_dry_run$
  then
    l_argument_name := g_programs(g_jobs(p_job_name).program_name).program_arguments.first;
    while l_argument_name is not null
    loop
      dbms_scheduler$set_job_argument_value
      ( job_name => p_job_name
      , argument_name => l_argument_name
      , argument_value => argument_value(l_argument_name)
      );
    
      l_argument_name := g_programs(g_jobs(p_job_name).program_name).program_arguments.next(l_argument_name);
    end loop;
  else
    for r in
    ( select  pa.argument_name
      ,       pa.argument_position
      from    user_scheduler_jobs j
              inner join user_scheduler_program_args pa
              on pa.program_name = j.program_name
      where   j.job_name = p_job_name
      order by
              pa.argument_name
    )
    loop
      dbms_scheduler$set_job_argument_value
      ( job_name => p_job_name
      , argument_name => r.argument_name
      , argument_value => argument_value(r.argument_name)
      );
    end loop;
  end if;
end set_processing_job_arguments;

procedure submit_processing
( p_processing_package in varchar2
, p_groups_to_process_list in varchar2
, p_nr_workers in positiven
, p_worker_nr in positive
, p_end_date in user_scheduler_jobs.end_date%type
)
is
  l_job_name constant job_name_t :=
    join_job_name
    ( p_processing_package
    , case when p_worker_nr is null then c_program_supervisor else c_program_worker end
    , p_worker_nr
    );
  l_end_date user_scheduler_jobs.end_date%type;
  l_schedule_name user_scheduler_jobs.schedule_name%type;
  l_start_date user_scheduler_jobs.start_date%type;
  l_repeat_interval user_scheduler_jobs.repeat_interval%type;
begin  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.SUBMIT_PROCESSING');
  dbug.print
  ( dbug."input"
  , 'p_processing_package: %s; p_groups_to_process_list: %s; p_nr_workers: %s; p_worker_nr: %s; p_end_date: %s'
  , p_processing_package
  , p_groups_to_process_list
  , p_nr_workers
  , p_worker_nr
  , to_char(p_end_date, "yyyy-mm-dd hh24:mi:ss")
  );
$end

  if p_end_date > systimestamp()
  then
    null;
  else
    raise_application_error
    ( c_end_date_not_in_the_future
    , utl_lms.format_message
      ( c_end_date_not_in_the_future_msg
      , to_char(p_end_date, "yyyy-mm-dd hh24:mi:ss")
      , to_char(systimestamp(), "yyyy-mm-dd hh24:mi:ss")
      )
    );
  end if;

  PRAGMA INLINE (is_job_running, 'YES');
  if is_job_running(l_job_name)
  then
    raise_application_error
    ( c_job_already_running
    , utl_lms.format_message
      ( c_job_already_running_msg
      , l_job_name
      )
    );
  end if;

  create_job(p_job_name => l_job_name);

  set_processing_job_arguments
  ( p_job_name => l_job_name
  , p_processing_package => p_processing_package
  , p_groups_to_process_list => p_groups_to_process_list
  , p_nr_workers => p_nr_workers
  , p_worker_nr => p_worker_nr
  , p_end_date => p_end_date
  );
  
  -- GO
  change_job(p_job_name => l_job_name, p_enabled => true);
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end submit_processing;

function determine_processing_package
( p_processing_package in varchar2
)
return varchar2
is
begin
  if p_processing_package is not null
  then
    return msg_pkg.get_object_name(p_object_name => p_processing_package, p_what => 'package', p_fq => 0, p_qq => 0);
  else
    raise program_error;
  end if;
end determine_processing_package;

procedure stop_job
( p_job_name in job_name_t
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.STOP_JOB');
  dbug.print(dbug."input", 'p_job_name: %s', p_job_name);
$end

  for i_step in 1..2
  loop
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'i_step: %s', i_step);
$end

    -- stop and disable jobs gracefully first
    PRAGMA INLINE (is_job_running, 'YES');
    exit when not(is_job_running(p_job_name));

    admin_scheduler_pkg$stop_job(p_job_name => p_job_name, p_force => case i_step when 1 then false else true end);
  end loop;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end    
end stop_job;

procedure drop_job
( p_job_name in job_name_t
, p_force in boolean
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.DROP_JOB');
  dbug.print(dbug."input", 'p_job_name: %s', p_job_name);
$end

  PRAGMA INLINE (stop_job, 'YES');
  stop_job(p_job_name);
  admin_scheduler_pkg$drop_job(p_job_name => p_job_name, p_force => p_force);

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
exception
  when e_job_unknown
  then
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.leave;
$end
    null;

$if oracle_tools.cfg_pkg.c_debugging $then
  when others
  then
    dbug.leave_on_error;
    raise;
$end    
end drop_job;

function get_groups_to_process
( p_processing_package in varchar2
)
return sys.odcivarchar2list
is
  l_statement varchar2(32767 byte);
  l_groups_to_process_tab sys.odcivarchar2list;
begin
  l_statement := utl_lms.format_message
                 ( q'[begin :1 := %s.get_groups_to_process(:2); end;]'
                 , p_processing_package -- already checked by determine_processing_package
                 );

  execute immediate l_statement
    using out l_groups_to_process_tab, in utl_lms.format_message('package://%s.%s', $$PLSQL_UNIT_OWNER, $$PLSQL_UNIT);

  return l_groups_to_process_tab;
  
$if oracle_tools.cfg_pkg.c_debugging $then
exception
  when others
  then
    dbug.print(dbug."error", 'l_statement: %s', l_statement);
    dbug.on_error;
    raise;     
$end
end get_groups_to_process;

function get_nr_workers
( p_nr_groups in naturaln -- for instance get_groups_to_process().count
, p_nr_workers_each_group in positive default msg_constants_pkg.get_nr_workers_each_group
, p_nr_workers_exact in positive default msg_constants_pkg.get_nr_workers_exact
)
return naturaln
is
begin
  return
    case
      when p_nr_groups = 0
      then 0
      -- exactly one of them must be not-null
      when p_nr_workers_each_group is null and p_nr_workers_exact is null
      then 0
      when p_nr_workers_each_group is not null and p_nr_workers_exact is not null
      then 0
      when p_nr_workers_exact is not null
      then ceil(p_nr_workers_exact / p_nr_groups) * p_nr_groups -- example: p_nr_groups = 3, p_nr_workers_exact in (1, 2, 3) => 3
      else p_nr_workers_each_group * p_nr_groups
    end;
end get_nr_workers;

procedure do
( p_commands in varchar2 -- a list
, p_processing_package in varchar2
)
is
  l_commands dbms_sql.varchar2a;
begin
  oracle_tools.pkg_str_util.split
  ( p_str => p_commands
  , p_delimiter => ','
  , p_str_tab => l_commands
  );
  for i_idx in l_commands.first .. l_commands.last
  loop
    do
    ( p_command => l_commands(i_idx)
    , p_processing_package => p_processing_package 
    );
  end loop;
end;

-- PUBLIC

function show_job_info
( p_processing_package in varchar2 default '%'
)
return job_info_tab_t
pipelined
is
begin
  for rj in
  ( select  j.job_name 
    ,       j.program_name
    ,       j.schedule_owner
    ,       j.schedule_name
    ,       j.repeat_interval
    ,       j.enabled
    ,       j.state
    ,       j.start_date
    ,       j.end_date
    ,       j.last_start_date
    ,       j.last_run_duration
    ,       j.next_run_date
    ,       j.run_count
    ,       j.failure_count
    ,       j.retry_count
    ,       p.program_action || '(' as procedure_call
    from    user_scheduler_jobs j
            inner join user_scheduler_programs p
            on p.program_name = j.program_name
    where   j.program_name in (c_program_launcher, c_program_do, c_program_supervisor, c_program_worker)
    order by
            case j.program_name 
              when c_program_launcher
              then 1
              when c_program_do
              then 2
              when c_program_supervisor
              then 3
              when c_program_worker
              then 4
            end
    ,       j.job_name         
  )
  loop
    for ra in
    ( select  ja.argument_name
      ,       ja.value as argument_value
      ,       ja.argument_position
      ,       ja.argument_type
      from    user_scheduler_job_args ja
      where   ja.job_name = rj.job_name
      order by
              ja.argument_position
    )
    loop
      rj.procedure_call :=
        rj.procedure_call ||
        case when ra.argument_position != 1 then ', ' end ||
        utl_lms.format_message
        ( '%s => %s'
        , ra.argument_name
        , case ra.argument_type
            when 'NUMBER'
            then dyn_sql_parm(to_number(ra.argument_value))
            else dyn_sql_parm(ra.argument_value)
          end
        );
    end loop;
    rj.procedure_call :=
      rj.procedure_call || ')';
    pipe row (rj);
  end loop;
  return;
end;

function do
( p_commands in varchar2 -- create / drop / start / shutdown / stop / restart / check-jobs-running / check-jobs-not-running
, p_processing_package in varchar2 default '%' -- find packages like this paramater that have both a routine get_groups_to_process() and processing()
, p_read_initial_state in natural default null -- read info from USER_SCHEDULER_* dictionary views at the beginning to constitute an ininitial state
, p_show_initial_state in natural default null -- show the initial state: set to false (0) when you want to have what-if scenarios
, p_show_comments in natural default null -- show comments with each command in p_commands and the program
)
return sys.odcivarchar2list
pipelined
is
  l_module_name constant varchar2(100 byte) := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DO (1)';
  
  c_dry_run_old constant boolean := g_dry_run$;
  c_show_comments_old constant boolean := g_show_comments$;

  l_processing_package constant all_objects.object_name%type := 'MSG_AQ_PKG'; -- shortcut, TODO: see procedure do()

  l_read_initial_state constant boolean :=
    case
      when p_read_initial_state is null and p_show_initial_state is null
      then true
      when p_read_initial_state is null and p_show_initial_state != 0
      then true
      when p_read_initial_state is null
      then false
      when p_read_initial_state = 0
      then false
      else true
    end;
  l_show_initial_state constant boolean :=
    case
      when p_show_initial_state is null and l_read_initial_state
      then true
      when p_show_initial_state is null
      then false
      when p_show_initial_state = 0
      then false
      else true
    end;
  l_show_comments constant boolean :=
    case
      when p_show_comments is null and p_read_initial_state is null and p_show_initial_state is null
      then false
      when p_show_comments is null
      then true
      when p_show_comments = 0
      then false
      else true
    end;

  procedure read_initial_state
  is
    l_job_name_tab sys.odcivarchar2list;
  begin
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.enter(l_module_name || '.READ_INITIAL_STATE');
$end

    l_job_name_tab :=
      sys.odcivarchar2list
      ( join_job_name
        ( p_processing_package => l_processing_package
        , p_program_name => c_program_do
        )
      , join_job_name
        ( p_processing_package => l_processing_package
        , p_program_name => c_program_launcher
        )
      , -- supervisor
        join_job_name
        ( p_processing_package => l_processing_package
        , p_program_name => c_program_supervisor
        , p_worker_nr => null
        )
      );
    for i_worker_nr in 1 .. get_groups_to_process(l_processing_package).count
    loop
      l_job_name_tab.extend(1);
      l_job_name_tab(l_job_name_tab.last) :=
        join_job_name
        ( p_processing_package => l_processing_package
        , p_program_name => c_program_worker
        , p_worker_nr => i_worker_nr
        );
    end loop;

    <<program_loop>>
    for p in ( select  p.program_name
               ,       p.program_type
               ,       p.program_action
               ,       p.number_of_arguments
               ,       p.enabled
               ,       p.comments
               from    user_scheduler_programs p
               where   p.program_name in (c_program_launcher, c_program_supervisor, c_program_worker, c_program_do)
               order by
                       case p.program_name
                         when c_program_launcher
                         then 1
                         when c_program_do
                         then 2
                         when c_program_supervisor
                         then 3
                         when c_program_worker
                         then 4
                       end
             )
    loop
      if g_programs.exists(p.program_name)
      then
        raise program_error;
      end if;
        
      dbms_scheduler$create_program
      ( program_name => p.program_name
      , program_type => p.program_type
      , program_action => p.program_action
      , number_of_arguments => p.number_of_arguments
      , enabled => false -- programs are created initially disabled so arguments can be added
      , comments => p.comments
      );

      <<program_argument_loop>>
      for pa in ( select  pa.program_name
                  ,       pa.argument_name
                  ,       pa.argument_position
                  ,       pa.argument_type
                  ,       pa.default_value
                  from    user_scheduler_program_args pa
                  where   pa.program_name = p.program_name
                  order by
                          pa.argument_position
                )
      loop
        if g_programs(pa.program_name).program_arguments.exists(pa.argument_name)
        then
          raise program_error;
        end if;
        
        dbms_scheduler$define_program_argument
        ( program_name => pa.program_name
        , argument_name => pa.argument_name
        , argument_position => pa.argument_position
        , argument_type => pa.argument_type
        , default_value => pa.default_value
        );
      end loop program_argument_loop;

      if upper(p.enabled) = 'TRUE'
      then
        enable_program(p.program_name);
      end if;

      <<job_loop>>
      for j in ( select  j.job_name
                 ,       j.program_name
                 ,       j.start_date
                 ,       j.repeat_interval
                 ,       j.end_date
                 ,       j.enabled
                 ,       j.auto_drop
                 ,       j.comments
                 -- extra
                 ,       j.schedule_name
                 ,       j.state
                 from    user_scheduler_jobs j
                 where   j.program_name = p.program_name
                 and     j.job_name in ( select t.column_value from table(l_job_name_tab) t )
                 order by
                         j.job_name 
               )
      loop
        if j.schedule_name is not null and not g_schedules.exists(j.schedule_name)
        then
          <<schedule_loop>>
          for r in ( select  s.schedule_name
                     ,       s.start_date
                     ,       s.repeat_interval
                     ,       s.end_date
                     ,       s.comments
                     from    user_scheduler_schedules s
                     where   s.schedule_name = j.schedule_name
                   )
          loop
            if g_schedules.exists(r.schedule_name)
            then
              raise program_error;
            end if;
            
            dbms_scheduler$create_schedule
            ( schedule_name => r.schedule_name
            , start_date => r.start_date
            , repeat_interval => r.repeat_interval
            , end_date => r.end_date
            , comments => r.comments
            );
          end loop schedule_loop;
        end if;

        if g_jobs.exists(j.job_name)
        then
          raise program_error;
        end if;
        
        if j.schedule_name is not null
        then
          dbms_scheduler$create_job
          ( job_name => j.job_name
          , program_name => j.program_name
          , schedule_name => j.schedule_name
          , enabled => false -- jobs are created initially disabled so arguments can be added
          , auto_drop => case upper(j.auto_drop) when 'TRUE' then true else false end
          , comments => j.comments
          );
        else
          dbms_scheduler$create_job
          ( job_name => j.job_name
          , program_name => j.program_name
          , start_date => j.start_date
          , repeat_interval => j.repeat_interval
          , end_date => j.end_date
          , enabled => false -- jobs are created initially disabled so arguments can be added
          , auto_drop => case upper(j.auto_drop) when 'TRUE' then true else false end
          , comments => j.comments
          );
        end if;
        g_jobs(j.job_name).state := j.state;

        <<job_argument_loop>>
        for ja in ( select  ja.job_name
                    ,       ja.argument_name
                    ,       ja.value as argument_value
                    from    user_scheduler_job_args ja
                    where   ja.job_name = j.job_name
                    order by
                            ja.argument_name -- like in set_*_job_arguments
                  )
        loop
          if g_jobs(ja.job_name).job_arguments.exists(ja.argument_name)
          then
            raise program_error;
          end if;
          
          dbms_scheduler$set_job_argument_value
          ( job_name => ja.job_name
          , argument_name => ja.argument_name
          , argument_value => ja.argument_value
          );
        end loop job_argument_loop;
        
        if upper(j.enabled) = 'TRUE'
        then
          enable_job(j.job_name, false);
        end if;
      end loop job_loop;
    end loop program_loop;
    
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.leave;
$end
  end read_initial_state;

  procedure cleanup
  is
  begin
    -- restore
    g_dry_run$ := c_dry_run_old;
    g_show_comments$ := c_show_comments_old;
    g_commands.delete;
    g_schedules.delete;
    g_programs.delete;
    g_jobs.delete;
  end cleanup;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter(l_module_name);
  dbug.print
  ( dbug."input"
  , 'p_commands: %s; p_processing_package: %s; p_read_initial_state: %s; p_show_initial_state: %s; p_show_comments: %s'
  , p_commands
  , p_processing_package
  , p_read_initial_state
  , p_show_initial_state
  , p_show_comments
  );
$end

  g_dry_run$ := true;
  g_commands.delete;
  g_schedules.delete;
  g_programs.delete;
  g_jobs.delete;

  -- always add one comment: this call
  g_show_comments$ := true;
  add_comment
  ( utl_lms.format_message
    ( 'do(p_commands => %s, p_processing_package => %s, p_read_initial_state => %s, p_show_initial_state => %s, p_show_comments => %s)'
    , dyn_sql_parm(p_commands)
    , dyn_sql_parm(p_processing_package)
    , dyn_sql_parm(case when l_read_initial_state then 1 else 0 end)
    , dyn_sql_parm(case when l_show_initial_state then 1 else 0 end)
    , dyn_sql_parm(case when l_show_comments then 1 else 0 end)
    )
  );  
  g_show_comments$ := l_show_comments;
  
  if l_read_initial_state
  then
    if l_show_initial_state
    then
      add_comment('show-initial-state');
    end if;
    read_initial_state;
    if not l_show_initial_state
    then
      g_commands.delete;
    end if;
  end if;

  do
  ( p_commands => p_commands
  , p_processing_package => p_processing_package
  );

  if g_commands is not null and g_commands.count > 0
  then
    for i_idx in g_commands.first .. g_commands.last
    loop
      pipe row (g_commands(i_idx));
    end loop;
  end if;

  cleanup;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end

  return; -- essential for a pipelined function
exception
  when others
  then
    declare
      l_error_stack_tab oracle_tools.api_call_stack_pkg.t_error_stack_tab := oracle_tools.api_call_stack_pkg.get_error_stack;
    begin
      if l_error_stack_tab.count > 0
      then
        for i_idx in l_error_stack_tab.first .. l_error_stack_tab.last
        loop
          add_comment(l_error_stack_tab(i_idx).error_msg);
        end loop;
      end if;
      
      if g_commands is not null and g_commands.count > 0
      then
        for i_idx in g_commands.first .. g_commands.last
        loop
          pipe row (g_commands(i_idx));
        end loop;
      end if;
    end;
    
    cleanup;

$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.leave_on_error;
$end

    return;
end do;

procedure do
( p_command in varchar2
, p_processing_package in varchar2
)
is
  pragma autonomous_transaction;

  l_program_tab constant sys.odcivarchar2list :=
    sys.odcivarchar2list
    ( c_program_launcher
    , c_program_do
    , c_program_supervisor
    , c_program_worker
    );
  l_schedule_tab constant sys.odcivarchar2list :=
    sys.odcivarchar2list
    ( c_schedule_launcher
    );
  l_shutdown_timeout constant positiven :=
     case
       when lower(p_command) = 'shutdown'
       then msg_constants_pkg.get_time_between_heartbeats * 2 -- give some leeway
       else 1 -- but not when we want to stop quickly
     end;
  l_command_tab constant sys.odcivarchar2list :=
    case lower(p_command)
      -- create / drop scheduler objects
      when 'create'
      then sys.odcivarchar2list('create-jobs', 'check-jobs-not-running')
      when 'drop'
      then sys.odcivarchar2list('stop', 'check-jobs-not-running', 'drop-jobs', 'drop-programs', 'drop-schedules')
      -- start / stop
      when 'start'
      then sys.odcivarchar2list('check-jobs-not-running', p_command)
      when 'shutdown' -- try to stop gracefully
      then sys.odcivarchar2list(p_command, 'check-jobs-not-running')
      when 'stop'
      then sys.odcivarchar2list('shutdown', p_command, 'check-jobs-not-running')
      when 'restart'
      then sys.odcivarchar2list('shutdown', 'stop', 'check-jobs-not-running', 'start')
      else sys.odcivarchar2list(p_command)
    end;    
  l_processing_package all_objects.object_name%type := trim('"' from to_like_expr(upper(p_processing_package)));
  l_processing_package_tab sys.odcivarchar2list;

  procedure do_program_command
  ( p_command in varchar2
  , p_program_name in varchar2
  )
  is
    l_job_name job_name_t;
    l_job_names sys.odcivarchar2list;
    l_nr_groups natural;
    l_nr_workers natural;
  begin
    l_job_name :=
      join_job_name
      ( p_processing_package => l_processing_package 
      , p_program_name => p_program_name
      , p_worker_nr => null
      , p_check => false
      );

$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'command: %s; program name: %s; job name: %s', p_command, p_program_name, l_job_name);
$end

    case p_command
      when 'create-jobs'
      then
        if p_program_name <> c_program_worker
        then
          create_job(l_job_name);
        end if;
        
      when 'drop-programs'
      then
        begin
          -- do not use does_program_exist() since does_program_exist may return null
          if not(does_program_exist(p_program_name))
          then
            -- does_program_exist() returns false
            null;
          else
            -- does_program_exist() returns true or null
            dbms_scheduler$drop_program(program_name => p_program_name);
          end if;
        exception
          when others
          then
$if oracle_tools.cfg_pkg.c_debugging $then
            dbug.on_error;
            dbug.print
            ( dbug."warning"
            , 'trying to drop program %s'
            , p_program_name
            );
$end
            raise;
        end;
      
      when 'drop-jobs'
      then
        <<force_loop>>
        for i_force in 0..1 -- 0: force false
        loop
          PRAGMA INLINE (get_jobs, 'YES');
          l_job_names := get_jobs(p_job_name_expr => l_job_name || '%');

$if oracle_tools.cfg_pkg.c_debugging $then
          dbug.print(dbug."info", q'[jobs found matching '%s%': %s]', l_job_name, l_job_names.count);
$end

          if l_job_names.count > 0
          then
            <<job_loop>>
            for i_job_idx in l_job_names.first .. l_job_names.last
            loop
              begin
                PRAGMA INLINE (drop_job, 'YES');
                drop_job(l_job_names(i_job_idx), i_force != 0);
              exception
                when others
                then
$if oracle_tools.cfg_pkg.c_debugging $then
                  dbug.on_error;
                  dbug.print
                  ( dbug."warning"
                  , 'trying to drop job %s'
                  , l_job_names(i_job_idx)
                  );
$end
                  if i_force != 0
                  then
                    raise;
                  end if;
              end;
            end loop job_loop;
          end if;
        end loop force_loop;
      
      when 'check-jobs-running'
      then
        PRAGMA INLINE (get_jobs, 'YES');
        l_job_names := get_jobs(l_job_name || '%', 'RUNNING');

        if l_job_names.count = 0
        then
          raise_application_error
          ( c_there_are_no_running_jobs
          , utl_lms.format_message
            ( c_there_are_no_running_jobs_msg
            , l_job_name || '%'
            )
          );
        end if;
        
      when 'check-jobs-not-running'
      then
        PRAGMA INLINE (get_jobs, 'YES');
        l_job_names := get_jobs(l_job_name || '%', 'RUNNING');
        if l_job_names.count > 0
        then
          raise_application_error
          ( c_there_are_running_jobs
          , utl_lms.format_message
            ( c_there_are_running_jobs_msg
            , l_job_name || '%'
            , chr(10) || oracle_tools.api_pkg.collection2list(p_value_tab => l_job_names, p_sep => chr(10), p_ignore_null => 1)
            )
          );
        end if;
        
      when 'start'
      then
        if p_program_name = c_program_launcher
        then
          begin
            -- this will create the job too if necessary
            processing_launcher(p_processing_package => l_processing_package);
          exception
            when e_no_groups_to_process
            then
              if msg_constants_pkg.get_default_processing_method like 'plsql://%'
              then
                null; -- use PL/SQL notifications hence this is plausible
              else
                declare
                  l_nr_queues pls_integer;
                begin
                  select  count(*)
                  into    l_nr_queues
                  from    user_queue_tables t
                          inner join user_queues q
                          on q.queue_table = t.queue_table
                  where   t.queue_table = trim('"' from msg_aq_pkg.c_queue_table);

                  if l_nr_queues > 0
                  then
                    -- this is strange so reraise
                    raise;
                  end if;
                end;
              end if;
          end;
        end if;

      when 'shutdown'
      then
        l_nr_groups := get_groups_to_process(l_processing_package).count;
        l_nr_workers := get_nr_workers(p_nr_groups => l_nr_groups);
$if oracle_tools.cfg_pkg.c_debugging $then
        dbug.print(dbug."info", 'nr groups: %s; nr workers: %s', l_nr_groups, l_nr_workers);
$end
        oracle_tools.api_heartbeat_pkg.shutdown
        ( p_supervisor_channel => $$PLSQL_UNIT
        , p_nr_workers => case when l_nr_workers > 0 then l_nr_workers end
        );

        <<sleep_loop>>
        for i_sleep in 1 .. l_shutdown_timeout
        loop
          PRAGMA INLINE (get_jobs, 'YES');
          exit sleep_loop when get_jobs(p_job_name_expr => l_job_name || '%', p_state => 'RUNNING').count = 0;
          dbms_session.sleep(1);
        end loop;

      when 'stop'
      then
        PRAGMA INLINE (get_jobs, 'YES');
        l_job_names := get_jobs(p_job_name_expr => l_job_name || '%');

$if oracle_tools.cfg_pkg.c_debugging $then
        dbug.print(dbug."info", q'[jobs found matching '%s%': %s]', l_job_name, l_job_names.count);
$end

        if l_job_names.count > 0
        then
          <<job_loop>>
          for i_job_idx in l_job_names.first .. l_job_names.last
          loop
            -- stop
            begin                  
              PRAGMA INLINE (stop_job, 'YES');
              stop_job(l_job_names(i_job_idx));
            exception
              when others
              then
$if oracle_tools.cfg_pkg.c_debugging $then
                dbug.on_error;
                dbug.print
                ( dbug."warning"
                , 'trying to stop job %s'
                , l_job_names(i_job_idx)
                );
$end
                raise; -- never ignore
            end;
            
            -- disable
            begin
              PRAGMA INLINE (change_job, 'YES');
              -- job exists since l_job_names only contains existing jobs
              change_job(p_job_name => l_job_names(i_job_idx), p_enabled => false);
            exception
              when others
              then
$if oracle_tools.cfg_pkg.c_debugging $then
                dbug.on_error;
                dbug.print
                ( dbug."warning"
                , 'trying to disable job %s'
                , l_job_names(i_job_idx)
                );
$end
                raise; -- never ignore
            end;
          end loop job_loop;
        end if;

      else
        raise_application_error
        ( c_unexpected_command
        , utl_lms.format_message
          ( c_unexpected_command_msg
          , p_command
          )
        );
    end case;
  end do_program_command;

  procedure cleanup
  is
  begin
    g_processing_package$ := null;
  end;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.DO (2)');
  dbug.print
  ( dbug."input"
  , 'p_command: %s; p_processing_package: %s'
  , p_command
  , p_processing_package
  );
$end

  if g_dry_run$
  then
    add_comment(p_command);
  end if;

  -- check for processing packages having both routine GET_GROUPS_TO_PROCESS and PROCESSING
  select  p.package_name
  bulk collect
  into    l_processing_package_tab
  from    user_arguments p
  where   p.object_name = 'GET_GROUPS_TO_PROCESS'
  and     ( l_processing_package is null or p.package_name like l_processing_package escape '\' )
  intersect
  select  p.package_name
  from    user_arguments p
  where   p.object_name = 'PROCESSING'
  and     ( l_processing_package is null or p.package_name like l_processing_package escape '\' )
  ;

  if l_processing_package_tab.count = 0
  then
    raise no_data_found;
  end if;

  <<processing_package_loop>>
  for i_package_idx in l_processing_package_tab.first .. l_processing_package_tab.last
  loop
    l_processing_package := l_processing_package_tab(i_package_idx);
    g_processing_package$ := l_processing_package;

$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'l_processing_package_tab(%s): %s', i_package_idx, l_processing_package_tab(i_package_idx));
$end

    <<command_loop>>
    for i_command_idx in l_command_tab.first .. l_command_tab.last
    loop
      case l_command_tab(i_command_idx)
        when 'drop-schedules'
        then
          <<schedule_loop>>
          for i_schedule_idx in l_schedule_tab.first .. l_schedule_tab.last
          loop
            begin
              if g_dry_run$
              then
                add_comment(utl_lms.format_message('command: %s; schedule: %s', l_command_tab(i_command_idx), l_schedule_tab(i_schedule_idx)));
              end if;
              if not(does_schedule_exist(l_schedule_tab(i_schedule_idx)))
              then
                null;
              else
                -- does_schedule_exist() returns true or null
                dbms_scheduler$drop_schedule(l_schedule_tab(i_schedule_idx));
              end if;
            end;
          end loop schedule_loop;

        else
          <<program_loop>>
          for i_program_idx in l_program_tab.first .. l_program_tab.last
          loop
            if g_dry_run$
            then
              add_comment(utl_lms.format_message('command: %s; program: %s', l_command_tab(i_command_idx), l_program_tab(i_program_idx)));
            end if;
            do_program_command(l_command_tab(i_command_idx), l_program_tab(i_program_idx));
          end loop program_loop;
      end case;
    end loop command_loop;
  end loop processing_package_loop;

  cleanup;
  commit;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end
exception
  when others
  then
    cleanup;
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.leave_on_error;
$end    
    raise;
end do;

procedure set_do_job_arguments
( p_job_name in job_name_t
, p_command in varchar2
, p_processing_package in varchar2
)
is
  l_argument_name user_scheduler_program_args.argument_name%type;
  
  function argument_value
  ( p_argument_name in varchar2
  )
  return varchar2
  is
  begin
    return
      case p_argument_name
        when 'P_COMMAND'
        then p_command
        when 'P_PROCESSING_PACKAGE'
        then p_processing_package
        else to_char(1/0) -- trick in order not to forget something
      end;
  end;    
begin
  -- Set the actual arguments for the next run.  
  if g_dry_run$
  then
    l_argument_name := g_programs(g_jobs(p_job_name).program_name).program_arguments.first;
    while l_argument_name is not null
    loop
      dbms_scheduler$set_job_argument_value
      ( job_name => p_job_name
      , argument_name => l_argument_name
      , argument_value => argument_value(l_argument_name)
      );
    
      l_argument_name := g_programs(g_jobs(p_job_name).program_name).program_arguments.next(l_argument_name);
    end loop;
  else
    for r in
    ( select  pa.argument_name
      ,       pa.argument_position 
      from    user_scheduler_jobs j
              inner join user_scheduler_program_args pa
              on pa.program_name = j.program_name
      where   job_name = p_job_name
      order by
              pa.argument_name
    )
    loop
      dbms_scheduler$set_job_argument_value
      ( job_name => p_job_name
      , argument_name => r.argument_name
      , argument_value => argument_value(r.argument_name)
      );
    end loop;
  end if;  
end set_do_job_arguments;

procedure submit_do
( p_command in varchar2
, p_processing_package in varchar2
)
is
  l_job_name_do job_name_t;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.SUBMIT_DO');
  dbug.print(dbug."input", 'p_command: %s; p_processing_package: %s', p_command, p_processing_package);
$end

  l_job_name_do :=
    join_job_name
    ( p_processing_package => p_processing_package
    , p_program_name => c_program_do
    );

  create_job(l_job_name_do);

  set_do_job_arguments
  ( p_job_name => l_job_name_do
  , p_command => p_command
  , p_processing_package => p_processing_package
  );

  change_job(p_job_name => l_job_name_do, p_enabled => true);

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end submit_do;

procedure set_processing_launcher_job_arguments
( p_job_name in job_name_t
, p_processing_package in varchar2
, p_nr_workers_each_group in positive
, p_nr_workers_exact in positive
)
is
  l_argument_name user_scheduler_program_args.argument_name%type;
  
  function argument_value
  ( p_argument_name in varchar2
  )
  return varchar2
  is
  begin
    return
      case p_argument_name
        when 'P_PROCESSING_PACKAGE'
        then p_processing_package
        when 'P_NR_WORKERS_EACH_GROUP'
        then to_char(p_nr_workers_each_group)
        when 'P_NR_WORKERS_EXACT'
        then to_char(p_nr_workers_exact)
        else to_char(1/0) -- trick to not forget something
      end;
  end;    
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.SET_PROCESSING_LAUNCHER_JOB_ARGUMENTS');
  dbug.print
  ( dbug."input"
  , 'p_job_name: %s; p_processing_package: %s; p_nr_workers_each_group: %s; p_nr_workers_exact: %s'
  , p_job_name
  , p_processing_package
  , p_nr_workers_each_group
  , p_nr_workers_exact
  );
$end

  -- Set the actual arguments for the next run.  
  if g_dry_run$
  then
    l_argument_name := g_programs(g_jobs(p_job_name).program_name).program_arguments.first;
    while l_argument_name is not null
    loop
      dbms_scheduler$set_job_argument_value
      ( job_name => p_job_name
      , argument_name => l_argument_name
      , argument_value => argument_value(l_argument_name)
      );
    
      l_argument_name := g_programs(g_jobs(p_job_name).program_name).program_arguments.next(l_argument_name);
    end loop;
  else
    for r in
    ( select  pa.argument_name
      ,       pa.argument_position
      from    user_scheduler_jobs j
              inner join user_scheduler_program_args pa
              on pa.program_name = j.program_name
      where   job_name = p_job_name
      order by
              pa.argument_name
    )
    loop
      dbms_scheduler$set_job_argument_value
      ( job_name => p_job_name
      , argument_name => r.argument_name
      , argument_value => argument_value(r.argument_name)
      );
    end loop;
  end if;
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end set_processing_launcher_job_arguments;

procedure submit_processing_launcher
( p_processing_package in varchar2
, p_nr_workers_each_group in positive
, p_nr_workers_exact in positive
)
is
  l_processing_package constant all_objects.object_name%type := determine_processing_package(p_processing_package);
  l_job_name_launcher job_name_t;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.SUBMIT_PROCESSING_LAUNCHER');
  dbug.print
  ( dbug."input"
  , 'p_processing_package: %s; p_nr_workers_each_group: %s; p_nr_workers_exact: %s'
  , p_processing_package
  , p_nr_workers_each_group
  , p_nr_workers_exact
  );
$end

  l_job_name_launcher :=
    join_job_name
    ( p_processing_package => l_processing_package
    , p_program_name => c_program_launcher
    );

  create_job(p_job_name => l_job_name_launcher);

  set_processing_launcher_job_arguments
  ( p_job_name => l_job_name_launcher
  , p_processing_package => p_processing_package
  , p_nr_workers_each_group => p_nr_workers_each_group
  , p_nr_workers_exact => p_nr_workers_exact
  );

  -- GO
  change_job(p_job_name => l_job_name_launcher, p_enabled => true);

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end submit_processing_launcher;

procedure processing_launcher
( p_processing_package in varchar2
, p_nr_workers_each_group in positive
, p_nr_workers_exact in positive
)
is
  l_processing_package constant all_objects.object_name%type := determine_processing_package(p_processing_package);
  l_job_name_launcher job_name_t := null;
  l_end_date user_scheduler_jobs.end_date%type := null;
  l_job_name_tab dbms_sql.varchar2s;
  l_groups_to_process_tab sys.odcivarchar2list;
  l_groups_to_process_list varchar2(4000 char);
  l_start constant oracle_tools.api_time_pkg.time_t := oracle_tools.api_time_pkg.get_time;
  l_elapsed_time oracle_tools.api_time_pkg.seconds_t;
  l_dbug_channel_tab dbug_channel_tab_t;
  l_session_job_name constant job_name_t := session_job_name();

  l_program_name constant varchar2(100 byte) := $$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESSING_LAUNCHER';

  procedure check_input_and_state
  is
  begin
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.enter(l_program_name || '.' || 'CHECK_INPUT_AND_STATE');
$end
  
    case
      when ( p_nr_workers_each_group is not null and p_nr_workers_exact is null ) or
           ( p_nr_workers_each_group is null and p_nr_workers_exact is not null )
      then null; -- ok
      else
        raise_application_error
        ( c_one_parameter_not_null
        , utl_lms.format_message
          ( c_one_parameter_not_null_msg
          , p_nr_workers_each_group -- since the type is positive, %d should work
          , p_nr_workers_exact -- idem
          )
        );
    end case;

    -- Is this session running as a job?
    -- If not, just create a job name launcher to be used by the worker jobs.
    
    l_job_name_launcher := l_session_job_name;

$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'g_dry_run$: %s', g_dry_run$);
$end

    if l_job_name_launcher is null
    then
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print
      ( dbug."warning"
      , utl_lms.format_message
        ( c_session_not_running_job_msg
        , to_char(c_session_id)
        )
      );
$end
      
      l_job_name_launcher := 
        join_job_name
        ( p_processing_package => l_processing_package
        , p_program_name => c_program_launcher
        );

      -- This session is not a running job: maybe the job does not exist yet so create/enable it to get a next_run_date
      if does_job_exist(l_job_name_launcher)
      then
        -- needed in dry run mode
        set_processing_launcher_job_arguments
        ( p_job_name => l_job_name_launcher
        , p_processing_package => p_processing_package
        , p_nr_workers_each_group => p_nr_workers_each_group
        , p_nr_workers_exact => p_nr_workers_exact
        );
        change_job(p_job_name => l_job_name_launcher, p_enabled => true);
      else
        submit_processing_launcher
        ( p_processing_package => p_processing_package
        , p_nr_workers_each_group => p_nr_workers_each_group
        , p_nr_workers_exact => p_nr_workers_exact
        );
      end if;

    elsif l_job_name_launcher <>
          join_job_name
          ( p_processing_package => l_processing_package
          , p_program_name => c_program_launcher
          )
    then
      raise value_error;
    end if;

    -- the job exists and is enabled or even running so the next call will return the next end date
    if g_dry_run$
    then
      l_end_date := systimestamp() + interval '1' hour;
    else
      get_next_end_date(l_job_name_launcher, l_end_date);
    end if;

$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.print(dbug."info", 'system date: %s', to_char(systimestamp, "yyyy-mm-dd hh24:mi:ss"));
$end

    if l_end_date > systimestamp()
    then
      null;
    else
      raise_application_error
      ( c_end_date_not_in_the_future
      , utl_lms.format_message
        ( c_end_date_not_in_the_future_msg
        , to_char(l_end_date, "yyyy-mm-dd hh24:mi:ss")
        , to_char(systimestamp(), "yyyy-mm-dd hh24:mi:ss")
        )
      );
    end if;

    l_groups_to_process_tab := get_groups_to_process(l_processing_package);

    if l_groups_to_process_tab.count = 0
    then
      raise_application_error
      ( c_no_groups_to_process
      , utl_lms.format_message(c_no_groups_to_process_msg, l_processing_package)
      );
    end if;

    l_groups_to_process_list :=
      oracle_tools.api_pkg.collection2list
      ( p_value_tab => l_groups_to_process_tab
      , p_sep => ','
      , p_ignore_null => 1
      );
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.leave;
$end
  end check_input_and_state;

  procedure define_jobs
  is
    -- nr of workers must be > 0
    l_nr_workers constant positiven :=
      get_nr_workers
      ( p_nr_groups => l_groups_to_process_tab.count
      , p_nr_workers_each_group => p_nr_workers_each_group
      , p_nr_workers_exact => p_nr_workers_exact
      );
  begin
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.enter(l_program_name || '.' || 'DEFINE_JOBS');
    dbug.print(dbug."info", 'l_nr_workers: %s', l_nr_workers);
$end
    -- Create the job name list of supervisor and workers
    for i_worker_nr in 0 .. l_nr_workers
    loop
      l_job_name_tab(i_worker_nr) :=
        join_job_name
        ( p_processing_package => p_processing_package
        , p_program_name => case when i_worker_nr = 0 then c_program_supervisor else c_program_worker end
        , p_worker_nr => case when i_worker_nr = 0 then null else i_worker_nr end
        );
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."info", 'l_job_name_tab(%s): %s', i_worker_nr, l_job_name_tab(i_worker_nr));
$end
    end loop;
    
    -- Shutdown supervisor and workers, if any
    begin
      oracle_tools.api_heartbeat_pkg.shutdown
      ( p_supervisor_channel => $$PLSQL_UNIT
      , p_nr_workers => l_nr_workers
      );
    exception
      when oracle_tools.api_heartbeat_pkg.e_shutdown_request_failed
      then null;
    end;
    
    <<job_loop>>
    for i_job_idx in l_job_name_tab.first .. l_job_name_tab.last
    loop
      begin                  
        -- stop worker jobs
        PRAGMA INLINE (stop_job, 'YES');
        stop_job(l_job_name_tab(i_job_idx));
      exception
        when others
        then
$if oracle_tools.cfg_pkg.c_debugging $then
          dbug.on_error;
          dbug.print
          ( dbug."warning"
          , 'trying to stop job %s'
          , l_job_name_tab(i_job_idx)
          );
$end
          null;
      end;
    end loop job_loop;
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.leave;
$end
  end define_jobs;

  procedure start_jobs
  is
  begin    
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.enter(l_program_name || '.' || 'START_JOB');
$end
    if l_job_name_tab.count > 1 -- exclude supervisor
    then
      -- submit also the supervisor (index 0 but must have p_worker_nr null)
      <<worker_loop>>
      for i_worker_nr in l_job_name_tab.first .. l_job_name_tab.last
      loop
$if oracle_tools.cfg_pkg.c_debugging $then
        dbug.print(dbug."info", 'i_worker_nr: %s', i_worker_nr);
$end
        submit_processing
        ( p_processing_package => p_processing_package
        , p_groups_to_process_list => l_groups_to_process_list
        , p_nr_workers => l_job_name_tab.count
        , p_worker_nr => case when i_worker_nr = 0 then null else i_worker_nr end
        , p_end_date => l_end_date
        );
      end loop worker_loop;
    end if;
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.leave;
$end
  end start_jobs;

  procedure cleanup
  is
  begin
    if l_session_job_name is not null
    then
      done(l_dbug_channel_tab);
    end if;
  end cleanup;
begin
  if l_session_job_name is not null
  then
    init(l_dbug_channel_tab);
  end if;
  
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter(l_program_name);
  dbug.print
  ( dbug."input"
  , utl_lms.format_message
    ( 'p_processing_package: %s; p_nr_workers_each_group: %d; p_nr_workers_exact: %d'
    , p_processing_package
    , p_nr_workers_each_group
    , p_nr_workers_exact
    )
  );
$end

  check_input_and_state;
  define_jobs;
  start_jobs;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end

  cleanup; -- after dbug.leave since the done inside will change dbug state

exception
  when others
  then
    if g_dry_run$
    then
      add_comment(substr(sqlerrm, 1, 2000));
    end if;  
    
$if oracle_tools.cfg_pkg.c_debugging $then  
    dbug.leave_on_error;
$end

    cleanup; -- after dbug.leave_on_error since the done inside will change dbug state
    raise;
end processing_launcher;

procedure processing
( p_processing_package in varchar2 
, p_groups_to_process_list in varchar2
, p_nr_workers in positiven
, p_worker_nr in positive
, p_end_date in varchar2
)
is
  l_processing_package constant all_objects.object_name%type := determine_processing_package(p_processing_package);
  l_groups_to_process_tab sys.odcivarchar2list;
  l_end_date constant oracle_tools.api_time_pkg.timestamp_t := oracle_tools.api_time_pkg.str2timestamp(p_end_date);
  -- for the heartbeat
  l_silence_threshold oracle_tools.api_time_pkg.seconds_t := msg_constants_pkg.get_time_between_heartbeats * 2;
  l_dbug_channel_tab dbug_channel_tab_t;
  l_session_job_name constant job_name_t := session_job_name();

  procedure restart_workers
  ( p_silent_worker_tab in oracle_tools.api_heartbeat_pkg.silent_worker_tab_t
  , p_silence_threshold in out nocopy oracle_tools.api_time_pkg.seconds_t
  )
  is
  begin
$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESSING.RESTART_WORKERS');
$end

    if p_silent_worker_tab is null or p_silent_worker_tab.count = 0
    then
      raise program_error;
    end if;

    if p_silence_threshold >= msg_constants_pkg.get_max_silence_threshold
    then
      submit_do('restart', p_processing_package);
      raise_application_error
      ( oracle_tools.api_heartbeat_pkg.c_silent_workers_found
      , utl_lms.format_message
        ( 'There are %s workers silent since at least %s seconds.'
        , to_char(p_silent_worker_tab.count)
        , to_char(p_silence_threshold)
        )
      );
    end if;
    
    p_silence_threshold := p_silence_threshold + msg_constants_pkg.get_time_between_heartbeats;
 
    <<worker_loop>>
    for i_idx in p_silent_worker_tab.first .. p_silent_worker_tab.last
    loop
      if not
         ( is_job_running
           ( join_job_name
             ( p_processing_package
             , case when p_silent_worker_tab(i_idx) > 0 then c_program_worker else c_program_supervisor end
             , p_silent_worker_tab(i_idx)
             )
           )
         )
      then
        submit_processing
        ( p_processing_package => p_processing_package
        , p_groups_to_process_list => p_groups_to_process_list
        , p_nr_workers => p_nr_workers
        , p_worker_nr => p_silent_worker_tab(i_idx)
        , p_end_date => l_end_date -- all jobs in the worker group are supposed to have the same end date
        );
      end if;
    end loop worker_loop;

$if oracle_tools.cfg_pkg.c_debugging $then
    dbug.leave;
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end  
  end restart_workers;

  procedure processing_supervisor
  is
    l_start_date constant oracle_tools.api_time_pkg.timestamp_t := oracle_tools.api_time_pkg.get_timestamp;
    l_ttl constant positiven := oracle_tools.api_time_pkg.delta(l_start_date, l_end_date);
    l_now oracle_tools.api_time_pkg.timestamp_t;
    l_elapsed_time oracle_tools.api_time_pkg.seconds_t;
    -- for the heartbeat
    l_timestamp_tab oracle_tools.api_heartbeat_pkg.timestamp_tab_t;
    l_silent_worker_tab oracle_tools.api_heartbeat_pkg.silent_worker_tab_t;

    procedure cleanup
    is
    begin
      oracle_tools.api_heartbeat_pkg.done
      ( p_supervisor_channel => $$PLSQL_UNIT
      , p_worker_nr => null
      );
    end cleanup;
  begin
    oracle_tools.api_heartbeat_pkg.init
    ( p_supervisor_channel => $$PLSQL_UNIT
    , p_worker_nr => null
    , p_max_worker_nr => p_nr_workers
    , p_timestamp_tab => l_timestamp_tab
    );
    
    <<process_loop>>
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

      oracle_tools.api_heartbeat_pkg.recv
      ( p_supervisor_channel => $$PLSQL_UNIT
      , p_silence_threshold => l_silence_threshold
      , p_first_recv_timeout => least
                                ( msg_constants_pkg.get_time_between_heartbeats
                                , greatest
                                  ( 1 -- don't use 0 but 1 second as minimal timeout since 0 seconds may kill your server
                                  , trunc(l_ttl - l_elapsed_time)
                                  )
                                )
      , p_timestamp_tab =>l_timestamp_tab
      , p_silent_worker_tab => l_silent_worker_tab
      );

      if l_silent_worker_tab is not null and l_silent_worker_tab.count > 0
      then
        restart_workers(l_silent_worker_tab, l_silence_threshold);
      end if;
    end loop process_loop;

    cleanup;
  exception
    when oracle_tools.api_heartbeat_pkg.e_shutdown_request_forwarded
    then
      -- log the shutdown anyhow (although it is okay) otherwise the error gets lost
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.on_error;
$end
      cleanup;
      -- no re-raise since it is a normal way to stop working
      
    when others
    then
      -- error gets logged below
      cleanup;
      raise;
  end processing_supervisor;

  procedure processing_worker
  is
    l_statement constant varchar2(32767 byte) :=
      utl_lms.format_message
      ( q'[
call %s.processing( p_controlling_package => :1
                  , p_groups_to_process_tab => :2
                  , p_worker_nr => :3
                  , p_end_date => :4
                  , p_silence_threshold => :5
                  )]'
      , l_processing_package -- already checked by determine_processing_package
      );    
    -- ORA-06550: line 1, column 18:
    -- PLS-00302: component 'PROCESING' must be declared
    e_compilation_error exception;
    pragma exception_init(e_compilation_error, -6550);
  begin
    <<processing_loop>>
    loop
      begin
        execute immediate l_statement
          using in $$PLSQL_UNIT, in l_groups_to_process_tab, in p_worker_nr, in l_end_date, in l_silence_threshold;
          
        exit processing_loop; -- no error so stop
      exception
        when oracle_tools.api_heartbeat_pkg.e_silent_workers_found
        then
          -- just the supervisor is silent
          restart_workers
          ( p_silent_worker_tab => sys.odcinumberlist(null) -- null means supervisor
          , p_silence_threshold => l_silence_threshold
          );
          -- no re-raise because we want to try again till the silence threshold is too large
      end;
    end loop processing_loop;
    
  exception
    when e_compilation_error
    then
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.print(dbug."error", 'statement: %s', l_statement);
$end                  
      raise;

    when oracle_tools.api_heartbeat_pkg.e_shutdown_request_received
    then
      -- log the shutdown anyhow (although it is okay) otherwise the error gets lost
$if oracle_tools.cfg_pkg.c_debugging $then
      dbug.on_error;
$end
      null;
      -- no re-raise since it is a normal way to stop working
  end processing_worker;
  
  procedure cleanup
  is
  begin
    if l_session_job_name is not null
    then
      done(l_dbug_channel_tab);
    end if;
  end cleanup;
begin
  if l_session_job_name is not null
  then
    init(l_dbug_channel_tab);
  end if;  

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESSING');
  dbug.print
  ( dbug."input"
  , 'p_processing_package: %s; p_groups_to_process_list: %s; p_nr_workers: %s; p_worker_nr: %s; p_end_date: %s'
  , p_processing_package
  , p_groups_to_process_list
  , p_nr_workers
  , p_worker_nr
  , to_char(l_end_date, "yyyy-mm-dd hh24:mi:ss")
  );
$end

  if l_end_date > systimestamp()
  then
    null;
  else
    raise_application_error
    ( c_end_date_not_in_the_future
    , utl_lms.format_message
      ( c_end_date_not_in_the_future_msg
      , to_char(l_end_date, "yyyy-mm-dd hh24:mi:ss")
      , to_char(systimestamp(), "yyyy-mm-dd hh24:mi:ss")
      )
    );
  end if;

  if not g_dry_run$ and l_session_job_name is null
  then
    raise_application_error
    ( c_session_not_running_job
    , utl_lms.format_message
      ( c_session_not_running_job_msg
      , to_char(c_session_id)
      )
    );
  end if;

  select  pg.column_value
  bulk collect
  into    l_groups_to_process_tab
  from    table(oracle_tools.api_pkg.list2collection(p_value_list => p_groups_to_process_list, p_sep => ',', p_ignore_null => 1)) pg;

  if p_worker_nr is null
  then
    processing_supervisor;
  else
    processing_worker;
  end if;

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.leave;
$end  

  cleanup;
exception
  when others
  then
$if oracle_tools.cfg_pkg.c_debugging $then  
    dbug.leave_on_error;
$end    
    cleanup;
    raise;
end processing;

end msg_scheduler_pkg;
/

