begin
  execute immediate q'<
create table schema_object_filter_results
( schema_object_filter_id integer
  constraint schema_object_filter_results$nnc$schema_object_filter_id not null
, schema_object_id varchar2(500 byte)
  constraint schema_object_filter_results$nnc$schema_object_id not null
, created timestamp(6)
  default sys_extract_utc(systimestamp)
  constraint schema_object_filter_results$nnc$created not null
, generate_ddl_details varchar2(1002 byte) invisible -- must be schema_objects.obj.matches_schema_object_details(schema_object_id)
  constraint schema_object_filter_results$nnc$generate_ddl_details not null
  constraint schema_object_filter_results$ck$generate_ddl_details check (substr(generate_ddl_details, 1, 2) in (' |', '0|', '1|'))
, generate_ddl number(1, 0) generated always as (to_number(ltrim(substr(generate_ddl_details, 1, 1)))) -- null, 0 or 1
, generate_ddl_info varchar2(1000 byte) generated always as (substrb(generate_ddl_details, 3, 1000))
, constraint schema_object_filter_results$pk
  primary key (schema_object_filter_id, schema_object_id)
, constraint schema_object_filter_results$fk$1
  foreign key (schema_object_id)
  references schema_objects(id) on delete cascade
, constraint schema_object_filter_results$fk$2
  foreign key (schema_object_filter_id)
  references schema_object_filters(id) on delete cascade
)
>';

  execute immediate q'<
alter table schema_object_filter_results nologging
>';

-- foreign key index schema_object_filter_results$fk$1
  execute immediate q'<
create index schema_object_filter_results$idx$1
on schema_object_filter_results(schema_object_id)
>';

-- Foreign key index schema_object_filter_results$fk$2 not necessary
-- since schema_object_filter_id is first part of primary key index.

  execute immediate q'<
comment on table schema_object_filter_results is
    'The schema object filter results, needed because the function matches_schema_object_details is too expensive.'
>';
end;
/
