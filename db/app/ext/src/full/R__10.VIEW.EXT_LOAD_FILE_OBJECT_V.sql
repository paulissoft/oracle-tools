CREATE OR REPLACE FORCE VIEW "EXT_LOAD_FILE_OBJECT_V" ("VIEW_NAME", "FILE_NAME", "MIME_TYPE", "OBJECT_NAME", "SHEET_NAMES", "LAST_EXCEL_COLUMN_NAME", "HEADER_ROW_FROM", "HEADER_ROW_TILL", "DATA_ROW_FROM", "DATA_ROW_TILL", "DETERMINE_DATATYPE")  AS 
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

