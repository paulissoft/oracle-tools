CREATE OR REPLACE TYPE BODY "ORACLE_TOOLS"."T_SCHEMA_DDL_PARAMS" AS

overriding
member procedure serialize
( self in oracle_tools.t_schema_ddl_params
, p_json_object in out nocopy json_object_t
)
is
  procedure to_json_array(p_attribute in varchar2, p_str_tab in oracle_tools.t_text_tab)
  is
    l_json_array json_array_t;
  begin
    if p_str_tab is not null and p_str_tab.count > 0
    then
      l_json_array := json_array_t();
      for i_idx in 1 .. p_str_tab.count -- show all items
      loop
        l_json_array.append(p_str_tab(i_idx));
      end loop;
      p_json_object.put(p_attribute, l_json_array);
    end if;
  end to_json_array;
begin
  p_json_object.put('OBJECT_SCHEMA', self.object_schema);  
  p_json_object.put('BASE_OBJECT_SCHEMA', self.base_object_schema);
  p_json_object.put('BASE_OBJECT_TYPE', self.base_object_type);  
  to_json_array('OBJECT_NAME_TAB', self.object_name_tab);
  to_json_array('BASE_OBJECT_NAME_TAB', self.base_object_name_tab);
  p_json_object.put('NR_OBJECTS', self.nr_objects);
end serialize;

end;
/

