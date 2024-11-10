create function matches_schema_object_fnc(p_schema_object_filter_id in number, p_schema_object_id in varchar2)
return integer
deterministic
is
begin
  for r in ( select t.obj from schema_object_filters t where t.id = p_schema_object_filter_id )
  loop
    return r.obj.matches_schema_object(p_schema_object_id);
  end loop;
  raise no_data_found;
end matches_schema_object_fnc;
/

create table schema_object_filter_results
( schema_object_filter_id integer not null
, schema_object_id varchar2(500 byte) not null
, created timestamp(6) 
  default sys_extract_utc(systimestamp)
  not null
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

-- Will we generate DDL for this one?
create index schema_object_filter_results$idx$1
on schema_object_filter_results(schema_object_filter_id, oracle_tools.matches_schema_object_fnc(schema_object_filter_id, schema_object_id)); 

-- Foreign key index schema_object_filter_results$fk$1 not necessary
-- since schema_object_filter_id is first part of primary key index.

-- foreign key index schema_object_filter_results$fk$2
create index schema_object_filter_results$fk$2
on schema_object_filter_results(schema_object_id);
