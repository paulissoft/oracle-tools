begin
  execute immediate q'<
create table schema_objects
( id varchar2(500 byte)
  constraint schema_objects$nnc$id not null
, obj oracle_tools.t_schema_object 
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  constraint schema_objects$nnc$created not null
, updated timestamp(6)
, constraint schema_objects$pk primary key (id)
, constraint schema_objects$ck$obj check (obj is not null and obj.id = id)
, constraint schema_objects$ck$obj$last_ddl_time$ check (obj.last_ddl_time$ is not null) deferrable initially deferred
)
>';

  execute immediate q'<
alter table schema_objects nologging
>';

  execute immediate q'<
create index schema_objects$idx$1
on schema_objects (obj.object_schema(), obj.object_name(), obj.object_type())
>';

  execute immediate q'<
create index schema_objects$idx$2
on schema_objects (obj.base_object_schema(), obj.base_object_name(), obj.base_object_type())
>';

  execute immediate q'<
comment on table schema_objects is
    'The schema objects including named object and dependent or granted objects.'
>';
end;
/
