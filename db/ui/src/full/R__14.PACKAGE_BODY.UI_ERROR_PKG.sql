create or replace package body ui_error_pkg
as
  --
  -- Function: apex_error_handling
  -- Purpose: Try to elegantly handle errors that occur while using the application.
  --
  function apex_error_handling ( p_error in apex_error.t_error )
  return apex_error.t_error_result
  is
    l_result          apex_error.t_error_result;
    l_constraint_name varchar2(255);
    l_module_name constant varchar2(60) := 'ui_error_pkg.apex_error_handling';

    function sqlerrm_to_sqlcode(p_sqlerrm in varchar2)
    return pls_integer
    is
    begin
      return to_number(substr(substr(p_sqlerrm, instr(p_sqlerrm, 'ORA')), 4, 6));
    end sqlerrm_to_sqlcode;

    function is_constraint_error(p_sqlcode in pls_integer)
    return boolean
    is
    begin
      return case when p_sqlcode in (-1, /*-2091,*/ -2290, -2291, -2292, -2293) then true else false end;
    end is_constraint_error;

    procedure trace(p_message in varchar2, p_p1 in varchar2, p_p2 in varchar2 default null)
    is
    begin
      apex_debug.trace(p_message, p_p1, p_p2);
$if cfg_pkg.c_debugging $then
      dbug.print(dbug."info", p_message, p_p1, p_p2);
$end
    end;    
  begin
$if cfg_pkg.c_debugging $then
    dbug.enter(l_module_name);
    dbug.print
    ( dbug."input"
    , 'p_error.message: %s; p_error.apex_error_code: %s; p_error.ora_sqlcode: %s; p_error.ora_sqlerrm: %s'
    , p_error.message
    , p_error.apex_error_code
    , p_error.ora_sqlcode
    , p_error.ora_sqlerrm
    );
$end
    -- apex_debug.enable(apex_debug.c_log_level_app_trace);
    apex_debug.enter
    ( p_routine_name => l_module_name
    , p_name01 => 'p_error.message'
    , p_value01 => p_error.message
    , p_name02 => 'p_error.additional_info'
    , p_value02 => p_error.additional_info
    , p_name03 => 'p_error.display_location'
    , p_value03 => p_error.display_location
    , p_name04 => 'p_error.association_type'
    , p_value04 => p_error.association_type
    , p_name05 => 'p_error.page_item_name'
    , p_value05 => p_error.page_item_name
    , p_name06 => 'p_error.is_internal_error'
    , p_value06 => apex_debug.tochar(p_error.is_internal_error)
    , p_name07 => 'p_error.is_common_runtime_error'
    , p_value07 => apex_debug.tochar(p_error.is_common_runtime_error)
    , p_name08 => 'p_error.apex_error_code'
    , p_value08 => p_error.apex_error_code
    , p_name09 => 'p_error.ora_sqlcode'
    , p_value09 => p_error.ora_sqlcode
    , p_name10 => 'p_error.ora_sqlerrm'
    , p_value10 => p_error.ora_sqlerrm
    );

    --
    --   -) ORA-12048: error encountered while refreshing materialized view "BONUS_DATA"."BNS_MV_BR_OPN_5" FOLLOWED BY
    --      ... ORA-02290: check constraint (BONUS_DATA.BR_OPN_5) violated OR
    --      ... ORA-12034: materialized view log on "BONUS_DATA"."BNS_OBJECTIVE_PLAN_DETAILS" younger than last refresh
    --   -) ORA-12008: error in materialized view or zonemap refresh path FOLLOWED BY
    --      ... ORA-02290: check constraint (BONUS_DATA.BR_OPN_3) violated
    --   -) ORA-02091: transaction rolled back (-> can hide a deferred constraint)
    --
    -- So transform l_error (the copy of p_error).
    if p_error.ora_sqlcode in (-12048, -12008, -2091)
    then
      declare
        l_error apex_error.t_error := p_error; -- manipulate it
        l_first_ora_error_text varchar2(32767) := null;
      begin
        l_error.is_internal_error := false;

        loop
          l_first_ora_error_text := apex_error.get_first_ora_error_text(p_error => l_error, p_include_error_no => true); -- Include ORA-xxxxx: 

          trace('l_first_ora_error_text: %s', l_first_ora_error_text);

          exit when l_first_ora_error_text is null;

          -- Let l_error.ora_sqlerrm point to the first ORA error plus the rest
          l_error.ora_sqlerrm := substr(l_error.ora_sqlerrm, instr(l_error.ora_sqlerrm, l_first_ora_error_text));
          
          trace('l_error.ora_sqlerrm: %s', l_error.ora_sqlerrm);
          
          l_error.ora_sqlcode := sqlerrm_to_sqlcode(l_first_ora_error_text);
          
          trace('l_error.ora_sqlcode: %s', l_error.ora_sqlcode);

          exit when is_constraint_error(l_error.ora_sqlcode);

          -- ORA-12034: materialized view log on "BONUS_DATA"."BNS_OBJECTIVE_PLAN_DETAILS" younger than last refresh
          if l_error.ora_sqlcode = -12034
          then
            -- The original error (p_error.ora_sqlerrm) is:
            --
            -- ORA-12048: error encountered while refreshing materialized view "BONUS_DATA"."BNS_MV_BR_OPN_5" ...
            --
            data_br_pkg.refresh_mv
            ( p_owner => replace(sys_context('userenv', 'current_schema'), '_UI', '_DATA')
            , p_mview_name => regexp_substr(p_error.ora_sqlerrm, '"([^"]+)"', 1, 2)
            );
          end if;

          -- Let l_error.ora_sqlerrm point to the position after the first ORA error
          l_error.ora_sqlerrm := substr(l_error.ora_sqlerrm, 1 + length(l_first_ora_error_text));
        end loop; 

        if l_first_ora_error_text is not null
        then
          return apex_error_handling(p_error => l_error);
        end if;
      end;
    end if;

    l_result := apex_error.init_error_result(p_error => p_error);
    -- If it is an internal error raised by APEX, like an invalid statement or
    -- code which can not be executed, the error text might contain security sensitive
    -- information. To avoid this security problem we can rewrite the error to
    -- a generic error message and log the original error message for further
    -- investigation by the help desk.
    if p_error.is_internal_error
    then
      -- mask all errors that are not common runtime errors (Access Denied
      -- errors raised by application / page authorization and all errors
      -- regarding session and session state)
      if not p_error.is_common_runtime_error
      then
        -- Submit into Team Development as feedback
        apex_util.submit_feedback (
            p_comment         => 'Unexpected Error',
            p_type            => 3,
            p_application_id  => v('APP_ID'),
            p_page_id         => v('APP_PAGE_ID'),
            p_email           => v('APP_USER'),
            p_label_01        => 'Session',
            p_attribute_01    => v('APP_SESSION'),
            p_label_02        => 'Language',
            p_attribute_02    => v('AI_LANGUAGE'),
            p_label_03        => 'Error orq_sqlcode',
            p_attribute_03    => p_error.ora_sqlcode,
            p_label_04        => 'Error message',
            p_attribute_04    => p_error.message,
            p_label_05        => 'UI Error message',
            p_attribute_05    => l_result.message
        );
        -- Log an Issues Developer Portal / JIRA     
        -- see other entries in Gist Dimitri Gielis
        --https://gist.github.com/dgielis/e97c94391058dcacb4a2b50e355d9445


        -- Change the message to the generic error message which doesn't expose
        -- any sensitive information.
        l_result.message         := 'An unexpected internal application error has occurred: ' || substr(p_error.message,0,3500);
        l_result.additional_info := null;
      end if;
    else
      -- Always show the error as inline error
      -- Note: If you have created manual tabular forms (using the package
      --       apex_item/htmldb_item in the SQL statement) you should still
      --       use "On error page" on that pages to avoid loosing entered data
      l_result.display_location := case
                                     when l_result.display_location = apex_error.c_on_error_page then apex_error.c_inline_in_notification
                                     else l_result.display_location
                                   end;
      -- If it's a constraint violation like
      --
      --   -) ORA-00001: unique constraint violated
      --   -) ORA-02290: check constraint violated
      --   -) ORA-02291: integrity constraint violated - parent key not found
      --   -) ORA-02292: integrity constraint violated - child record found
      --   -) ORA-02293: cannot validate (BONUS_DATA.BR_OPN_3) - check constraint violated
      --
      -- we try to get a friendly error message from our constraint lookup configuration.
      -- If we don't find the constraint in our lookup table we fallback to
      -- the original ORA error message.
      if is_constraint_error(p_error.ora_sqlcode)
      then
        l_constraint_name := apex_error.extract_constraint_name(p_error => p_error);
        l_result.message := APEX_LANG.MESSAGE(l_constraint_name);

        -- GJP 2020-03-02  Prepend the constraint name to get a better error message
        if l_result.message is not null
        then
          l_result.message := l_constraint_name || ': ' || l_result.message;
        else
          l_result.message := p_error.message;
        end if;

        trace('l_constraint_name: %s; l_result.message: %s', l_constraint_name, l_result.message);
      elsif p_error.ora_sqlcode = data_api_pkg.c_exception
      then
        declare
          l_first_ora_error_text constant varchar2(32767) := 
            apex_error.get_first_ora_error_text(p_error => p_error, p_include_error_no => true);-- Do include ORA-xxxxx: 
        begin
          -- Use APEX_LANG.MESSAGE to get a translation first, next use the default if not found.
          l_result.message := api_pkg.translate_error(l_first_ora_error_text, 'APEX_LANG.MESSAGE');
          if l_result.message is null or l_result.message = l_first_ora_error_text
          then
            l_result.message := api_pkg.translate_error(l_first_ora_error_text);
          end if;
        end;
        
        trace('l_result.message: %s', l_result.message);
      end if;
      -- If an ORA error has been raised, for example a raise_application_error(-20xxx, '...')
      -- in a table trigger or in a PL/SQL package called by a process and we
      -- haven't found the error in our lookup table, then we just want to see
      -- the actual error text and not the full error stack with all the ORA error numbers.
      if p_error.ora_sqlcode is not null and l_result.message = p_error.message
      then
        l_result.message := apex_error.get_first_ora_error_text (
                                p_error => p_error );

        trace('l_result.message: %s', l_result.message);
      end if;
      -- If no associated page item/tabular form column has been set, we can use
      -- apex_error.auto_set_associated_item to automatically guess the affected
      -- error field by examine the ORA error for constraint names or column names.
      if l_result.page_item_name is null and l_result.column_alias is null
      then
        apex_error.auto_set_associated_item
        ( p_error        => p_error
        , p_error_result => l_result
        );
      end if;
    end if;
    
    trace('l_result.message: %s', l_result.message);
    
$if cfg_pkg.c_debugging $then
    dbug.print
    ( dbug."output"
    , 'l_result.message: %s; l_result.additional_info: %s'
    , l_result.message
    , l_result.additional_info
    );
    dbug.leave;
$end
    
    return l_result;
    
$if cfg_pkg.c_debugging $then
  exception
    when others
    then
      dbug.leave_on_error;
      raise;
$end
  end apex_error_handling;

  function apex_error_handling
  ( p_sqlcode in integer
  , p_sqlerrm in varchar2
  , p_error_backtrace in varchar2
  )
  return apex_error.t_error_result
  is
    l_error apex_error.t_error;
  begin
    -- type t_error is record (
    --   message  varchar2(32767),             /* Error message which will be displayed */
    --   additional_info varchar2(32767),      /* Only used for display_location ON_ERROR_PAGE to display additional error information */
    --   display_location  varchar2(40),       /* Use constants "used for display_location" below */
    --   association_type  varchar2(40),       /* Use constants "used for asociation_type" below */
    --   page_item_name    varchar2(255),      /* Associated page item name */
    --   region_id         number,             /* Associated tabular form region id of the primary application */
    --   column_alias      varchar2(255),      /* Associated tabular form column alias */
    --   row_num           pls_integer,        /* Associated tabular form row */
    --   is_internal_error boolean,            /* Set to TRUE if it's a critical error raised by the APEX engine, like an invalid SQL/PLSQL statements, ... Internal Errors are always displayed on the Error Page */
    --   apex_error_code   varchar2(255),      /* Contains the system message code if it's an error raised by APEX */
    --   ora_sqlcode       number,             /* SQLCODE on exception stack which triggered the error, NULL if the error was not raised by an ORA error */
    --   ora_sqlerrm      varchar2(32767),     /* SQLERRM which triggered the error, NULL if the error was not raised by an ORA error */
    --   error_backtrace   varchar2(32767),     /* Output of sys.dbms_utility.format_error_backtrace or sys.dbms_utility.format_call_stack */
    --   error_statement   varchar2(32767),     /* Statement that was parsed when the error occurred - only suitable when parsing caused the error */
    --   component         apex.t_component /* Component which has been processed when the error occurred */
    -- );
    
    l_error.message           := p_sqlerrm;
    l_error.additional_info   := p_sqlerrm;
    l_error.display_location  := apex_error.c_inline_in_notification;
    l_error.association_type  := null;
    l_error.page_item_name    := null;
    l_error.region_id         := null;
    l_error.column_alias      := null;
    l_error.row_num           := null;
    l_error.is_internal_error := false;
    l_error.apex_error_code   := null;
    l_error.ora_sqlcode       := p_sqlcode;
    l_error.ora_sqlerrm       := p_sqlerrm;
    l_error.error_backtrace   := p_error_backtrace;
    l_error.error_statement   := null;

    return apex_error_handling(l_error);
  end apex_error_handling;

end ui_error_pkg;
/
