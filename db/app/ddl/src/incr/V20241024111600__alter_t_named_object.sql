alter type oracle_tools.t_named_object
  add final static function deserialize(p_text_tab in oracle_tools.t_text_tab) return oracle_tools.t_named_object deterministic cascade;

alter type oracle_tools.t_named_object  
  add final member function serialize return oracle_tools.t_text_tab deterministic cascade;

