CREATE OR REPLACE PACKAGE BODY "API_LONGOPS_PKG" -- -*-coding: utf-8-*-
is

g_longops_counter positiven := 1;

function longops_init
( p_target_desc in varchar2
, p_totalwork in binary_integer default 0
, p_op_name in varchar2 default 'fetch'
, p_units in varchar2 default 'rows'
)
return t_longops_rec
is
  l_longops_rec t_longops_rec;
begin
  l_longops_rec.rindex := dbms_application_info.set_session_longops_nohint;
  l_longops_rec.slno := null;
  l_longops_rec.sofar := 0;
  l_longops_rec.totalwork := p_totalwork;
  l_longops_rec.op_name := p_op_name;
  l_longops_rec.units := p_units;
  l_longops_rec.target_desc := p_target_desc || '@' || g_longops_counter;

  longops_show(l_longops_rec, 0);

  g_longops_counter := g_longops_counter + 1;

  return l_longops_rec;
end longops_init;

procedure longops_show
( p_longops_rec in out nocopy t_longops_rec
, p_increment in naturaln default 1
)
is
begin
  p_longops_rec.sofar := p_longops_rec.sofar + p_increment;
  dbms_application_info.set_session_longops( rindex => p_longops_rec.rindex
                                           , slno => p_longops_rec.slno
                                           , op_name => p_longops_rec.op_name
                                           , sofar => p_longops_rec.sofar
                                           , totalwork => p_longops_rec.totalwork
                                           , target_desc => p_longops_rec.target_desc
                                           , units => p_longops_rec.units
                                           );
end longops_show;                                             

procedure longops_done
( p_longops_rec in out nocopy t_longops_rec
)
is
begin
  if p_longops_rec.totalwork = p_longops_rec.sofar
  then
    null; -- nothing has changed and dbms_application_info.set_session_longops() would show a duplicate
  else
    p_longops_rec.totalwork := p_longops_rec.sofar;
    longops_show(p_longops_rec, 0);
  end if;
end longops_done;

end API_LONGOPS_PKG;
/

