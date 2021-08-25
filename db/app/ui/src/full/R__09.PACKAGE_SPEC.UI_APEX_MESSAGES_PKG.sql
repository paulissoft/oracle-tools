create or replace package ui_apex_messages_pkg authid current_user
as

/**
 *
 * Package to maintain Apex messages.
 *
 * The App Builder provides a page for this: Application -> Shared Components -> Text Messages.
 *
 * There are three procedures to insert, update or delete messages:
 *
 * <code>
 * APEX_LANG.CREATE_MESSAGE (
 *   p_application_id           IN NUMBER,
 *   p_name                     IN VARCHAR2,
 *   p_language                 IN VARCHAR2,
 *   p_message_text             IN VARCHAR2 )
 *
 * APEX_LANG.UPDATE_MESSAGE (
 *   p_id             IN NUMBER,
 *   p_message_text   IN VARCHAR2 )
 *
 * APEX_LANG.DELETE_MESSAGE (
 *   p_id IN NUMBER )
 * </code>
 *
 * The combination of application id, name and language (in lower case) seems
 * to be unique in an Apex workspace when you look at
 * APEX_LANG.UPDATE_MESSAGE.
 *
 * The strange thing about the interface is that there is no function to get
 * the id from an inserted message.  And the Apex views do not seem to have
 * the information neither.
 *
 * But I have found revealing information on 
 *
 *   https://community.oracle.com/tech/developers/discussion/716972/translating-messages-used-internally-by-apex-create-through-plsql
 *
 * and it appears that this query:
 *
 * <code>
 * select  aat.translation_entry_id
 * into    l_id
 * from    apex_application_translations aat
 * where   aat.application_id = p_application_id
 * and     aat.translatable_message = p_name
 * and     aat.language_code = lower(p_language) -- GJP 2021-01-26
 * </code>
 *
 * returns the id.
 * 
 * The view UI_APEX_MESSAGES_V has an instead of trigger so you can issue DML against it.
 *
 */

type t_rec is record
( application_id apex_application_translations.application_id%type
, name           apex_application_translations.translatable_message%type
, language       apex_application_translations.language_code%type -- in lower case
, message_text   apex_application_translations.message_text%type
, id             apex_application_translations.translation_entry_id%type
);

type t_tab is table of t_rec;

/**
 * Initialise an Apex session but only when not running Apex.
 *
 * NOTE: there is no active Apex session if and only if sys_context('APEX$SESSION', 'APP_SESSION') is null.
 *
 * This code is used to create an Apex session if necessary:
 *
 * <code>
 * ui_session_pkg.create_apex_session
 * ( p_app_id => p_application_id
 * , p_app_user => p_app_user
 * , p_app_page_id => p_app_page_id
 * )
 * </code>
 *
 * @param p_application_id  The application id
 * @param p_app_user        The username to create a session for
 * @param p_app_page_id     The application page id
 */
procedure init
( p_application_id in number
, p_app_user in varchar2 default 'ADMIN'
, p_app_page_id in number default 1
);

/**
 * Get the Apex messages.
 *
 * @param p_application_id  The application id (null means all)
 * @param p_name            The name of the message (null means all)
 * @param p_language        The language of the message (null means all)
 */
function get_messages
( p_application_id in number default null
, p_name in varchar2 default null
, p_language in varchar2 default null
)
return t_tab
pipelined;

/**
 * Insert, update, merge or delete an Apex runtime message in the context of an active Apex session.
 *
 * The merge is a combination of update or insert (upsert).
 *
 * @param p_application_id  The application id
 * @param p_name            The name of the message
 * @param p_language        The language of the message
 * @param p_message_text    The message text
 */
procedure insert_message
( p_application_id in number
, p_name in varchar2
, p_language in varchar2
, p_message_text in varchar2
);
  
procedure update_message
( p_application_id in number
, p_name in varchar2
, p_language in varchar2
, p_message_text in varchar2
);
  
procedure merge_message
( p_application_id in number
, p_name in varchar2
, p_language in varchar2
, p_message_text in varchar2
);
  
procedure delete_message
( p_application_id in number
, p_name in varchar2
, p_language in varchar2
);

/**
 *
 * Insert, update or delete an Apex runtime message in the context of an active Apex session.
 *
 * NOTE: you can only call this function in the context of an active Apex session.
 *
 * For insert mode you have to specify non-null values for the input
 * parameters (input/output parameter p_id is irrelevant).
 *
 * For update mode you have to specify non-null values for the input parameter
 * p_message_text and input/output parameter p_id.
 *
 * For delete mode you have to specify a non-null value for the input/output
 * parameter p_id and it will be nullified on return.
 *
 * @param p_action          The action: (I)nsert, (U)pdate or (D)elete
 * @param p_application_id  The application id
 * @param p_name            The name of the message
 * @param p_language        The language of the message
 * @param p_message_text    The message text
 * @param p_id              The primary key
 */
procedure dml
( p_action in varchar2
, p_application_id in number default null -- on update/delete null is allowed
, p_name in varchar2 default null         -- on update/delete null is allowed
, p_language in varchar2 default null     -- on update/delete null is allowed
, p_message_text in varchar2 default null -- on delete null is allowed
, p_id in out nocopy number
);  

$if cfg_pkg.c_testing $then

--%suitepath(UI)
--%suite

--%beforeall
procedure ut_setup;

--%afterall
procedure ut_teardown;

--%test
procedure ut_dml;

--%test
--%throws(value_error)
procedure ut_dml_update_null_id;

--%test
--%throws(value_error)
procedure ut_dml_update_null_message_text;

--%test
--%throws(value_error)
procedure ut_dml_delete_null_id;

$end

end ui_apex_messages_pkg;
/
