create or replace view EXT_LOAD_FILE_OBJECT_V as 
select  t.view_name
,       t.file_name
,       t.mime_type
,       t.object_name
,       t.sheet_names
,       t.last_excel_column_name
,       t.header_row_from
,       t.header_row_till
,       t.data_row_from
,       t.data_row_till
,       t.determine_datatype
from    table(ext_load_file_pkg.display_object_info) t
with read only;
