CREATE TYPE "MSG_WITH_ID_KEY_TYP" AUTHID DEFINER UNDER MSG_TYP
(
/**
An object type meant for all messages having ID as the primary key.
**/

  final
  member procedure construct
  ( self in out nocopy msg_with_id_key_typ
  , p_source$ in varchar2
  , p_context$ in varchar2
  , p_id in integer -- sets self.key$ using anydata.ConvertNumber(p_id)
  )
/**
This procedure is there since Oracle Object Types do not allow to invoke a super constructor.
Therefore this procedure can be called instead in a sub type constructor like this:
```
(self as msg_with_id_key_typ).construct(p_source$, p_context$, p_id);
-- initialize other member attributes
```
**/

, final
  member function id
  return integer
/**
Return the id (via the self.key$.getnumber() function since self.key$ is an anydata).
**/

, overriding
  member procedure serialize
  ( self in msg_with_id_key_typ
  , p_json_object in out nocopy json_object_t
  )
/**
Serialize this type.
Every sub type must add its attributes (in capital letters).
**/
)
not final;
/

