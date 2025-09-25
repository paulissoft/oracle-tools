CREATE OR REPLACE PACKAGE "UTIL_DICT_PKG" AUTHID CURRENT_USER is

type fkey_search_rec_t is record
( master_table_name user_tables.table_name%type
, master_index_name user_indexes.index_name%type
, detail_table_name user_tables.table_name%type
, detail_index_name user_indexes.index_name%type
, detail_constraint_name user_constraints.constraint_name%type
, column_name user_ind_columns.column_name%type
, remark varchar2(1000 char)
);

type fkey_search_tab_t is table of fkey_search_rec_t;

function fkey_search
( p_table_name in varchar2 default '%'
)
return fkey_search_tab_t
pipelined;

end util_dict_pkg;
/

