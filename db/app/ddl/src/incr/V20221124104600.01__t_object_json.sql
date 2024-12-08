begin
  execute immediate q'[
CREATE TYPE "ORACLE_TOOLS"."T_OBJECT_JSON" AUTHID CURRENT_USER AS OBJECT
( dummy$ varchar2(1 byte)

, static
  function deserialize
  ( p_obj_type in varchar2 -- the (schema and) name of the object type to convert to, e.g. ORACLE_TOOLS.T_OBJECT_JSON
  , p_obj in clob -- the JSON representation
  )
  return oracle_tools.t_object_json
  deterministic
/** Deserialize a JSON object to an Oracle Object Type. **/
  
, final
  member function get_type
  ( self in oracle_tools.t_object_json
  )
  return varchar2
  deterministic
/** Get the schema and name of the type, e.g. SYS.NUMBER or ORACLE_TOOLS.T_OBJECT_JSON. **/
  
, final
  member function serialize
  ( self in oracle_tools.t_object_json
  )
  return clob
  deterministic
/** Serialize an Oracle Object Type to a JSON object. **/
  
, member procedure serialize
  ( self in oracle_tools.t_object_json
  , p_json_object in out nocopy json_object_t
  )
/** Serialize this type, every sub type must add its attributes (in capital letters). **/

, order member function compare
  ( self in oracle_tools.t_object_json
  , p_other_object_json in oracle_tools.t_object_json
  )
  return integer
  deterministic
/** Return a CLOB compare of these objects. **/

, final member function repr
  ( self in oracle_tools.t_object_json
  )
  return clob
  deterministic
/** Get the pretty printed JSON representation of this object type (or one of its sub types). **/
  
, final
  member procedure print
  ( self in oracle_tools.t_object_json
  )
/**
Print the object type and representation using dbug.print() or dbms_output.put_line().
At most 2000 characters are printed for the representation.
**/
)
not instantiable
not final]';
end;
/
