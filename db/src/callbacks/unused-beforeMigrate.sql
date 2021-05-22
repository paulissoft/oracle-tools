begin
  dbms_application_info.set_client_info('beforeMigrate');

  declare
    -- Oracle 10g R2:
    -- ORA-06550: line 1, column 7:
    -- PLS-00201: identifier 'ADMIN.EBR' must be declared
    -- ORA-06550: line 1, column 7:
    -- PL/SQL: Statement ignored
    -- ORA-06512: at line 9
    e_compilation_error exception;
    pragma exception_init(e_compilation_error, -6550);
    -- Oracle 11g:
    -- ORA-06576: not a valid function or procedure name
    e_invalid_procedure exception;
    pragma exception_init(e_invalid_procedure, -6576);
  begin
    execute immediate 'begin admin.ebr.migrate_init(p_schema => user); end;';
  exception
    when e_compilation_error or e_invalid_procedure
    then null;
  end;
end;
/
