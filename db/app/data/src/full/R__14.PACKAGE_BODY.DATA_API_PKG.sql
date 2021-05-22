create or replace package body DATA_API_PKG
is

-- LOCAL


-- GLOBAL

function get_owner
return all_objects.owner%type
is
begin
  return sys_context('userenv', 'current_schema');
end get_owner;

procedure raise_error
( p_error_code in varchar2
, p_p1 in varchar2 default null
, p_p2 in varchar2 default null
, p_p3 in varchar2 default null
, p_p4 in varchar2 default null
, p_p5 in varchar2 default null
, p_p6 in varchar2 default null
, p_p7 in varchar2 default null
, p_p8 in varchar2 default null
, p_p9 in varchar2 default null
)
is
  l_p varchar2(32767);
  l_error_message varchar2(2000) := "#" || p_error_code;
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.RAISE_ERROR');
  dbug.print
  ( dbug."input"
  , 'p_error_code: %s; p_p1: %s; p_p2: %s; p_p3: %s; p_p4: %s'
  , p_error_code
  , p_p1
  , p_p2
  , p_p3
  , p_p4
  );
  dbug.print
  ( dbug."input"
  , 'p_p5: %s; p_p6: %s; p_p7: %s; p_p8: %s; p_p9: %s'
  , p_p5
  , p_p6
  , p_p7
  , p_p8
  , p_p9
  );
$end

  if p_error_code is null
  then
    raise value_error;
  end if;

  <<append_loop>>
  for i_idx in 1..9
  loop
    l_p :=
      case i_idx
        when 1 then p_p1
        when 2 then p_p2
        when 3 then p_p3
        when 4 then p_p4
        when 5 then p_p5
        when 6 then p_p6
        when 7 then p_p7
        when 8 then p_p8
        when 9 then p_p9
      end;

    l_error_message := l_error_message || "#" || l_p;
  end loop append_loop;

  -- strip empty parameters from the end
  l_error_message := rtrim(l_error_message, '#');

  raise_application_error(c_exception, l_error_message);
  
$if cfg_pkg.c_debugging $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end  
end raise_error;

procedure raise_error_overlap
( p_error_code in varchar2
, p_lwb1 in varchar2
, p_upb1 in varchar2
, p_lwb2 in varchar2
, p_upb2 in varchar2
, p_lwb_incl boolean
, p_upb_incl boolean
, p_key1 in varchar2
, p_key2 in varchar2
, p_key3 in varchar2
)
is
begin
  data_api_pkg.raise_error
  ( p_error_code => p_error_code
  , p_p1 => case when p_lwb_incl then '[' else '(' end || p_lwb1 || ', ' || p_upb1 || case when p_upb_incl then ']' else ')' end
  , p_p2 => case when p_lwb_incl then '[' else '(' end || p_lwb2 || ', ' || p_upb2 || case when p_upb_incl then ']' else ')' end
  , p_p3 => p_key1
  , p_p4 => p_key2
  , p_p5 => p_key3
  );
end raise_error_overlap;

function show_job_status
( p_job_name in all_scheduler_job_run_details.job_name%type
, p_start_date_min in all_scheduler_job_run_details.actual_start_date%type
)
return t_job_status_tab
pipelined
is
begin
$if cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT || '.SHOW_JOB_STATUS');
  dbug.print
  ( dbug."input"
  , 'p_job_name: %s; p_start_date_min: %s'
  , p_job_name, to_char(p_start_date_min, 'YYYY-MM-DD HH24:MI:SS TZR')
  );
$end

  for r in
  ( select  t.job_name
    ,       t.status
    ,       t.actual_start_date
    ,       t.errors
    from    ( select  *
              from    all_scheduler_job_run_details
              where   all_scheduler_job_run_details.job_name = p_job_name
              and     ( p_start_date_min is null
                        or
                        all_scheduler_job_run_details.actual_start_date >= p_start_date_min
                      )
              order by
                      log_date desc
            ) t
    where   rownum = 1 -- show the latest job
  )
  loop
    pipe row (r);
  end loop;

$if cfg_pkg.c_debugging $then
  dbug.leave;
$end

  return; -- essential
exception
  when no_data_needed
  then
$if cfg_pkg.c_debugging $then
    dbug.leave_on_error;
$end
    null; -- not a real error, just a way to some cleanup

  when no_data_found -- verdwijnt anders in het niets omdat het een pipelined function betreft die al data ophaalt
  then
$if cfg_pkg.c_debugging $then
    dbug.leave_on_error;
$end
    raise program_error;

  when others
  then
$if cfg_pkg.c_debugging $then
    dbug.leave_on_error;
$end
    raise;
end show_job_status;

$if cfg_pkg.c_testing $then

procedure ut_raise_error
is
  l_msg_exp varchar2(4000 char);
begin
  for i_idx in 1..6
  loop
    begin
      case i_idx
        when 1
        then l_msg_exp := '#'; raise_error(null);             
        when 2
        then l_msg_exp := '#abc'; raise_error('abc');
        when 3
        then l_msg_exp := '#def#p1'; raise_error('def', p_p1 => 'p1');
        when 4
        then l_msg_exp := '#ghi##p2'; raise_error('ghi', p_p2 => 'p2');
        when 5
        then l_msg_exp := '#jkl#########p9'; raise_error('jkl', p_p9 => 'p9');
        when 6
        then l_msg_exp := '#MNO#a#b#c#d#e#f#g#h#i'; raise_error('MNO', p_p1 => 'a', p_p2 => 'b', p_p3 => 'c', p_p4 => 'd', p_p5 => 'e', p_p6 => 'f', p_p7 => 'g', p_p8 => 'h', p_p9 => 'i');
      end case;
      raise program_error;
    exception
      when others
      then
        case i_idx
          when 1
          then
            ut.expect(sqlcode, 'sqlcode '|| i_idx).to_equal(-6502);
            
          else
            ut.expect(sqlcode, 'sqlcode '|| i_idx).to_equal(c_exception);
            ut.expect(sqlerrm, 'sqlerrm '|| i_idx).to_be_like('%'||l_msg_exp||'%');
        end case;
    end;
  end loop;
end ut_raise_error;

$end

end DATA_API_PKG;
/

