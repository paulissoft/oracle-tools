CREATE OR REPLACE PACKAGE "API_TIME_PKG" AUTHID DEFINER
is

subtype time_t is number; -- return value of dbms_utility.get_time()
subtype timestamp_t is timestamp(6) with time zone; -- return value of systimestamp()
subtype timestamp_diff_t is interval day(9) to second(6);
subtype seconds_t is number; -- before the decimal the number of seconds, after the decimal the fractional seconds
subtype timestamp_str_t is varchar2(33 char);

c_timestamp_format constant varchar2(37 char) := 'YYYY-MM-DD"T"HH24:MI:SS.FF6"Z"TZH:TZM';

/**
Package to give a rough estimate of the elapsed time in seconds and fractional seconds.
The granularity is what is returned by dbms_utility.get_time, i.e hundredths of seconds.

Notes:
1. the SYS_EXTRACT_UTC() returns a value with datatype TIMESTAMP, not TIMESTAMP WITH TIME ZONE. So do NOT use that.
2. SYSTIMESTAMP() and CURRENT_TIMESTAMP() have datatype TIMESTAMP WITH TIME ZONE.
**/

function get_time
return time_t;
/** Get the time in seconds with fractions (not hundredths of seconds!). Just returns dbms_utility.get_time. **/

function get_timestamp
return timestamp_t;
/** Get the current timestamp. Just returns systimestamp(). **/

function elapsed_time
( p_start in time_t -- start value returned by get_time
, p_end in time_t -- end value returned by get_time
)
return seconds_t; -- in seconds with fractions (not hundredths of seconds!)
/**
Determines the elapsed time in seconds (not hundredths of seconds!) between two measure points taken by get_time(), the start (earlier) and the end (later).

The function dbms_utility.get_time returns the number of hundredths of a second from the point in time at which the subprogram is invoked.

Numbers are returned in the range -2147483648 to 2147483647 depending on
platform and machine, and your application must take the sign of the number
into account in determining the interval. For instance, in the case of two
negative numbers, application logic must allow that the first (earlier) number
will be larger than the second (later) number which is closer to zero. By the
same token, your application should also allow that the first (earlier) number
be negative and the second (later) number be positive.
**/

function delta
( p_start in time_t -- start value returned by get_time
, p_end in time_t -- end value returned by get_time
)
return seconds_t; -- in seconds with fractions (not hundredths of seconds!)
/** Just another name for elapsed_time above. **/

function elapsed_time
( p_start in timestamp_t -- start value returned by get_timestamp
, p_end in timestamp_t -- end value returned by get_timestamp
)
return seconds_t; -- in seconds with fractions (not hundredths of seconds!)
/**
Determines the elapsed time in seconds (and fractional seconds) between two measure points taken by get_timestamp(), the start (earlier) and the end (later).
The DAY, HOUR, MINUTE and SECOND will be EXTRACTed from the difference interval.
**/

function delta
( p_start in timestamp_t -- start value returned by get_timestamp
, p_end in timestamp_t -- end value returned by get_timestamp
)
return seconds_t; -- in seconds with fractions (not hundredths of seconds!)
/** Just another name for elapsed_time above. **/

function timestamp2str
( p_val in timestamp_t
)
return timestamp_str_t;
/** Return the timestamp value in 'YYYY-MM-DD"T"HH24:MI:SS.FF6"Z"' format. */

function str2timestamp
( p_val in timestamp_str_t
)
return timestamp_t;
/** Return the timestamp string value (in 'YYYY-MM-DD"T"HH24:MI:SS.FF6"Z"' format) as a timestamp with time zone. */

function get_timestamp_str
return timestamp_str_t;
/** Get the current timestamp as a string. Just returns systimestamp() (in 'YYYY-MM-DD"T"HH24:MI:SS.FF6"Z"' format). **/

$if oracle_tools.cfg_pkg.c_testing $then

--%suitepath(API)
--%suite

--%test
procedure ut_get_timestamp;

--%test
procedure ut_delta;

--%test
procedure ut_timestamp2str;

--%test
procedure ut_str2timestamp;

$end

end API_TIME_PKG;
/

