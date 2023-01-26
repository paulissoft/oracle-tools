CREATE TYPE DATA_ROW_ID_T AUTHID CURRENT_USER UNDER DATA_ROW_T
(
/**
An object type meant for all tables having ID as the primary key.
**/

  final
  member procedure construct
  ( self in out nocopy data_row_id_t
  , p_table_owner in varchar2
  , p_table_name in varchar2
  , p_dml_operation in varchar2
  , p_id in integer -- sets self.key using anydata.ConvertNumber(p_id)
  )
/*
This procedure is there since Oracle Object Types do not allow to invoke a super constructor.
Therefore this procedure can be called instead in a sub type constructor like this:
```
(self as data_row_id_t).construct(p_table_owner, p_table_name, p_dml_operation, p_id);
-- initialize other member attributes
```
*/

, final
  member function id
  return integer
/*
Return the id (via the self.key.getnumber() function since key is an anydata).
*/

, overriding
  member procedure serialize
  ( self in data_row_id_t
  , p_json_object in out nocopy json_object_t
  )
/*
Serialize this type.
Every sub type must add its attributes (in capital letters).
*/
)
not instantiable
not final;
/
