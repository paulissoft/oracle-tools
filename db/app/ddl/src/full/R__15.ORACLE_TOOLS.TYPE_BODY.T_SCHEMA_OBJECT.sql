CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_SCHEMA_OBJECT" AS

final member function network_link
return varchar2
deterministic
is
begin
  return self.network_link$;
end network_link;

final member procedure network_link
( self in out nocopy oracle_tools.t_schema_object
, p_network_link in varchar2
)
is
begin
  self.network_link$ := p_network_link;
end network_link;

final member function object_schema
return varchar2
deterministic
is
begin
  return self.object_schema$;
end object_schema;

final member procedure object_schema
( self in out nocopy oracle_tools.t_schema_object
, p_object_schema in varchar2
)
is
begin
  self.object_schema$ := p_object_schema;
end object_schema;

member function object_name
return varchar2
deterministic
is
begin
  return null;
end object_name;

member function base_object_schema
return varchar2
deterministic
is
begin
  return null;
end base_object_schema;

member procedure base_object_schema
( self in out nocopy oracle_tools.t_schema_object
, p_base_object_schema in varchar2
)
is
begin
  raise_application_error(oracle_tools.pkg_ddl_error.c_not_implemented, 'An object of type ' || self.object_type() || ' can not set its base_object_schema.');
end base_object_schema;

member function base_object_type
return varchar2
deterministic
is
begin
  return null;
end base_object_type;

member function base_dict_object_type
return varchar2
deterministic
is
begin
  return null;
end base_dict_object_type;

member function base_object_name
return varchar2
deterministic
is
begin
  return null;
end base_object_name;

member function column_name
return varchar2
deterministic
is
begin
  return null;
end column_name;

member function grantee
return varchar2
deterministic
is
begin
  return null;
end grantee;

member function privilege
return varchar2
deterministic
is
begin
  return null;
end privilege;

member function grantable
return varchar2
deterministic
is
begin
  return null;
end grantable;

static function object_type_order
( p_object_type in varchar2
)
return integer
deterministic
is
begin
  return
    case p_object_type
      when 'SEQUENCE'              then  1
      when 'TYPE_SPEC'             then  2
      when 'CLUSTER'               then  3
      when 'AQ_QUEUE_TABLE'        then  4
      when 'AQ_QUEUE'              then  5
      when 'TABLE'                 then  6
      when 'DB_LINK'               then  7
      when 'FUNCTION'              then  8
      when 'PACKAGE_SPEC'          then  9
      when 'VIEW'                  then 10
      when 'PROCEDURE'             then 11
      when 'MATERIALIZED_VIEW'     then 12
      when 'MATERIALIZED_VIEW_LOG' then 13
      when 'PACKAGE_BODY'          then 14
      when 'TYPE_BODY'             then 15
      when 'INDEX'                 then 16
      when 'TRIGGER'               then 17
      when 'OBJECT_GRANT'          then 18
      when 'CONSTRAINT'            then 19
      when 'REF_CONSTRAINT'        then 20
      when 'SYNONYM'               then 21
      when 'COMMENT'               then 22
      when 'DIMENSION'             then 23
      when 'INDEXTYPE'             then 24
      when 'JAVA_SOURCE'           then 25
      when 'LIBRARY'               then 26
      when 'OPERATOR'              then 27
      when 'REFRESH_GROUP'         then 28
      when 'XMLSCHEMA'             then 29
      when 'PROCOBJ'               then 30
      else null
    end;
end object_type_order;

final member function object_type_order
return integer
deterministic
is
begin
  return oracle_tools.t_schema_object.object_type_order(self.object_type);
end object_type_order;

static function id
( p_object_schema in varchar2
, p_object_type in varchar2
, p_object_name in varchar2
, p_base_object_schema in varchar2
, p_base_object_type in varchar2
, p_base_object_name in varchar2
, p_column_name in varchar2
, p_grantee in varchar2
, p_privilege in varchar2
, p_grantable in varchar2
)
return varchar2
deterministic
is
  l_id varchar2(4000 char) := null;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter('ORACLE_TOOLS.T_SCHEMA_OBJECT.ID');
  dbug.print(dbug."input", 'p_object_schema: %s; p_object_type: %s; p_object_name: %s', p_object_schema, p_object_type, p_object_name);
  if not(p_base_object_schema is null and p_base_object_type is null and p_base_object_name is null)
  then
    dbug.print(dbug."input", 'p_base_object_schema: %s; p_base_object_type: %s; p_base_object_name: %s', p_base_object_schema, p_base_object_type, p_base_object_name);
  end if;
  if not(p_column_name is null)
  then
    dbug.print(dbug."input", 'p_column_name: %s', p_column_name);
  end if;
  if not(p_grantee is null and p_privilege is null and p_grantable is null)
  then
    dbug.print(dbug."input", 'p_grantee: %s; p_privilege: %s; p_grantable: %s', p_grantee, p_privilege, p_grantable);
  end if;
$end

  if p_object_type = 'OBJECT_GRANT'
  then
    l_id :=
      -- DBMS_METADATA does not determine object_name and base object_type
      -- :OBJECT_GRANT::<owner>::T_PROJECTITEMDOCUMENT:<owner>
      null || ':' ||
      p_object_type || ':' ||
      null || ':' ||
      -- base object
      p_base_object_schema || ':' ||
      null || ':' ||
      p_base_object_name || ':' ||
      -- column name
      null || ':' ||
      -- grantee
      p_grantee || ':' ||
      -- privilege
      p_privilege || ':' ||
      -- grantable
      p_grantable
      ;
  elsif p_object_type in ('TRIGGER', 'SYNONYM')
  then
    l_id :=
      -- DBMS_METADATA does not need to determine base object
      -- <owner>:TRIGGER:TR_BR_CATEGORY::::
      -- <owner>:PACKAGE_SPEC:IR_TO_MSEXCEL:::::
      p_object_schema || ':' ||
      p_object_type || ':' ||
      p_object_name || ':' ||
      -- base object
      null || ':' ||
      null || ':' ||
      null || ':' ||
      -- column name
      null || ':' ||
      -- grantee
      null || ':' ||
      -- privilege
      null || ':' ||
      -- grantable
      null
      ;
  elsif p_object_type in ('INDEX')
  then
    l_id :=
      -- DBMS_METADATA does not need to determine base object, but we do in oracle_tools.pkg_ddl_util.parse_ddl()
      -- <owner>:INDEX:DOCUMENT_PK::::
      p_object_schema || ':' ||
      p_object_type || ':' ||
      p_object_name || ':' ||
      -- base object
      p_base_object_schema || ':' ||
      null || ':' ||
      p_base_object_name || ':' ||
      -- column name
      null || ':' ||
      -- grantee
      null || ':' ||
      -- privilege
      null || ':' ||
      -- grantable
      null
      ;
  elsif p_object_type = 'COMMENT'
  then
    l_id :=
      -- object
      null || ':' ||
      p_object_type || ':' ||
      null || ':' ||
      -- base object
      p_base_object_schema || ':' ||
      p_base_object_type || ':' ||
      p_base_object_name || ':' ||
      -- column name
      p_column_name || ':' ||
      -- grantee
      null || ':' ||
      -- privilege
      null || ':' ||
      -- grantable
      null
      ;
  elsif p_object_type = 'PROCOBJ'
  then
    l_id :=
      -- object
      null || ':' ||
      p_object_type || ':' ||
      p_object_name || ':' ||
      -- base object
      null || ':' ||
      null || ':' ||
      null || ':' ||
      -- column name
      null || ':' ||
      -- grantee
      null || ':' ||
      -- privilege
      null || ':' ||
      -- grantable
      null
      ;
  else
    l_id :=
      -- object
      p_object_schema || ':' ||
      p_object_type || ':' ||
      p_object_name || ':' ||
      -- base object
      p_base_object_schema || ':' ||
      p_base_object_type || ':' ||
      p_base_object_name || ':' ||
      -- column name
      null || ':' ||
      -- grantee
      p_grantee || ':' ||
      -- privilege
      p_privilege || ':' ||
      -- grantable
      p_grantable
      ;
  end if;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.print(dbug."output", 'return: %s', l_id);
  dbug.leave;
$end

  return l_id;
end id;

member function id
return varchar2
deterministic
is
begin
  return oracle_tools.t_schema_object.id
         ( p_object_schema => self.object_schema
         , p_object_type => self.object_type
         , p_object_name => self.object_name
         , p_base_object_schema => self.base_object_schema
         , p_base_object_type => self.base_object_type
         , p_base_object_name => self.base_object_name
         , p_column_name => self.column_name
         , p_grantee => self.grantee
         , p_privilege => self.privilege
         , p_grantable => self.grantable
         );
end id;

map member function signature
return varchar2
deterministic
is
begin
  return self.id;
end signature;

static function dict2metadata_object_type
( p_dict_object_type in varchar2
)
return varchar2
deterministic
is
  l_metadata_object_type oracle_tools.pkg_ddl_util.t_metadata_object_type;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter('ORACLE_TOOLS.T_SCHEMA_OBJECT.DICT2METADATA_OBJECT_TYPE');
$end

  l_metadata_object_type := case
                              -- http://stackoverflow.com/questions/3235300/oracles-dbms-metadata-get-ddl-for-object-type-job
                              when p_dict_object_type in ('JOB', 'PROGRAM', 'RULE', 'RULE SET', 'EVALUATION CONTEXT')
                              then 'PROCOBJ'
                              when p_dict_object_type = 'GRANT'
                              then 'OBJECT_GRANT'
                              when p_dict_object_type in ('PACKAGE', 'TYPE')
                              then p_dict_object_type || '_SPEC'
                              when p_dict_object_type = 'QUEUE'
                              then 'AQ_QUEUE'
                              else replace(p_dict_object_type, ' ', '_')
                            end;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end

  return l_metadata_object_type;
end dict2metadata_object_type;

final member function dict2metadata_object_type
return varchar2
deterministic
is
begin
  return oracle_tools.t_schema_object.dict2metadata_object_type(self.object_type);
end dict2metadata_object_type;

member procedure print(self in oracle_tools.t_schema_object)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 1 $then
  dbug.enter('ORACLE_TOOLS.T_SCHEMA_OBJECT.PRINT');
  dbug.print(dbug."info", 'network link: %s; id: %s', self.network_link(), self.id());
  dbug.print(dbug."info", 'signature: %s', self.signature());
  dbug.leave;
$else
  null;
$end
end print;

static procedure create_schema_object
( p_object_schema in varchar2
, p_object_type in varchar2
, p_object_name in varchar2 default null
, p_base_object_schema in varchar2 default null
, p_base_object_type in varchar2 default null
, p_base_object_name in varchar2 default null
, p_column_name in varchar2 default null
, p_grantee in varchar2 default null
, p_privilege in varchar2 default null
, p_grantable in varchar2 default null
, p_schema_object out nocopy oracle_tools.t_schema_object
)
is
  l_base_object_schema all_objects.owner%type := p_base_object_schema;
  l_base_object_name all_objects.object_name%type := p_base_object_name;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('ORACLE_TOOLS.T_SCHEMA_OBJECT.CREATE_SCHEMA_OBJECT (1)');
  dbug.print
  ( dbug."input"
  , 'p_object_schema: %s; p_object_type: %s; p_object_name: %s'
  , p_object_schema
  , p_object_type
  , p_object_name
  );
  if p_base_object_schema is not null or p_base_object_type is not null or p_base_object_name is not null
  then
    dbug.print
    ( dbug."input"
    , 'p_base_object_schema: %s; p_base_object_type: %s; p_base_object_name: %s'
    , p_base_object_schema
    , p_base_object_type
    , p_base_object_name
    );
  end if;
  if p_column_name is not null or p_grantee is not null or p_privilege is not null or p_grantable is not null
  then
    dbug.print
    ( dbug."input"
    , 'p_column_name: %s; p_grantee: %s; p_privilege: %s; p_grantable: %s'
    , p_column_name
    , p_grantee
    , p_privilege
    , p_grantable
    );
  end if;
$end

  case p_object_type
    when 'INDEX' -- a named object with a base named object
    then
      -- base_object_type is corrected in create_named_object()
      if l_base_object_schema is null or l_base_object_name is null
      then
        select  i.table_owner
        ,       i.table_name
        into    l_base_object_schema
        ,       l_base_object_name
        from    all_indexes i
        where   i.owner = p_object_schema
        and     i.index_name = p_object_name
        and     ( l_base_object_schema is null or i.table_owner = l_base_object_schema )
        and     ( l_base_object_name is null or i.table_name = l_base_object_name )
        ;
      end if;
      
      p_schema_object :=
        oracle_tools.t_index_object
        ( p_base_object =>
            oracle_tools.t_named_object.create_named_object
            ( p_object_schema => l_base_object_schema
            , p_object_type => p_base_object_type
            , p_object_name => l_base_object_name
            )
        , p_object_schema => p_object_schema
        , p_object_name => p_object_name
        , p_tablespace_name => null
        );

    when 'TRIGGER' -- a named object with a base named object
    then
      -- base_object_type is corrected in create_named_object()
      if l_base_object_schema is null or l_base_object_name is null
      then
        select  t.table_owner
        ,       t.table_name
        into    l_base_object_schema
        ,       l_base_object_name
        from    all_triggers t
        where   t.owner = p_object_schema
        and     t.trigger_name = p_object_name
        and     ( l_base_object_schema is null or t.table_owner = l_base_object_schema )
        and     ( l_base_object_name is null or t.table_name = l_base_object_name )
        ;
      end if;
      
      p_schema_object :=
        oracle_tools.t_trigger_object
        ( p_base_object =>
            oracle_tools.t_named_object.create_named_object
            ( p_object_schema => l_base_object_schema
            , p_object_type => p_base_object_type
            , p_object_name => l_base_object_name
            )
        , p_object_schema => p_object_schema
        , p_object_name => p_object_name
        );

    when 'OBJECT_GRANT'
    then
      p_schema_object :=
        oracle_tools.t_object_grant_object
        ( p_base_object =>
            oracle_tools.t_named_object.create_named_object
            ( p_object_schema => p_base_object_schema
            , p_object_type => p_base_object_type
            , p_object_name => p_base_object_name
            )
        , p_object_schema => p_object_schema
        , p_grantee => p_grantee
        , p_privilege => p_privilege
        , p_grantable => p_grantable
        );

    when 'CONSTRAINT'
    then
      p_schema_object :=
        oracle_tools.t_constraint_object
        ( p_base_object =>
            oracle_tools.t_named_object.create_named_object
            ( p_object_schema => p_base_object_schema
            , p_object_type => p_base_object_type
            , p_object_name => p_base_object_name
            )
        , p_object_schema => p_object_schema
        , p_object_name => p_object_name
        );

    when 'REF_CONSTRAINT'
    then
      p_schema_object :=
        oracle_tools.t_ref_constraint_object
        ( p_base_object =>
            oracle_tools.t_named_object.create_named_object
            ( p_object_schema => p_base_object_schema
            , p_object_type => p_base_object_type
            , p_object_name => p_base_object_name
            )
        , p_object_schema => p_object_schema
        , p_object_name => p_object_name
        );

    when 'SYNONYM' -- a named object with a base named object
    then
      -- base_object_type is corrected in create_named_object()
      if l_base_object_schema is null or l_base_object_name is null
      then
        select  s.table_owner
        ,       s.table_name
        into    l_base_object_schema
        ,       l_base_object_name
        from    all_synonyms s
        where   s.owner = p_object_schema
        and     s.synonym_name = p_object_name
        and     ( l_base_object_schema is null or s.table_owner = l_base_object_schema )
        and     ( l_base_object_name is null or s.table_name = l_base_object_name )
        ;
      end if;
      
      p_schema_object :=
        oracle_tools.t_synonym_object
        ( p_base_object =>
            oracle_tools.t_named_object.create_named_object
            ( p_object_schema => l_base_object_schema
            , p_object_type => p_base_object_type
            , p_object_name => l_base_object_name
            )
        , p_object_schema => p_object_schema
        , p_object_name => p_object_name
        );

    when 'COMMENT'
    then
      p_schema_object :=
        oracle_tools.t_comment_object
        ( p_base_object =>
            oracle_tools.t_named_object.create_named_object
            ( p_object_schema => p_base_object_schema
            , p_object_type => p_base_object_type
            , p_object_name => p_base_object_name
            )
        , p_object_schema => p_object_schema
        , p_column_name => p_column_name
        );

    else
-- when 'SEQUENCE'
-- when 'TYPE_SPEC'
-- when 'CLUSTER'
-- when 'AQ_QUEUE_TABLE'
-- when 'AQ_QUEUE'
-- when 'TABLE'
-- when 'DB_LINK'
-- when 'FUNCTION'
-- when 'PACKAGE_SPEC'
-- when 'VIEW'
-- when 'PROCEDURE'
-- when 'MATERIALIZED_VIEW'
-- when 'MATERIALIZED_VIEW_LOG'
-- when 'PACKAGE_BODY'
-- when 'TYPE_BODY'
-- when 'DIMENSION'
-- when 'INDEXTYPE'
-- when 'JAVA_SOURCE'
-- when 'LIBRARY'
-- when 'OPERATOR'
-- when 'REFRESH_GROUP'
-- when 'XMLSCHEMA'
-- when 'PROCOBJ'
      oracle_tools.t_named_object.create_named_object
      ( p_object_schema => p_object_schema
      , p_object_type => p_object_type
      , p_object_name => p_object_name
      , p_named_object => p_schema_object
      );
  end case;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end create_schema_object;

static function create_schema_object
( p_object_schema in varchar2
, p_object_type in varchar2
, p_object_name in varchar2 default null
, p_base_object_schema in varchar2 default null
, p_base_object_type in varchar2 default null
, p_base_object_name in varchar2 default null
, p_column_name in varchar2 default null
, p_grantee in varchar2 default null
, p_privilege in varchar2 default null
, p_grantable in varchar2 default null
)
return oracle_tools.t_schema_object
is
   l_schema_object oracle_tools.t_schema_object;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('ORACLE_TOOLS.T_SCHEMA_OBJECT.CREATE_SCHEMA_OBJECT (2)');
$end

  oracle_tools.t_schema_object.create_schema_object
  ( p_object_schema => p_object_schema
  , p_object_type => p_object_type
  , p_object_name => p_object_name
  , p_base_object_schema => p_base_object_schema
  , p_base_object_type => p_base_object_type
  , p_base_object_name => p_base_object_name
  , p_column_name => p_column_name
  , p_grantee => p_grantee
  , p_privilege => p_privilege
  , p_grantable => p_grantable
  , p_schema_object => l_schema_object
  );

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end

  return l_schema_object;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
exception
  when others
  then
    dbug.leave_on_error;
    raise;
$end
end create_schema_object;

static function is_a_repeatable
( p_object_type in varchar2
)
return integer
deterministic
is
begin
  -- See generate_ddl.pl documentatation
  return
    case dict2metadata_object_type(p_object_type)
      -- schema objects
      when 'SEQUENCE' then 0
      when 'TYPE_SPEC' then 0 -- can not replace a type when it is used by another object
      when 'CLUSTER' then 0
      when 'AQ_QUEUE_TABLE' then 0
      when 'AQ_QUEUE' then 0
      when 'TABLE' then 0
      when 'COMMENT' then 1
      when 'FUNCTION' then 1
      when 'PACKAGE_SPEC' then 1
      when 'VIEW' then 1
      when 'PROCEDURE' then 1
      when 'MATERIALIZED_VIEW' then 0
      when 'MATERIALIZED_VIEW_LOG' then 0
      when 'PACKAGE_BODY' then 1
      when 'TYPE_BODY' then 1
      when 'INDEX' then 0
      when 'TRIGGER' then 1
      when 'OBJECT_GRANT' then 1
      when 'CONSTRAINT' then 0
      when 'REF_CONSTRAINT' then 0
      when 'SYNONYM' then 1
      when 'DB_LINK' then 0
      when 'DIMENSION' then 0
      when 'INDEXTYPE' then 1
      when 'JAVA_SOURCE' then 1
      when 'LIBRARY' then 1
      when 'OPERATOR' then 1
      when 'REFRESH_GROUP' then 0
      when 'XMLSCHEMA' then 0
      when 'PROCOBJ' then 0

      -- non schema objects
      when 'CONTEXT' then 1
      when 'DIRECTORY' then 1
      when 'SYSTEM_GRANT' then 1
    end;
end is_a_repeatable;

member function is_a_repeatable
return integer
deterministic
is
begin
  return oracle_tools.t_schema_object.is_a_repeatable(self.object_type());
end is_a_repeatable;

final member function fq_object_name
return varchar2
deterministic
is
  l_object_name varchar2(4000 char);

  function get_object_part(p_object_part in varchar2)
  return varchar2
  is
  begin
    return case when upper(p_object_part) != p_object_part then '"' || p_object_part || '"' else p_object_part end;
  end get_object_part;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter('ORACLE_TOOLS.T_SCHEMA_OBJECT.FQ_OBJECT_NAME');
$end

  l_object_name :=
    get_object_part(object_schema())
    || '.'
    || get_object_part(object_name())
    ;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.print(dbug."output", 'return: %s', l_object_name);
  dbug.leave;
$end

  return l_object_name;
end fq_object_name;

member function dict_object_type
return varchar2
deterministic
is
  l_dict_object_type oracle_tools.pkg_ddl_util.t_dict_object_type;
  l_metadata_object_type oracle_tools.pkg_ddl_util.t_metadata_object_type;
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter('ORACLE_TOOLS.T_SCHEMA_OBJECT.DICT_OBJECT_TYPE');
$end

  l_metadata_object_type := self.object_type();

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.print(dbug."info", 'l_metadata_object_type: %s', l_metadata_object_type);
$end

  l_dict_object_type :=
    case
      when l_metadata_object_type in ('PACKAGE_SPEC', 'TYPE_SPEC')
      then replace(l_metadata_object_type, '_SPEC')
      when l_metadata_object_type = 'AQ_QUEUE'
      then 'QUEUE'
      else replace(l_metadata_object_type, '_', ' ')
    end;

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 3 $then
  dbug.print(dbug."output", 'return: %s', l_dict_object_type);
  dbug.leave;
$end

  return l_dict_object_type;
end dict_object_type;

member procedure chk
( self in oracle_tools.t_schema_object
, p_schema in varchar2
)
is
begin
$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('ORACLE_TOOLS.T_SCHEMA_OBJECT.CHK');
$end

  oracle_tools.pkg_ddl_util.chk_schema_object(p_schema_object => self, p_schema => p_schema);

$if oracle_tools.cfg_pkg.c_debugging and oracle_tools.pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end chk;

end;
/

