set define on verify off feedback off

-- define 1 must be userid hence is defined

column p2 new_value 2 noprint
column p3 new_value 3 noprint
column p4 new_value 4 noprint
column p5 new_value 5 noprint

select  '' as p2
,       '' as p3
,       '' as p4
,       '' as p5
from    dual
where   0 = 1;

column p2 clear
column p3 clear
column p4 clear
column p5 clear

