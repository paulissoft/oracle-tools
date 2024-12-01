create or replace force view v_dependent_or_granted_object_types as
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
