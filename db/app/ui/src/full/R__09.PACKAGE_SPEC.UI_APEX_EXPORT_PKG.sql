CREATE OR REPLACE PACKAGE "UI_APEX_EXPORT_PKG" AUTHID CURRENT_USER
as

/**
 *
 * Package to export Apex applications.
 *
 * See also APEX_EXPORT:
 * - get_application()
 *
 */

subtype boolean_t is naturaln; -- 0/1

type item_rec_t is record
( code varchar2(5 byte) default 'FILE' -- error/file
, nr integer default 0
, line# integer default 0 -- 0 for heading
, line varchar2(32767 byte)
);

type item_tab_t is table of item_rec_t;

function get_application
( p_workspace_name          in varchar2
, p_application_id          in number
, p_type                    in apex_export.t_export_type       default apex_export.c_type_application_source
, p_split                   in boolean_t                       default 0
, p_with_date               in boolean_t                       default 0
, p_with_ir_public_reports  in boolean_t                       default 0
, p_with_ir_private_reports in boolean_t                       default 0
, p_with_ir_notifications   in boolean_t                       default 0
, p_with_translations       in boolean_t                       default 0
, p_with_original_ids       in boolean_t                       default 0
, p_with_no_subscriptions   in boolean_t                       default 0
, p_with_comments           in boolean_t                       default 0
, p_with_supporting_objects in varchar2                        default null
, p_with_acl_assignments    in boolean_t                       default 0
, p_components              in apex_t_varchar2                 default null
, p_with_audit_info         in apex_export.t_audit_type        default null
)
return item_tab_t pipelined; -- returns errors and/or files
/**

A copy of APEX_EXPORT.get_application (excluding obsolete parameters).
But instead of an array of type APEX_T_EXPORT_FILES it returns 'ERROR' and/or 'FILE' (code):
1. errors: for line# = 0 the Nth error (-- === error N ===) and for line# >0 the SQLERRM lines
2. files : for line# = 0 the Mth file and NAME (-- === file M: NAME ===) and for line# > 0 the lines of that file

**/

end ui_apex_export_pkg;
/

