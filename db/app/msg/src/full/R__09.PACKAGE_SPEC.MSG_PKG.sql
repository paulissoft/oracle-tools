CREATE OR REPLACE PACKAGE "MSG_PKG" AUTHID DEFINER AS 

-- Do we want to print enqueued / dequeued messages? >= 1 is true
c_debugging constant naturaln := $if oracle_tools.cfg_pkg.c_debugging $then 1 $else 0 $end;

type boolean_lookup_tab_t is table of boolean index by varchar2(4000 char);

type msg_tab_t is table of msg_typ;

/**
A package with some generic definitions, exceptions, functions and procedures.
**/

procedure init;

procedure done;

function get_object_name
( p_object_name in varchar2 -- the object name part
, p_what in varchar2 -- the kind of object: used in error message
, p_schema_name in varchar2 default $$PLSQL_UNIT_OWNER -- the schema part name
, p_fq in integer default 1 -- return fully qualified name, yes (1) or no (0)
, p_qq in integer default 1 -- return double quoted name, yes (1) or no (0)
, p_uc in integer default 1 -- return name in upper case, yes (1) or no (0)
)
return varchar2;
/** A function to return the object name in some kind of format. **/

function get_msg_tab
return msg_tab_t;
/** Return a list of subtype instances having as final supertype MSG_TYP. MSG_TYP is not part of the list. **/

procedure process_msg
( p_msg in msg_typ
, p_commit in boolean
);
/** Dedicated procedure to process a message, especially interesting since it enables profiling. **/

procedure data2msg
( p_data_clob in clob
, p_msg_vc out nocopy varchar2
, p_msg_clob out nocopy clob
);
/** Copy the input CLOB to either p_msg_vc if small enough or otherwise to p_msg_clob. **/

procedure msg2data
( p_msg_vc in varchar2
, p_msg_clob in clob
, p_data_json out nocopy json_element_t
);
/** Copy either p_msg_vc if not null, otherwise p_msg_clob to the output CLOB. **/

procedure data2msg
( p_data_blob in blob
, p_msg_raw out nocopy raw
, p_msg_blob out nocopy blob
);
/** Copy the input BLOB to either p_msg_raw if small enough or otherwise to p_msg_blob. **/

procedure msg2data
( p_msg_raw in raw
, p_msg_blob in blob
, p_data_json out nocopy json_element_t
);
/** Copy either p_msg_raw if not null, otherwise p_msg_blob to the output BLOB. **/

end msg_pkg;
/

