alter type oracle_tools.t_named_object
  add final static function deserialize(p_named_object in clob) return oracle_tools.t_named_object deterministic cascade;

alter type oracle_tools.t_named_object  
  add final member function serialize return clob deterministic cascade;

