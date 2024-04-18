CREATE OR REPLACE PACKAGE "EXT_LOAD_FILE_PKG" authid definer as

apex_installed constant boolean := true;

-- to speed it up
create_collection_from_query constant boolean := false;

subtype t_boolean is integer; -- must be a SQL type, not a PL/SQL type
subtype t_excel_column_name is varchar2(3 char);
subtype t_mime_type is varchar2(255 char);
subtype t_nls_charset_name is varchar2(100);

min_excel_column_name constant t_excel_column_name := 'A';
min_excel_column_number constant positiven := 1;

max_excel_column_name constant t_excel_column_name := 'XFD'; -- in Excel 2019
max_excel_column_number constant positiven := 16384; -- 24 (X) * 26 * 26 + 6 (F) * 26 + 4 (D)

csv_nls_charset_name constant t_nls_charset_name := 'WE8MSWIN1252';

subtype t_determine_datatype is integer; -- must be a SQL type, not a PL/SQL type

-- All strings of maximum length hence VARCHAR2(4000 CHAR)
"DATATYPE STRING LENGTH MAX" constant t_determine_datatype := 0;
-- Use the document information to determine the exact datatype and for a string the minimum length to store all data.
-- Possible datatypes:
-- 1) NUMBER
-- 2) DATE
-- 3) TIMESTAMP
-- 4) VARCHAR2(n CHAR) where n is the maximum length in the data document hence the minimum to store all document data
"DATATYPE EXACT LENGTH MIN" constant t_determine_datatype  := 1;
-- Use the document information to determine the exact datatype and for a string the maximum length (hence VARCHAR2(4000 CHAR))
"DATATYPE EXACT LENGTH MAX" constant t_determine_datatype  := 2;



/* An structure that describes how to load DML */
type t_object_info_rec is record
( view_name user_views.view_name%type -- this view contains excel name - database column name mapping plus key info
, file_name varchar2(1000 char) -- Excel/CSV file name
, mime_type t_mime_type -- text/csv for CSV files
, object_name all_objects.object_name%type -- name of the object to load into (may be fully qualified like TOOLS."test")
, sheet_names varchar2(4000 char) -- for spreadsheet files
, last_excel_column_name t_excel_column_name default 'ZZ'
  -- header start at this row (0 means NO header)
, header_row_from integer default 1 -- natural is not supported due to the pipelined function built on this record
  -- header ends at this row (inclusive)
, header_row_till integer default 1
  -- the data starts at this row (should be after after header_row_till)
, data_row_from integer default 2
, data_row_till integer default null -- all
  -- do we need to determine the datatype?
, determine_datatype t_determine_datatype default "DATATYPE EXACT LENGTH MAX" -- use varchar2(4000 char) for strings
, nls_charset_name t_nls_charset_name default csv_nls_charset_name
);

type t_object_info_tab is table of t_object_info_rec;

subtype t_apex_file_id is integer; -- apex_application_temp_files.id%type
subtype t_apex_seq_id is integer; -- apex_collections.seq_id%type

/* An object that describes how to load a column */
type t_column_info_rec is record
( apex_file_id t_apex_file_id -- key part 1 for apex_collection
, seq_id t_apex_seq_id -- key part 2 for apex_collection
, view_name user_views.view_name%type -- this view contains excel name - database column name mapping plus key info
, excel_column_name t_excel_column_name
, header_row varchar2(4000 char)
, data_row varchar2(4000 char)
, data_type varchar2(100 char)
, format_mask varchar2(100 char)
, in_key t_boolean
, default_value varchar2(4000 char)
);

type t_column_info_tab is table of t_column_info_rec;

type t_object_columns_tab is table of all_tab_columns.column_name%type;

/**
 * Return the columns of a table/view (or synonym pointing to a table/view).
 *
 * @param p_object_name  The object name (may be fully qualified if p_owner is empty)
 * @param p_owner        The owner (may be empty)
 *
 * @return The schema owner of that package
 */
function get_object_columns
( p_object_name in varchar2
, p_owner in varchar2 default null
)
return t_object_columns_tab
pipelined;

/**
 * Return the owner of the load data package.
 *
 * May be useful when creating a table and granting privileges to this owner
 * so the load can succeed.
 *
 * The load data package is currently EXCELTABLE.
 *
 * @return The schema owner of that package
 */
function get_load_data_owner
return all_users.username%type;

/**
 * Return an natural integer for an Excel column name.
 *
 * It will return:
 * -  0 for  null
 * -  1 for  'A'
 * -  2 for  'B'
 * - 26 for  'Z'
 * - 27 for 'AA'
 *
 * @param p_excel_column_name  An Excel column name
 *
 * @return A natural integer
 */
function excel_column_name2number
( p_excel_column_name in varchar2
)
return naturaln
deterministic;

/**
 * Return an Excel column name for a number.
 *
 * @param p_number  A natural integer
 *
 * @return An Excel column name
 */
function number2excel_column_name
( p_number in naturaln
)
return varchar2
deterministic;

/**
 * Set load file info.
 *
 * Creates a view named LOAD_FILE_<timestamp>_V with as column names
 * the Excel columns and a primary key (disabled) for those
 * Excel columns that have in_key set to 1.
 *
 * @param p_object_info_rec         The object info
 * @param p_column_info_tab         A table of column info
 * @param p_view_name               The view containing the object info
 */
procedure set_load_file_info
( p_object_info_rec in t_object_info_rec
, p_column_info_tab in t_column_info_tab
, p_view_name out nocopy varchar2
);

/**
 * Get object info.
 *
 * @param p_view_name               The view containing the object info
 * @param p_object_info_rec         The object info
 */
procedure get_object_info
( p_view_name in varchar2
, p_object_info_rec out nocopy t_object_info_rec 
);

/**
 * Get column info.
 *
 * @param p_view_name               The view containing the object info
 * @param p_column_info_tab         A table of column info
 */
procedure get_column_info
( p_view_name in varchar2
, p_column_info_tab out nocopy t_column_info_tab
);

/**
 * Display object info used to load into objects.
 *
 * @return A list of object info
 */
function display_object_info
return t_object_info_tab
pipelined;

/**
 * Display column info used to load into objects.
 *
 * @return A list of column info
 */
function display_column_info
return t_column_info_tab
pipelined;

/**
 * Convert blob to clob.
 *
 * @param p_blob              The blob
 * @param p_nls_charset_name  The NLS character set used to convert the flat file BLOB into a CLOB.
 *
 * @return A CLOB
 */
function blob2clob
( p_blob in blob
, p_nls_charset_name in t_nls_charset_name default csv_nls_charset_name
)
return clob;

/**
 * Display the contents of the collection to initialise.
 *
 * This function is used in init().
 *
 * @param p_apex_file_id            An apex_application_temp_files id
 * @param p_sheet_names             The colon separated Excel sheet names list (for non CSV files)
 * @param p_last_excel_column_name  The last Excel column name (for non CSV files)
 * @param p_header_row_from         The header starts at this row (0: no header)
 * @param p_header_row_till         The header ends at this row (0: no header)
 * @param p_data_row_from           The first data row starts at this row
 * @param p_data_row_till           The last data row ends at this row (null means all)
 * @param p_determine_datatype      Determine the datatype
 * @param p_format_mask             The format mask for a DATE or TIMESTAMP
 * @param p_view_name               The object info for the DML
 * @param p_nls_charset_name        The NLS character set used to convert the flat file BLOB into a CLOB.
 *
 * @return A collection
 */
function display
( p_apex_file_id in t_apex_file_id
, p_sheet_names in varchar2
, p_last_excel_column_name in varchar2
, p_header_row_from in natural
, p_header_row_till in natural
, p_data_row_from in natural
, p_data_row_till in natural
, p_determine_datatype in t_determine_datatype
, p_format_mask in varchar2
, p_view_name in varchar2
, p_nls_charset_name in t_nls_charset_name default csv_nls_charset_name
)
return t_column_info_tab
pipelined;

/**
 * Determine CSV info about field separator and end of line string.
 *
 * See also https://www.codeproject.com/Articles/231582/Auto-detect-CSV-separator.
 *
 * Rules for writing CSV files are pretty simple:
 *
 * a) If value contains separator character or new line character or begins
 * with a quote - enclose the value in quotes.
 * b) If value is enclosed in quotes - any quote character contained in the
 * value should be followed by an additional quote character.
 *
 * This algorithm just keeps the count of all possible field separator
 * candidates and to speed it up one additional heuristic is used: for each
 * row the field separator candidates that are seen in the current row are
 * stored. This allows us to speed up and normally just reading the header
 * line(s) is enough.
 *
 * The end of line string is the first sequence of line feeds and/or carriage
 * returns not inside a quoted field.
 *
 * The algorithm stops when:
 * 1) the CSV (at most 32767 characters) has been read
 * 2) there is a new row and at most one candidate has been processed
 *
 * Now:
 * I) when no candidate has been seen: the field separator will be empty (CSV with one column?)
 * II) when one candidate has been seen: that is the field separator
 * III) when more candidate have been seen: take the one with the maximal count overall
 *
 * @param p_csv
 * @param p_field_separators  A string of possible field separator characters (each 1 long)
 * @param p_eol               The end of line string
 * @param p_field_separator   The field separator
 */
procedure determine_csv_info
( p_csv in clob
, p_field_separators in varchar2 default ',;:|' || chr(9)
, p_quote_char in varchar2 default '"'
, p_eol out nocopy varchar2
, p_field_separator out nocopy varchar2
);

-- helper function invoked by function display( p_apex_file_id ... )
procedure get_column_info_tab
( -- common parameters
  p_apex_file_id in t_apex_file_id
, p_last_excel_column_name in varchar2
, p_header_row_from in natural
, p_header_row_till in natural
, p_data_row_from in natural
, p_data_row_till in natural
, p_determine_datatype in t_determine_datatype
, p_format_mask in varchar2
, p_view_name in varchar2
  -- CSV parameters
, p_clob in clob default null
, p_eol in varchar2 default null
, p_field_separator in varchar2 default null
, p_quote_char in varchar2 default null
  -- Spreadsheet parameters
, p_blob in blob default null
, p_sheet_names in varchar2 default null
, p_column_info_tab out nocopy t_column_info_tab
);

/**
 * Create a collection to describe a file and display the header and first data row.
 *
 * Invoked by an Apex application.
 *
 * @param p_apex_file_id            An apex_application_temp_files id
 * @param p_sheet_names             The colon separated Excel sheet names list
 * @param p_last_excel_column_name  The last Excel column name (for non CSV files)
 * @param p_header_row_from         The header starts at this row (0: no header)
 * @param p_header_row_till         The header ends at this row (0: no header)
 * @param p_data_row_from           The first data row starts at this row
 * @param p_data_row_till           The first data row ends at this row (null means all)
 * @param p_determine_datatype      Determine the datatype
 * @param p_format_mask             The format mask for a DATE or TIMESTAMP
 * @param p_view_name               The object info for the DML
 * @param p_nls_charset_name        The NLS character set used to convert the flat file BLOB into a CLOB.
 */
procedure init
( p_apex_file_id in t_apex_file_id
, p_sheet_names in varchar2
, p_last_excel_column_name in varchar2
, p_header_row_from in natural
, p_header_row_till in natural
, p_data_row_from in natural
, p_data_row_till in natural
, p_determine_datatype in t_determine_datatype
, p_format_mask in varchar2 default null -- v('APP_NLS_TIMESTAMP_FORMAT')
, p_view_name in varchar2 default null
, p_nls_charset_name in t_nls_charset_name default csv_nls_charset_name
);

/**
 * Display the collection initialized by procedure init (and updated by dml).
 *
 * @param p_apex_file_id            An apex_application_temp_files id
 *
 * @return A collection
 */
function display
( p_apex_file_id in t_apex_file_id
)
return t_column_info_tab
pipelined;

/**
 * Generate a create table statement so the table can be used by function load.
 *
 * @param p_apex_file_id            An apex_application_temp_files id
 * @param p_table_name              The table name
 *
 * @return Create table statement with primary key if there are key columns.
 */
function create_table_statement
( p_apex_file_id in t_apex_file_id
, p_table_name in varchar2
)
return dbms_sql.varchar2a;

/**
 * Validate the load file columns.
 *
 * These checks are performed:
 * 1) is the excel column correct?
 * 2) is the header row correct?
 * 3) is the data type correct?
 * 4) is the format mask correct (only for date / timestamp)?
 * 5) is the in key value correct?
 * 6) is the default value correct?
 *
 * @param p_apex_file_id            An Apex collection
 */
procedure validate
( p_excel_column_name in varchar2
, p_header_row in varchar2
, p_data_type in varchar2
, p_format_mask in varchar2
, p_in_key in varchar2 -- string yes and not a number in order to better check the value
, p_default_value in varchar2
);

/**
 * Validate the collection table column names.
 *
 * These checks are performed:
 * 1) are there duplicate table column names (header_row) in the collection? 
 * 2) is the (fully qualified) object column name set a superset of the collection column name set?
 * 3) for action Update, Merge or Delete there must be a key
 *
 * @param p_apex_file_id            An apex_application_temp_files id
 * @param p_object_info_rec         The object info
 * @param p_action                  (I)nsert
 *                                  (R)eplace for truncate + insert
 *                                  (U)pdate
 *                                  (M)erge
 *                                  (D)elete
 */
procedure validate
( p_apex_file_id in t_apex_file_id
, p_object_info_rec in t_object_info_rec
, p_action in varchar2
);

/**
 * Validate the collection table column names.
 *
 * See validate(p_apex_file_id, p_object_info_rec, p_action).
 *
 * @param p_apex_file_id            An apex_application_temp_files id
 * @param p_sheet_names             The colon separated Excel sheet names list
 * @param p_last_excel_column_name  The last Excel column name (for non CSV files)
 * @param p_header_row_from         The header starts at this row (0: no header)
 * @param p_header_row_till         The header ends at this row (0: no header)
 * @param p_data_row_from           The first data row starts at this row
 * @param p_data_row_till           The last data row ends at this row (null means all)
 * @param p_determine_datatype      Determine the datatype
 * @param p_object_name             The object name for the DML
 * @param p_action                  (I)nsert
 *                                  (R)eplace for truncate + insert
 *                                  (U)pdate
 *                                  (M)erge
 *                                  (D)elete
 * @param p_nls_charset_name        The NLS character set used to convert the flat file BLOB into a CLOB.
 */
procedure validate
( p_apex_file_id in t_apex_file_id
, p_sheet_names in varchar2
, p_last_excel_column_name in varchar2
, p_header_row_from in natural
, p_header_row_till in natural
, p_data_row_from in natural
, p_data_row_till in natural
, p_determine_datatype in t_determine_datatype
, p_object_name in varchar2
, p_action in varchar2
, p_nls_charset_name in t_nls_charset_name default csv_nls_charset_name
);

/**
 * Load an Excel.
 *
 * This function is used in load().
 *
 * @param p_object_name             The object name for the DML
 * @param p_column_info_tab         The columns to insert
 * @param p_action                  (I)nsert
 *                                  (R)eplace for truncate + insert
 *                                  (U)pdate
 *                                  (M)erge
 *                                  (D)elete
 * @param p_blob                    The Excel
 * @param p_sheet_names             The colon separated Excel sheet names list
 * @param p_header_row_from         The header starts at this row (0: no header)
 * @param p_header_row_till         The header ends at this row (0: no header)
 * @param p_data_row_from           The first data row starts at this row
 * @param p_data_row_till           The last data row ends at this row (null means all)
 *
 * @return The number of rows affected
 */
function load_excel
( p_object_name in varchar2
, p_column_info_tab in t_column_info_tab
, p_action in varchar2
, p_blob in blob
, p_sheet_names in varchar2
, p_header_row_from in natural
, p_header_row_till in natural
, p_data_row_from in natural
, p_data_row_till in natural
)
return integer;

/**
 * Load a CSV.
 *
 * This function is used in load().
 *
 * @param p_object_name             The object name for the DML
 * @param p_column_info_tab         The columns to insert
 * @param p_action                  (I)nsert
 *                                  (R)eplace for truncate + insert
 *                                  (U)pdate
 *                                  (M)erge
 *                                  (D)elete
 * @param p_clob                    The CSV
 * @param p_eol                     The end of line sequence (for CSV files)
 * @param p_field_separator         The field separator (for CSV files)
 * @param p_quote_char              To quote a field (for CSV files)
 * @param p_header_row_from         The header starts at this row (0: no header)
 * @param p_header_row_till         The header ends at this row (0: no header)
 * @param p_data_row_from           The first data row starts at this row
 * @param p_data_row_till           The last data row ends at this row (null means all)
 * @param p_nls_charset_name        The NLS character set used to convert the flat file BLOB into a CLOB.
 *
 * @return The number of rows affected
 */
function load_csv
( p_object_name in varchar2
, p_column_info_tab in t_column_info_tab
, p_action in varchar2
, p_clob in clob
, p_eol in varchar2
, p_field_separator in varchar2
, p_quote_char in varchar2
, p_header_row_from in natural
, p_header_row_till in natural
, p_data_row_from in natural
, p_data_row_till in natural
, p_nls_charset_name in t_nls_charset_name default csv_nls_charset_name
)
return integer;

/**
 * Load the collection initialized by procedure init (and updated by dml).
 *
 * @param p_apex_file_id            An apex_application_temp_files id
 * @param p_sheet_names             The colon separated Excel sheet names list
 * @param p_last_excel_column_name  The last Excel column name (for non CSV files)
 * @param p_header_row_from         The header starts at this row (0: no header)
 * @param p_header_row_till         The header ends at this row (0: no header)
 * @param p_data_row_from           The first data row starts at this row
 * @param p_data_row_till           The last data row ends at this row (null means all)
 * @param p_determine_datatype      Determine the datatype
 * @param p_object_name             The object name for the DML
 * @param p_action                  (I)nsert
 *                                  (R)eplace for truncate + insert
 *                                  (U)pdate
 *                                  (M)erge
 *                                  (D)elete
 * @param p_nls_charset_name        The NLS character set used to convert the flat file BLOB into a CLOB.
 *
 * @return The number of rows affected
 */
function load
( p_apex_file_id in t_apex_file_id
, p_sheet_names in varchar2
, p_last_excel_column_name in varchar2
, p_header_row_from in natural
, p_header_row_till in natural
, p_data_row_from in natural
, p_data_row_till in natural
, p_determine_datatype in t_determine_datatype
, p_object_name in varchar2
, p_action in varchar2
, p_nls_charset_name in t_nls_charset_name default csv_nls_charset_name
)
return integer;

/**
 * Load an Apex file.
 *
 * This function is used by the Finish button.
 *
 * @param p_apex_file               The name for the temporary Apex file
 * @param p_owner                   The application owner
 * @param p_object_info_rec         Record containing all the defaults
 * @param p_apex_file_name          The Apex file name
 * @param p_csv_file                Is it a CSV file (0 = false; 1 = true)?
 * @param p_action                  The action to perform
 * @param p_new_table               Is the object a new table (0 = false; 1 = true)?
 * @param p_nr_rows                 The number of rows affected
 */

subtype t_apex_file_name is varchar2(400 char); -- apex_application_temp_files.filename%type

procedure load
( p_apex_file in varchar2
, p_owner in varchar2
, p_object_info_rec in out nocopy t_object_info_rec
, p_apex_file_id out nocopy t_apex_file_id
, p_apex_file_name out nocopy t_apex_file_name
, p_csv_file out nocopy natural
, p_action out nocopy varchar2
, p_new_table out nocopy natural
, p_nr_rows out nocopy natural
);

/**
 * Cleanup the collection initialized by procedure init (and updated by dml).
 *
 * @param p_apex_file_id            An apex_application_temp_files id
 */
procedure done
( p_apex_file_id in t_apex_file_id
);

/**
 * Issue DML.
 *
 * May be used in Apex to manage the load file object info.
 *
 * @param p_action                  (I)nsert, (U)pdate or (D)elete
 * @param p_view_name               The object info for the DML and also the primary key
 * @param p_file_name               The file name
 * @param p_mime_type               The file MIME type
 * @param p_object_name             The object to load into
 * @param p_sheet_names             The colon separated Excel sheet names list
 * @param p_last_excel_column_name  The last Excel column name (for non CSV files)
 * @param p_header_row_from         The header starts at this row (0: no header)
 * @param p_header_row_till         The header ends at this row (0: no header)
 * @param p_data_row_from           The first data row starts at this row
 * @param p_data_row_till           The last data row ends at this row (null means all)
 * @param p_determine_datatype      Determine the datatype
 */
procedure dml
( p_action in varchar2
, p_view_name in user_views.view_name%type -- key
, p_file_name in varchar2 default null
, p_mime_type in t_mime_type default null
, p_object_name in all_objects.object_name%type default null
, p_sheet_names in varchar2 default null
, p_last_excel_column_name in t_excel_column_name default null
, p_header_row_from in natural default null
, p_header_row_till in natural default null
, p_data_row_from in natural default null
, p_data_row_till in natural default null
, p_determine_datatype in t_determine_datatype default null
);

/**
 * Issue DML for the load file column info (using an Apex collection).
 *
 * May be used in Apex to manage the load file column info.
 *
 * @param p_action             (I)nsert, (U)pdate or (D)elete
 * @param p_apex_file_id       Primary key part 1 (used to populate an Apex collection with the id as name)
 * @param p_seq_id             Primary key part 2 (write on insert, read on update or delete)
 * @param p_excel_column_name
 * @param p_header_row
 * @param p_data_row
 * @param p_data_type
 * @param p_format_mask
 * @param p_in_key
 * @param p_default_value
 */
procedure dml
( p_action in varchar2
, p_apex_file_id in t_apex_file_id -- key part 1
, p_seq_id in out t_apex_seq_id -- key part 2
, p_excel_column_name in varchar2
, p_header_row in varchar2
, p_data_row in varchar2
, p_data_type in varchar2
, p_format_mask in varchar2
, p_in_key in integer
, p_default_value in varchar2
);

/**
 * Return the sheet names of an Excel file.
 *
 * @param p_excel              The Excel BLOB
 *
 * @return A list of sheet names
 */
function get_sheets
( p_excel in blob
)
return sys.odcivarchar2list
pipelined;

/**
 * Parse an optionally fully qualified object name into an owner and object name.
 *
 * With owner."Object" as input, it returns OWNER and Object.
 *
 * @param p_fq_object_name     An object name optionally prepended with an owner
 * @param p_owner              The unquoted object owner name (as in ALL_OBJECTS)
 * @param p_object_name        The unquoted object name (as in ALL_OBJECTS)
 */
procedure parse_object_name
( p_fq_object_name in varchar2
, p_owner out nocopy varchar2
, p_object_name out nocopy varchar2
);

$if cfg_pkg.c_testing $then

--%suitepath(EXT)
--%suite
--%rollback(manual)

--%beforeall
procedure ut_setup;

--%afterall
procedure ut_teardown;

--%test
procedure ut_excel_column_name2number;

--%test
procedure ut_number2excel_column_name;

-- test set_load_file_info / get_object_info / get_column_info
--%test
procedure ut_load_file_info;

--%test
procedure ut_load_csv;

--%test
procedure ut_get_column_info_tab;

--%test
procedure ut_determine_csv_info;

$end

end ext_load_file_pkg;
/

