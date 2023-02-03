CREATE TYPE "MSG_TYP" AUTHID DEFINER AS OBJECT
( source$ varchar2(128 char) -- may be used as a queue name (with dots replaced by dollars)
, context$ varchar2(128 char) -- may be (I)nsert/(U)pdate/(D)elete on DML
, key$ anydata
, timestamp$ timestamp -- creation timestamp
/**
This type stores (meta-)information about a data row. It is intended as a generic type that can be used in Oracle Advanced Queueing.
**/

, final member procedure construct
  ( self in out nocopy msg_typ
  , p_source$ in varchar2
  , p_context$ in varchar2
  , p_key$ in anydata
  )
/*
This procedure is there since Oracle Object Types do not allow to invoke a super constructor.
Therefore this procedure can be called instead in a sub type constructor like this:

(self as msg_typ).construct(p_source$, p_context$, p_key$);

This procedure also sets timestamp$ to the sytem timestamp using the systimestamp() function.
*/

, member procedure process
  ( self in msg_typ
  , p_msg_just_created in integer default 1 -- True (1) or false (1)
  )
/*

This is the main routine that determines whether to process a message later or now.

This is the default implementation which postpones the actual work:

```
  if self.wants_to_process(p_msg_just_created) = 1
  then
    case p_msg_just_created
      when 1 then self.process$later;
      when 0 then self.process$now;
    end case;
  end if;
```

Assuming that you use AQ (MSG_AQ_PKG), the call self.process(1) must be invoked when the message has just been created (for instance in a trigger), meaning it will be enqueued for later processing.

When dequeued the call self.process(0) should be invoked to do the actual job. MSG_AQ_PKG.DEQUEUE invokes self.process(0) for you.

You may decide to override this in a subtype to force immediate processing like this:

```
  if self.wants_to_process(p_msg_just_created) = 1
  then
    case p_msg_just_created
      when 1 then self.process$now;
    end case;
  end if;
```

*/

, member function wants_to_process
  ( self in msg_typ
  , p_msg_just_created in integer -- True (1) or false (1)
  )
  return integer -- True (1) or false (1)
/*

You must override this function that determines whether you want to process a message at this stage (just created or later).

First of all, you want only to process messages that are interesting: you do NOT want to descrease performance by queueing messages you will never process, don't you?

The next thing is that messages may be not interesting later on (p_msg_just_created = 0) due to elapsed time or some other reason.

*/

, member procedure process$now
  ( self in msg_typ
  )
/*

This method needs to be overriden: place here your custom code.

This code should never be used in application code directly, just inside self.process().

*/

, member procedure process$later
  ( self in msg_typ
  )
/*

The code to use to process your message later.

This code should never be used in application code directly, just inside self.process().

This is the actual implementation:

```
MSG_AQ_PKG.ENQUEUE(self, ...);
```

*/

, static
  function deserialize
  ( p_obj_type in varchar2 -- the (schema and) name of the object type to convert to, e.g. MSG_TYP
  , p_obj in clob -- the JSON representation
  )
  return msg_typ
/* Deserialize a JSON object to an Oracle Object Type. */
  
, final
  member function get_type
  ( self in msg_typ
  )
  return varchar2
/* Get the schema and name of the type, e.g. SYS.NUMBER or ORACLE_TOOLS.MSG_TYP. */
  
, final
  member function serialize
  ( self in msg_typ
  )
  return clob
/* Serialize an Oracle Object Type to a JSON object. */
  
, member procedure serialize
  ( self in msg_typ
  , p_json_object in out nocopy json_object_t
  )
/* Serialize this type, every sub type must add its attributes (in capital letters). */
  
, member function repr
  ( self in msg_typ
  )
  return clob
/* Get the pretty printed JSON representation of a data row (or one of its sub types). */
  
, final
  member procedure print
  ( self in msg_typ
  )
/*
Print the object type and representation using dbug.print() or dbms_output.put_line().
At most 2000 characters are printed for the representation.
*/

, final
  member function lob_attribute_list
  ( self in msg_typ
  )
  return varchar2
/* Returns the comma separated list of LOB attribute names for this type (self.get_type()). The list is empty when there are no LOB attributes. */

, final
  member function may_have_non_empty_lob
  ( self in msg_typ
  )
  return integer
/* Returns 1 (Yes) when self.lob_attribute_list() is not empty, else 0 (No). */
  
, member function has_non_empty_lob
  ( self in msg_typ
  )
  return integer
/* Has this data row a non empty LOB (BLOB or CLOB)? 0 for No, 1 for Yes. */  
)
not final;
/

