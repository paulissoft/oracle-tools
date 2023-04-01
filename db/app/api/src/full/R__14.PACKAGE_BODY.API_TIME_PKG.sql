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

function delta
( p_start in time_t
, p_end in time_t
)
return seconds_t
is
begin
  PRAGMA INLINE (elapsed_time, 'YES'); -- speed it up!
  return elapsed_time(p_start, p_end);
end delta;

function elapsed_time
( p_start in timestamp_t
, p_end in timestamp_t
)
return seconds_t
is
  -- do not use SYS_EXTRACT_UTC() since it returns a TIMESTAMP datatype, not TIMESTAMP WITH TIME ZONE 
  l_interval constant timestamp_diff_t := p_end - p_start;
begin
  return extract(day from l_interval) * 24 * 60 * 60 +
         extract(hour from l_interval) * 60 * 60 +
         extract(minute from l_interval) * 60 +
         extract(second from l_interval);
end elapsed_time;

function delta
( p_start in timestamp_t
, p_end in timestamp_t
)
return seconds_t
is
begin
  PRAGMA INLINE (elapsed_time, 'YES'); -- speed it up!
  return elapsed_time(p_start, p_end);
end delta;

function timestamp2str
( p_val in timestamp_t
)
return timestamp_str_t
is
begin
  return to_char(p_val, c_timestamp_format);
end timestamp2str;

function str2timestamp
( p_val in timestamp_str_t
)
return timestamp_t
is
begin
  return to_timestamp_tz(p_val, c_timestamp_format);
end str2timestamp;

function get_timestamp_str
return timestamp_str_t
is
begin
  PRAGMA INLINE (get_timestamp, 'YES'); -- speed it up!
  PRAGMA INLINE (timestamp2str, 'YES'); -- speed it up!
  return timestamp2str(p_val => get_timestamp);
end get_timestamp_str;

$if oracle_tools.cfg_pkg.c_testing $then

procedure ut_get_timestamp
is
  l_ts1 timestamp_t;
  l_ts2 timestamp_t;
begin
  l_ts1 := current_timestamp();
  l_ts2 := systimestamp();
  ut.expect(delta(l_ts1, l_ts2), '#1').to_be_less_than(1);

  l_ts2 := l_ts1 at time zone 'UTC';
  ut.expect(delta(l_ts1, l_ts2), '#2').to_equal(0);
  
  l_ts1 := get_timestamp;
  ut.expect(delta(l_ts1, l_ts2), '#3').to_be_less_than(1);

  l_ts2 := l_ts1 at time zone 'UTC';
  ut.expect(delta(l_ts1, l_ts2), '#4').to_equal(0);
end ut_get_timestamp;
 
procedure ut_delta
is
  l_ts1 constant timestamp_t := timestamp '2023-03-16 14:37:53.929218 +01:00';
  l_ts2 constant timestamp_t := timestamp '2023-03-16 14:37:54.012484 +00:00';
begin
  ut.expect(delta(l_ts1, l_ts2), 'delta').to_equal(3600.083266);
end ut_delta;

procedure ut_timestamp2str
is
  l_ts timestamp_t := timestamp '1997-01-31 09:26:56.66 +02:00';
  l_ts_str timestamp_str_t := timestamp2str(l_ts);
begin
  ut.expect(l_ts_str, 'timestamp as string').to_equal('1997-01-31T09:26:56.660000Z+02:00');

  l_ts := get_timestamp;
  ut.expect(timestamp2str(l_ts), q'[now = now at time zone 'UTC']').to_equal(timestamp2str(l_ts at time zone 'UTC'));
  
  ut.expect(l_ts_str, 'string => timestamp => string').to_equal(timestamp2str(str2timestamp(l_ts_str)));
end ut_timestamp2str;

procedure ut_str2timestamp
is
  l_ts timestamp_t := str2timestamp('2023-03-16T14:37:53.929218Z+01:00');
begin
  ut.expect(extract(YEAR from l_ts), 'YEAR').to_equal(2023);
  ut.expect(extract(MONTH from l_ts), 'MONTH').to_equal(03);
  ut.expect(extract(DAY from l_ts), 'DAY').to_equal(16);
  ut.expect(extract(HOUR from l_ts), 'HOUR').to_equal(14 - 1); -- due to timezone hour of +01
  ut.expect(extract(MINUTE from l_ts), 'MINUTE').to_equal(37);
  ut.expect(extract(SECOND from l_ts), 'SECOND').to_equal(53.929218);
  ut.expect(extract(TIMEZONE_HOUR from l_ts), 'TIMEZONE_HOUR').to_equal(+01);
  ut.expect(extract(TIMEZONE_MINUTE from l_ts), 'TIMEZONE_MINUTE').to_equal(00);

  ut.expect
  ( str2timestamp('2023-03-16T16:59:40.423483Z+01:00')
  , 'same timestamp but different time zones'
  ).to_equal
  ( str2timestamp('2023-03-16T15:59:40.423483Z+00:00')
  );
end ut_str2timestamp;

$end

end API_TIME_PKG;
/

