CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_REF_CONSTRAINT_OBJECT" AS

constructor function t_ref_constraint_object
( self in out nocopy t_ref_constraint_object
, p_base_object in t_named_object
, p_object_schema in varchar2
, p_object_name in varchar2
, p_constraint_type in varchar2 default null
, p_column_names in varchar2 default null
, p_ref_object in t_named_object default null
)
return self as result
is
  l_owner all_objects.owner%type;
  l_table_name all_objects.object_name%type;
  l_tablespace_name all_tables.tablespace_name%type;

  cursor c_con(b_owner in varchar2, b_constraint_name in varchar2, b_table_name in varchar2)
  is
    select  con.owner
    ,       con.constraint_type
    ,       con.table_name
    ,       con.r_owner
    ,       con.r_constraint_name
    from    all_constraints con
    where   con.owner = b_owner
    and     con.constraint_name = b_constraint_name
    and     (b_table_name is null or con.table_name = b_table_name)
    ;

  r_con c_con%rowtype;
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.enter('T_REF_CONSTRAINT_OBJECT.T_REF_CONSTRAINT_OBJECT');
  dbug.print
  ( dbug."input"
  , 'p_base_object.id(): %s; p_object_schema: %s; p_object_name: %s; p_constraint_type: %s; p_column_names: %s'
  , p_base_object.id()
  , p_object_schema
  , p_object_name
  , p_constraint_type
  , p_column_names
  );
  if p_ref_object is not null
  then
    p_ref_object.print();
  end if;
$end

  self.base_object$ := p_base_object;
  self.network_link$ := null;
  self.object_schema$ := p_object_schema;
  self.object_name$ := p_object_name;
  self.column_names$ := nvl(p_column_names, t_constraint_object.get_column_names(p_object_schema, p_object_name, p_base_object.object_name()));
  self.search_condition$ := null;

  -- GPA 2017-01-18
  -- one combined query (twice all_constraints and once all_objects) was too slow.
  if p_constraint_type is not null and p_ref_object is not null
  then
    self.constraint_type$ := p_constraint_type;  
    self.ref_object$ := p_ref_object;  
  else
    begin
      self.constraint_type$ := null; -- to begin with
      
      open c_con(p_object_schema, p_object_name, p_base_object.object_name());
      fetch c_con into r_con;
      if c_con%found
      then
        close c_con; -- closed cursor indicates success
        
        self.constraint_type$ := r_con.constraint_type;

        -- get the referenced table/view
        open c_con(r_con.r_owner, r_con.r_constraint_name, null);
        fetch c_con into r_con;
        if c_con%found
        then
          close c_con; -- closed cursor indicates success

          begin
            select  t.owner
            ,       t.table_name as table_name
            ,       t.tablespace_name as tablespace_name
            into    l_owner
            ,       l_table_name
            ,       l_tablespace_name
            from    all_tables t
            where   t.owner = r_con.owner
            and     t.table_name = r_con.table_name
            ;
            self.ref_object$ := t_table_object(l_owner, l_table_name, l_tablespace_name);
          exception
            when no_data_found
            then
              -- reference constraints to views are possible too...
              select  v.owner
              ,       v.view_name as table_name
              into    l_owner
              ,       l_table_name
              from    all_views v
              where   v.owner = r_con.owner
              and     v.view_name = r_con.table_name
              ;
              self.ref_object$ := t_view_object(l_owner, l_table_name);
          end;
        end if;
      end if;

      -- closed cursor indicates success
      if c_con%isopen
      then
        close c_con;
        raise no_data_found;
      end if;
      
    exception
      when others
      then
        self.ref_object$ := null;
        -- chk() will signal this later on
    end;
  end if;
  
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 3 $then
  dbug.leave;
$end

  return;
end;

-- begin of getter(s)

overriding member function object_type
return varchar2
deterministic
is
begin
  return 'REF_CONSTRAINT';
end object_type;

member function ref_object_schema
return varchar2
deterministic
is
begin
  return case when self.ref_object$ is not null then self.ref_object$.object_schema() end;
end ref_object_schema;  

final member procedure ref_object_schema
( self in out nocopy t_ref_constraint_object
, p_ref_object_schema in varchar2
)
is
begin
  self.ref_object$.object_schema(p_ref_object_schema);
end ref_object_schema;

member function ref_object_type
return varchar2
deterministic
is
begin
  return case when self.ref_object$ is not null then self.ref_object$.object_type() end;
end ref_object_type;  

member function ref_object_name
return varchar2
deterministic
is
begin
  return case when self.ref_object$ is not null then self.ref_object$.object_name() end;
end ref_object_name;  

-- end of getter(s)

overriding final map member function signature
return varchar2
deterministic
is
begin
  return self.object_schema ||
         ':' ||
         self.object_type ||
         ':' ||
         null || -- constraints may be equal between (remote) schemas even though the name is different
         ':' || 
         self.base_object_schema ||
         ':' ||
         self.base_object_type ||
         ':' ||
         self.base_object_name ||
         ':' ||
         self.constraint_type ||
         ':' ||
         self.column_names ||
         ':' ||
         self.ref_object_schema ||
         ':' ||
         self.ref_object_type ||
         ':' ||
         self.ref_object_name;
end signature;

overriding member procedure chk
( self in t_ref_constraint_object
, p_schema in varchar2
)
is
begin
$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.enter('T_REF_CONSTRAINT_OBJECT.CHK');
$end

  pkg_ddl_util.chk_schema_object(p_constraint_object => self, p_schema => p_schema);
  
  if self.ref_object$ is null
  then
    raise_application_error(-20000, 'Reference object should not be empty.');
  end if;

$if cfg_pkg.c_debugging and pkg_ddl_util.c_debugging >= 2 $then
  dbug.leave;
$end
end chk;

end;
/

