create table schema_object_filter_results
( schema_object_filter_id integer
  constraint schema_object_filter_results$nnc$schema_object_filter_id not null
, schema_object_id varchar2(500 byte)
  constraint schema_object_filter_results$nnc$schema_object_id not null
, generate_ddl number(1, 0) -- must be schema_objects.obj.matches_schema_object(schema_object_id)
  constraint schema_object_filter_results$nnc$generate_ddl not null
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  constraint schema_object_filter_results$nnc$created not null
, constraint schema_object_filter_results$pk
  primary key (schema_object_filter_id, schema_object_id)
, constraint schema_object_filter_results$fk$1
  foreign key (schema_object_filter_id)
  references schema_object_filters(id) on delete cascade
, constraint schema_object_filter_results$fk$2
  foreign key (schema_object_id)
  references schema_objects(id) on delete cascade
)
organization index
tablespace users
;

alter table schema_object_filter_results nologging;

-- Foreign key index schema_object_filter_results$fk$1 not necessary
-- since schema_object_filter_id is first part of primary key index.

-- foreign key index schema_object_filter_results$fk$2
create index schema_object_filter_results$fk$2
on schema_object_filter_results(schema_object_id);

alter table schema_object_filter_results
  add constraint schema_object_filter_results$ck$generate_ddl check (generate_ddl in (0, 1));

comment on table schema_object_filter_results is
    'The schema object filter results, needed because the function matches_schema_object is too expensive.';
