alter type t_ref_constraint_object
  drop attribute ref_object$ cascade;
alter type t_ref_constraint_object
  add attribute ref_object$ ref t_constraint_object cascade;
