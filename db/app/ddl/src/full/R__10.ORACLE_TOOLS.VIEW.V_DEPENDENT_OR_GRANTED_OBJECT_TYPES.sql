CREATE OR REPLACE FORCE VIEW "ORACLE_TOOLS"."V_DEPENDENT_OR_GRANTED_OBJECT_TYPES" ("NR", "OBJECT_TYPE") AS 
  select 2 as nr, 'OBJECT_GRANT' as object_type from dual
union all
select 3, 'SYNONYM' from dual
union all
select 4, 'COMMENT' from dual
union all
select 5, 'CONSTRAINT' from dual
union all
select 6, 'TRIGGER' from dual
union all
select 7, 'INDEX' from dual;

