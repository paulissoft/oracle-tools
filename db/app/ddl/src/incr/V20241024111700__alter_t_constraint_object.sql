alter type oracle_tools.t_constraint_object
  add final static function deserialize(p_constraint_object in clob) return oracle_tools.t_constraint_object deterministic cascade;

alter type oracle_tools.t_constraint_object  
  add final member function serialize return clob deterministic cascade;
