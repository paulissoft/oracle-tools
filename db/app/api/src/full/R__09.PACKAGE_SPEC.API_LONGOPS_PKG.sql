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

/**
This package is a wrapper around DBMS_APPLICATION_INFO.SET_SESSION_LONGOPS() and makes it easier to use it.
**/

function longops_init
( p_target_desc in varchar2 -- See DBMS_APPLICATION_INFO.SET_SESSION_LONGOPS()
, p_totalwork in binary_integer default 0 -- Idem
, p_op_name in varchar2 default 'fetch' -- Idem
, p_units in varchar2 default 'rows' -- Idem
)
return t_longops_rec;
/** Initialize a longops operation. **/

procedure longops_show
( p_longops_rec in out nocopy t_longops_rec
, p_increment in naturaln default 1 -- The increment for sofar
);
/** Some work has been done (SOFAR will be incremented by P_INCREMENT) and this call updates the longops operation. **/

procedure longops_done
( p_longops_rec in out nocopy t_longops_rec
);
/** Finish a longops operation: TOTALWORK will be set to SOFAR if necessary. **/

end API_LONGOPS_PKG;
/

