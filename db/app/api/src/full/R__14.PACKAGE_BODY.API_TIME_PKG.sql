CREATE OR REPLACE PACKAGE BODY "API_TIME_PKG" -- -*-coding: utf-8-*-
is

function get_time
return time_t
is
begin
  return dbms_utility.get_time;
end get_time;

function get_timestamp
return timestamp_t
is
begin
  return systimestamp();
end get_timestamp;

function elapsed_time
( p_start in time_t
, p_end in time_t
)
return seconds_t
is
  l_min constant number := -2147483648;
  l_max constant number :=  2147483647;
/**
Determines the elapsed time in fractional seconds (not hundredths!) between two measure points taken by dbms_utility.get_time, the start (earlier) and the end (later).

The function dbms_utility.get_time returns the number of hundredths of a second from the point in time at which the subprogram is invoked.

Numbers are returned in the range -2147483648 to 2147483647 depending on
platform and machine, and your application must take the sign of the number
into account in determining the interval. For instance, in the case of two
negative numbers, application logic must allow that the first (earlier) number
will be larger than the second (later) number which is closer to zero. By the
same token, your application should also allow that the first (earlier) number
be negative and the second (later) number be positive.
**/
begin
  -- EXAMPLES
  --
  --    p_start |       p_end | result
  --    ======= |       ===== | ======
  --          1 |           2 |  1/100
  --         -3 |          -1 |  1/100
  -- 2147483646 | -2147483647 |  3/100
  --         -1 |           3 |  4/100
  return case
           when p_start >= 0 and p_end >= 0 then (p_end - p_start)
           -- both p_start and p_end went thru l_max
           when p_start <  0 and p_end <  0 then (p_end - p_start)
           -- p_end went thru l_max
           when p_start >= 0 and p_end <  0 then (l_max - p_start) + (p_end - l_min) + 1
           -- count p_start till 0 and 0 till p_end
           when p_start <  0 and p_end >= 0 then (p_end + -1 * p_start)
         end / 100;
end elapsed_time;

function elapsed_time
( p_start in timestamp_t
, p_end in timestamp_t
)
return seconds_t
is
  l_interval constant timestamp_diff_t := sys_extract_utc(p_end) - sys_extract_utc(p_start);
begin
  return extract(day from l_interval) * 24 * 60 * 60 +
         extract(hour from l_interval) * 60 * 60 +
         extract(minute from l_interval) * 60 +
         extract(second from l_interval);
end elapsed_time;

end API_TIME_PKG;
/

