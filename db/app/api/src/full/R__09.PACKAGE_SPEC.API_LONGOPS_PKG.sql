CREATE OR REPLACE PACKAGE "API_LONGOPS_PKG" authid definer
is

type t_longops_rec is record (
  rindex binary_integer
, slno binary_integer
, sofar binary_integer
, totalwork binary_integer
, op_name varchar2(64 char)
, units varchar2(10 char)
, target_desc varchar2(32 char)
);

function longops_init
( p_target_desc in varchar2
, p_totalwork in binary_integer default 0
, p_op_name in varchar2 default 'fetch'
, p_units in varchar2 default 'rows'
)
return t_longops_rec;

procedure longops_show
( p_longops_rec in out nocopy t_longops_rec
, p_increment in naturaln default 1
);

procedure longops_done
( p_longops_rec in out nocopy t_longops_rec
);

end API_LONGOPS_PKG;
/

