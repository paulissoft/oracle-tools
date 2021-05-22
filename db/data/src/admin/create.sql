whenever sqlerror exit failure
set define on

define username = &&oracle_tools_schema
define user_tablespace = TBS_DATA_&&USERNAME
define temp_tablespace = TBS_TEMP_&&USERNAME

prompt Creating user &USERNAME

accept password prompt 'Password for user &USERNAME ? ' hide

select tablespace_name from user_tablespaces;

accept user_tablespace prompt 'User tablespace [&&user_tablespace] ? ' default '&&user_tablespace'
accept temp_tablespace prompt 'Temporary tablespace [&&temp_tablespace] ? ' default '&&temp_tablespace'

create user &username identified by "&&password" default tablespace &&user_tablespace temporary tablespace &&temp_tablespace;

alter user &username quota unlimited on &&user_tablespace;
