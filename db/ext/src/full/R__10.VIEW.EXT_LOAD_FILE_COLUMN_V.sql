create or replace view EXT_LOAD_FILE_COLUMN_V as
select  t.view_name
,       t.excel_column_name
,       t.header_row
,       t.data_type
,       t.format_mask
,       t.in_key
,       t.default_value
from    table(ext_load_file_pkg.display_column_info) t
with read only;
