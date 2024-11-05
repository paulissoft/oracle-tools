create table all_schema_ddls
( schema_object_filter_id number 
, seq integer constraint all_schema_ddls$ck$seq check (seq >= 1) -- Sequence within parent
, created timestamp(6) default sys_extract_utc(systimestamp) constraint all_schema_ddls$ck$created check (created is not null)
, ddl oracle_tools.t_schema_ddl constraint all_schema_ddls$ck$ddl check (ddl is not null)
, constraint all_schema_ddls$pk primary key (schema_object_filter_id, seq)
, constraint all_schema_ddls$fk$1 foreign key (schema_object_filter_id) references schema_object_filters(id) on delete cascade
)
nested table ddl.ddl_tab store as ddl_ddl_tab
( nested table text store as text_tab )
;

create unique index all_schema_ddls$idx$1 on all_schema_ddls(schema_object_filter_id, ddl.obj.id()); -- Object id
