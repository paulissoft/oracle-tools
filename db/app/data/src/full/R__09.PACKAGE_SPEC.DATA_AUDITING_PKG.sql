CREATE OR REPLACE PACKAGE DATA_AUDITING_PKG AUTHID CURRENT_USER IS

PROCEDURE add_auditing_colums
( p_table_name in user_tab_colums.table_name%type -- Table name, may be surrounded by double quotes
, p_column_aud$ins$who in user_tab_colums.column_name%type -- When not null this column will be renamed to AUD$INS$WHO
, p_column_aud$ins$where in user_tab_colums.column_name%type -- When not null this column will be renamed to AUD$INS$WHERE
, p_column_aud$ins$when in user_tab_colums.column_name%type -- When not null this column will be renamed to AUD$INS$WHEN
, p_column_aud$upd$who in user_tab_colums.column_name%type -- When not null this column will be renamed to AUD$UPD$WHO
, p_column_aud$upd$where in user_tab_colums.column_name%type -- When not null this column will be renamed to AUD$UPD$WHERE
, p_column_aud$upd$when in user_tab_colums.column_name%type -- When not null this column will be renamed to AUD$UPD$WHEN
);
/**

Will add these auditing columns to the table:
- AUD$INS$WHO
- AUD$INS$WHERE
- AUD$INS$WHEN
- AUD$UPD$WHO
- AUD$UPD$WHERE
- AUD$UPD$WHEN

When a p_column parameter is not empty,
the value of that parameter should be an existing column (may be surrounded by double quotes)
that will be renamed to the corresponding auditing column.

The datatype:
- WHO: VARCHAR2(128 CHAR)
- WHERE: VARCHAR2(128 CHAR)
- WHEN: TIMESTAMP WITH TIME ZONE (or the datatype of the old existing column)

When an auditing column already exists, nothing will happen.

The insert auditing columns will become an appropiate default so no auditing insert trigger is necessary.

The update auditing columns will be set in a dedicated auditing update trigger (created by ADD_AUDITING_TRIGGER).

The package CFG_INSTALL_DDL_PKG will be used for all DDL.

**/
procedure add_auditing_trigger
( p_table_name in user_tab_colums.table_name%type
);

procedure upd
( p_aud$upd$who in out nocopy varchar2
, p_aud$upd$where in out nocopy varchar2
, p_aud$upd$when in out nocopy timestamp with time zone -- standard
);
/**
Invoked by the trigger created by ADD_AUDITING_TRIGGER.

Will set the auditing values but only when null.

Functions used:
- AUD$UPD$WHO  : DATA_SESSION_USERNAME
- AUD$UPD$WHEN : DATA_TIMESTAMP
- AUD$UPD$WHERE: DATA_CALLER
**/

procedure upd
( p_aud$upd$who in out nocopy varchar2
, p_aud$upd$where in out nocopy varchar2
, p_aud$upd$when in out nocopy timestamp -- datatype of an old existing colum
);

procedure upd
( p_aud$upd$who in out nocopy varchar2
, p_aud$upd$where in out nocopy varchar2
, p_aud$upd$when in out nocopy date -- datatype of an old existing colum
);

END;
/
