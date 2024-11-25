create table schema_objects
( id varchar2(500 byte) not null constraint schema_objects$pk primary key
, obj t_schema_object 
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  not null
, constraint schema_objects$ck$obj check (obj is not null and obj.id = id)
);

alter table schema_objects nologging;

create index schema_objects$idx$1
on schema_objects (obj.object_schema(), obj.object_name(), obj.object_type());

create index schema_objects$idx$2
on schema_objects (obj.base_object_schema(), obj.base_object_name(), obj.base_object_type());
