set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- ORACLE Application Express (APEX) export file
--
-- You should run the script connected to SQL*Plus as the Oracle user
-- APEX_200200 or as the owner (parsing schema) of the application.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_api.import_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>67978470344966559
,p_default_owner=>'ORACLE_TOOLS'
);
end;
/
 
prompt APPLICATION 138 - Oracle Tools
--
-- Application Export:
--   Application:     138
--   Name:            Oracle Tools
--   Date and Time:   03:40 Monday June 7, 2021
--   Exported By:     ORACLE_TOOLS
--   Flashback:       0
--   Export Type:     Application Export
--     Pages:                     18
--       Items:                   90
--       Computations:             1
--       Validations:              7
--       Processes:               21
--       Regions:                 62
--       Buttons:                 32
--       Dynamic Actions:         23
--     Shared Components:
--       Logic:
--         Items:                  5
--         Processes:              1
--         Computations:           4
--         App Settings:           1
--         Build Options:          5
--       Navigation:
--         Lists:                  8
--         Breadcrumbs:            1
--           Entries:              4
--       Security:
--         Authentication:         1
--         Authorization:          3
--         ACL Roles:              3
--       User Interface:
--         Themes:                 1
--         Templates:
--           Page:                 9
--           Region:              15
--           Label:                7
--           List:                12
--           Popup LOV:            1
--           Calendar:             1
--           Breadcrumb:           1
--           Button:               3
--           Report:              10
--         LOVs:                  13
--         Shortcuts:              1
--         Plug-ins:               3
--       Globalization:
--         Messages:               6
--       Reports:
--       E-Mail:
--     Supporting Objects:  Included
--   Version:         20.2.0.00.20
--   Instance ID:     250161874321153
--

