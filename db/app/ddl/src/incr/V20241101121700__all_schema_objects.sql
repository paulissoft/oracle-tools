create function matches_schema_object_fnc(p_schema_object_filter_id in number, p_obj in oracle_tools.t_schema_object)
return integer
deterministic
is
begin
  raise_application_error(-20000, 'Must invoke all_schema_objects_api.matches_schema_object');
end matches_schema_object_fnc;
/

create table all_schema_objects
( schema_object_filter_id number 
, seq integer constraint all_schema_objects$ck$seq check (seq >= 1) -- Sequence within parent
, created timestamp(6) default sys_extract_utc(systimestamp) constraint all_schema_objects$ck$created check (created is not null)
, obj oracle_tools.t_schema_object constraint all_schema_objects$ck$obj check (obj is not null)
, constraint all_schema_objects$pk primary key (schema_object_filter_id, seq)
, constraint all_schema_objects$fk$1 foreign key (schema_object_filter_id) references schema_object_filters(id)
);

create unique index all_schema_objects$idx$1 on all_schema_objects(obj.id()); -- Object id
create        index all_schema_objects$idx$2 on all_schema_objects(matches_schema_object_fnc(schema_object_filter_id, obj)); -- Will we generate DDL for this one?
