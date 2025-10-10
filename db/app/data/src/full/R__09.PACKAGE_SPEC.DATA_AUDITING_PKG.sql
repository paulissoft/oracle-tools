CREATE OR REPLACE PACKAGE DATA_AUDITING_PKG AUTHID CURRENT_USER IS

PROCEDURE add_auditing_columns
( p_table_name in user_tab_columns.table_name%type -- Table name, may be surrounded by double quotes
, p_column_aud$ins$who in user_tab_columns.column_name%type -- When not null this column will be renamed to AUD$INS$WHO
, p_column_aud$ins$when in user_tab_columns.column_name%type -- When not null this column will be renamed to AUD$INS$WHEN
, p_column_aud$ins$where in user_tab_columns.column_name%type -- When not null this column will be renamed to AUD$INS$WHERE
, p_column_aud$upd$who in user_tab_columns.column_name%type -- When not null this column will be renamed to AUD$UPD$WHO
, p_column_aud$upd$when in user_tab_columns.column_name%type -- When not null this column will be renamed to AUD$UPD$WHEN
, p_column_aud$upd$where in user_tab_columns.column_name%type -- When not null this column will be renamed to AUD$UPD$WHERE
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
- WHERE: VARCHAR2(128 CHAR)

When an auditing column already exists, nothing will happen.

The insert auditing columns will become an appropiate default so no auditing insert trigger is necessary.

The update auditing columns will be set in a dedicated auditing update trigger (created by ADD_AUDITING_TRIGGER).

The package CFG_INSTALL_DDL_PKG will be used for all DDL.

**/
procedure add_auditing_trigger
( p_table_name in user_tab_columns.table_name%type
);
/**

Will create (but not replace) an auditing update trigger.

Executes these DDL statements:

```
CREATE TRIGGER AUD$<p_table_name>
BEFORE UPDATE ON <p_table_name>
FOR EACH ROW
WHEN (NEW.AUD$UPD$WHO IS NULL OR NEW.AUD$UPD$WHEN IS NULL OR NEW.AUD$UPD$WHERE IS NULL)
DISABLED
BEGIN
  ORACLE_TOOLS.DATA_AUDITING_PKG.UPD
  ( P_AUD$UPD$WHO => :NEW.AUD$UPD$WHO
  , P_AUD$UPD$WHEN => :NEW.AUD$UPD$WHEN
  , P_AUD$UPD$WHERE => :NEW.AUD$UPD$WHERE
  );
END;
```

and:

```
ALTER TRIGGER AUD$<p_table_name> ENABLE
```

The second statement only when the trigger is valid and disabled.

**/

procedure upd
( p_aud$upd$who in out nocopy varchar2
, p_aud$upd$when in out nocopy timestamp with time zone -- standard
, p_aud$upd$where in out nocopy varchar2
, p_size in naturaln default utl_call_stack.dynamic_depth -- This will skip the call to API_CALL_STACK_PKG.GET_CALL_STACK() itself
);
/**
Invoked by the trigger created by ADD_AUDITING_TRIGGER.

Will set the auditing values but only when null.

Functions used:
- P_AUD$UPD$WHO  : ORACLE_TOOLS.DATA_SESSION_USERNAME
- P_AUD$UPD$WHEN : ORACLE_TOOLS.DATA_TIMESTAMP
- P_AUD$UPD$WHERE: ORACLE_TOOLS.DATA_CALLER
**/

procedure upd
( p_aud$upd$who in out nocopy varchar2
, p_aud$upd$when in out nocopy timestamp -- datatype of an old existing colum
, p_aud$upd$where in out nocopy varchar2
, p_size in naturaln default utl_call_stack.dynamic_depth -- This will skip the call to API_CALL_STACK_PKG.GET_CALL_STACK() itself
);
/** See above but systimestamp will be used for P_AUD$UPD$WHEN **/

procedure upd
( p_aud$upd$who in out nocopy varchar2
, p_aud$upd$when in out nocopy date -- datatype of an old existing colum
, p_aud$upd$where in out nocopy varchar2
, p_size in naturaln default utl_call_stack.dynamic_depth -- This will skip the call to API_CALL_STACK_PKG.GET_CALL_STACK() itself
);
/** See above but sysdate will be used for P_AUD$UPD$WHEN **/

END;
/
