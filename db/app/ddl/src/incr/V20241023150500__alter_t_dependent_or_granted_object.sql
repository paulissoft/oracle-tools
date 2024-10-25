alter type t_dependent_or_granted_object
  drop attribute base_object$ cascade;
alter type t_dependent_or_granted_object
  add attribute base_object$ ref t_named_object cascade;
