CREATE OR REPLACE FORCE VIEW "MSG_QUEUE_INFO_V" ("QUEUE_NAME", "MSG_STATE", "TOTAL", "MIN_ELAPSED", "AVG_ELAPSED", "MAX_ELAPSED") AS 
  select  queue as queue_name
,       msg_state
,       count(*) as total
,       trunc(min(deq_time - enq_time) * 24 * 60 * 60, 2) as min_elapsed
,       trunc(avg(deq_time - enq_time) * 24 * 60 * 60, 2) as avg_elapsed
,       trunc(max(deq_time - enq_time) * 24 * 60 * 60, 2) as max_elapsed
from    aq$msg_qt
group by
        queue
,       msg_state
order by
        queue
,       msg_state;

