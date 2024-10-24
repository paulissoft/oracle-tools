alter type t_ref_constraint_object
  drop attribute base_object$ cascade;
alter type t_ref_constraint_object
  add attribute base_object$ clob cascade;
