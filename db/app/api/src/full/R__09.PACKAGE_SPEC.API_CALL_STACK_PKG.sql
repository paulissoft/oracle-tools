CREATE OR REPLACE PACKAGE "API_CALL_STACK_PKG" authid definer
is

subtype t_repr_tab is utl_call_stack.unit_qualified_name; -- a table type allowing us to use member of

/**

This package is a layer on top of UTL_CALL_STACK. It reverses the direction of a call stack compared to UTL_CALL_STACK which has the newest call entries at the lowest index entries. For instance the call with dynamic depth equal to UTL_CALL_STACK.DYNAMIC_DEPTH is the oldest (first) call. In this package it is the reverse which has as advantage that an entry in the call stack with dynamic depth equal to X will still have the same dynamic depth when another call is made. 

The same is true for the error stack: originating error first but that was already the case for UTL_CALL_STACK.

The same is true for the backtrace stack: originating call first unlike UTL_CALL_STACK.

**/

type t_call_stack_rec is record
( dynamic_depth pls_integer
, lexical_depth pls_integer
, owner all_objects.owner%type
, unit_type all_objects.object_type%type
, subprogram utl_call_stack.unit_qualified_name
, name varchar2(32767) -- the result of UTL_CALL_STACK.CONCATENATE_SUBPROGRAM() 
, unit_line pls_integer
);

/**

The call stack record type.

**/

type t_call_stack_tab is table of t_call_stack_rec index by binary_integer;

/**

The call stack table type.

**/

type t_error_stack_rec is record
( error_depth pls_integer
, error_number pls_integer
, error_msg varchar2(32767)
);

/**

The error stack record type.

**/


type t_error_stack_tab is table of t_error_stack_rec index by binary_integer;

/**

The error stack table type.

**/

type t_backtrace_stack_rec is record
( backtrace_depth pls_integer
, backtrace_line pls_integer
, backtrace_unit varchar2(32767)
);

/**

The backtrace stack record type.

**/

type t_backtrace_stack_tab is table of t_backtrace_stack_rec index by binary_integer;

/**

The backtrace stack table type.

**/

function get_call_stack
( p_start in pls_integer default 1 -- You can use -1 like the POSITION parameter in the SUBSTR() function
, p_size in naturaln default utl_call_stack.dynamic_depth -- This will skip the call to API_CALL_STACK_PKG.GET_CALL_STACK() itself
)
return t_call_stack_tab;

/**

Get the call stack as defined by UTL_CALL_STACK but with the oldest call first. 
The dynamic_depth field will be the same as the index in the output array.

The default invocation get_call_stack will return an array of length
utl_call_stack.dynamic_depth with the first entry having field dynamic_depth
equal to 1 and the last entry has dynamic_depth equal to
utl_call_stack.dynamic_depth.

**/

function repr
( p_call_stack_rec in t_call_stack_rec
)
return varchar2
deterministic;

/**

Get the representation of a call that is a string with these fields separated by a bar (|):
- dynamic_depth
- lexical_depth
- owner
- unit_type
- name
- unit_line

**/

function repr
( p_call_stack_tab in t_call_stack_tab
)
return t_repr_tab
deterministic;

/**

Get the representation of each call and return those representations.

**/

function get_error_stack
( p_start in pls_integer default 1 -- You can use -1 like the POSITION parameter in the SUBSTR() function
, p_size in naturaln default utl_call_stack.error_depth
)
return t_error_stack_tab;

/**

Get the error stack as defined by UTL_CALL_STACK but with the oldest call first. 
The error_depth field will be the same as the index in the output array.

**/

function repr
( p_error_stack_rec in t_error_stack_rec
)
return varchar2
deterministic;

/**

Get the representation of an error call that is a string with these fields separated by a bar (|):
- error_depth
- error_number
- error_msg

**/

function repr
( p_error_stack_tab in t_error_stack_tab
)
return t_repr_tab
deterministic;

/**

Get the representation of each error call and return those representations.

**/

function get_backtrace_stack
( p_start in pls_integer default 1 -- You can use -1 like the POSITION parameter in the SUBSTR() function
, p_size in naturaln default utl_call_stack.backtrace_depth
)
return t_backtrace_stack_tab;

/**

Get the backtrace stack as defined by UTL_CALL_STACK but with the oldest backtrace first. 
The backtrace_depth field will be the same as the index in the output array.

**/

function repr
( p_backtrace_stack_rec in t_backtrace_stack_rec
)
return varchar2
deterministic;

/**

Get the representation of a backtrace call that is a string with these fields separated by a bar (|):
- backtrace_depth
- backtrace_line
- backtrace_unit

**/

function repr
( p_backtrace_stack_tab in t_backtrace_stack_tab
)
return t_repr_tab
deterministic;

/**

Get the representation of each backtrace call and return those representations.

**/

procedure show_stack
( p_where_am_i in varchar2 -- place to show
);

/**

Show the current call, error and backtrace stack using DBMS_OUTPUT.

**/

$if cfg_pkg.c_testing $then

--%suitepath(API)
--%suite

--%test
procedure ut_get_call_stack;

--%test
procedure ut_get_error_stack;

--%test
procedure ut_get_backtrace_stack;

$end

end API_CALL_STACK_PKG;
/

