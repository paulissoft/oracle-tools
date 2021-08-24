CREATE OR REPLACE PACKAGE "UI_ERROR_PKG" 
as
  -- See https://gist.github.com/dgielis/050d3f2169a44afc39514171f6b6095a
  
  --
  -- Function: apex_error_handling
  -- Purpose: Try to elegantly handle errors that occur while using the application.
  --
  function apex_error_handling
  ( p_error in apex_error.t_error
  )
  return apex_error.t_error_result;

  -- To be used by dynamic actions
  function apex_error_handling
  ( p_sqlcode in integer
  , p_sqlerrm in varchar2
  , p_error_backtrace in varchar2 default sys.dbms_utility.format_error_backtrace
  )
  return apex_error.t_error_result;
  
end ui_error_pkg;
/

