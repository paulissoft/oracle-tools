CREATE OR REPLACE PACKAGE DATA_AUDITING_PKG AUTHID CURRENT_USER IS

PROCEDURE add_columns
( p_table_name in user_tab_columns.table_name%type -- Table name, may be surrounded by double quotes
, p_column_aud$ins$who in user_tab_columns.column_name%type default null -- When not null this column will be renamed to AUD$INS$WHO
, p_column_aud$ins$when in user_tab_columns.column_name%type default null -- When not null this column will be renamed to AUD$INS$WHEN
, p_column_aud$ins$where in user_tab_columns.column_name%type default null -- When not null this column will be renamed to AUD$INS$WHERE
, p_column_aud$upd$who in user_tab_columns.column_name%type default null -- When not null this column will be renamed to AUD$UPD$WHO
, p_column_aud$upd$when in user_tab_columns.column_name%type default null -- When not null this column will be renamed to AUD$UPD$WHEN
, p_column_aud$upd$where in user_tab_columns.column_name%type default null -- When not null this column will be renamed to AUD$UPD$WHERE
);
/**

Will add these auditing columns to the table:
- AUD$INS$WHO
- AUD$INS$WHEN
- AUD$INS$WHERE
- AUD$UPD$WHO
- AUD$UPD$WHEN
- AUD$UPD$WHERE

When a p_column parameter is not empty,
the value of that parameter should be an existing column (may be surrounded by double quotes)
that will be renamed to the corresponding auditing column.

The datatype:
- WHO: VARCHAR2(128 CHAR)
- WHEN: TIMESTAMP WITH TIME ZONE (or the datatype of the old existing column)
- WHERE: VARCHAR2(1000 CHAR)

Functions used:
- WHO: ORACLE_TOOLS.DATA_SESSION_USERNAME
- WHEN: ORACLE_TOOLS.DATA_TIMESTAMP
- WHERE: ORACLE_TOOLS.DATA_CALL_INFO

When an auditing column already exists, nothing will happen.

The auditing columns will be set in a dedicated auditing trigger (created by ADD_TRIGGER).

The package CFG_INSTALL_DDL_PKG will be used for all DDL.

**/
procedure add_trigger
( p_table_name in user_tab_columns.table_name%type
);
/**

Will create (but not replace) an auditing trigger.

Executes these DDL statements:

```
CREATE TRIGGER AUD$<p_table_name>
BEFORE INSERT OR UPDATE ON <p_table_name>
FOR EACH ROW
BEGIN
  IF INSERTING
  THEN
    ORACLE_TOOLS.DATA_AUDITING_PKG.UPD
    ( P_WHO => :NEW.AUD$INS$WHO
    , P_WHEN => :NEW.AUD$INS$WHEN
    , P_WHERE => :NEW.AUD$INS$WHERE
    );
  ELSE
    ORACLE_TOOLS.DATA_AUDITING_PKG.UPD
    ( P_WHO => :NEW.AUD$UPD$WHO
    , P_WHEN => :NEW.AUD$UPD$WHEN
    , P_WHERE => :NEW.AUD$UPD$WHERE
    );
  END IF;
END;
```

and:

```
ALTER TRIGGER AUD$<p_table_name> ENABLE
```

The second statement only when the trigger is valid and disabled.

**/

procedure set_columns
( p_who in out nocopy varchar2
, p_when in out nocopy timestamp with time zone -- standard
, p_where in out nocopy varchar2
, p_do_no_set_who in boolean default null
, p_do_no_set_when in boolean default null
, p_do_no_set_where in boolean default null
);
/**
Invoked by the trigger created by ADD_TRIGGER.

Will set the auditing values but only when null.

Functions used:
- P_WHO  : ORACLE_TOOLS.DATA_SESSION_USERNAME
- P_WHEN : ORACLE_TOOLS.DATA_TIMESTAMP
- P_WHERE: ORACLE_TOOLS.DATA_CALL_INFO
**/

procedure set_columns
( p_who in out nocopy varchar2
, p_when in out nocopy timestamp -- datatype of an old existing colum
, p_where in out nocopy varchar2
, p_do_no_set_who in boolean default null
, p_do_no_set_when in boolean default null
, p_do_no_set_where in boolean default null
);
/** See above but systimestamp will be used for P_WHEN **/

procedure set_columns
( p_who in out nocopy varchar2
, p_when in out nocopy date -- datatype of an old existing colum
, p_where in out nocopy varchar2
, p_do_no_set_who in boolean default null
, p_do_no_set_when in boolean default null
, p_do_no_set_where in boolean default null
);
/** See above but sysdate will be used for P_WHEN **/

function get_call_info
return varchar2;

END;
/
