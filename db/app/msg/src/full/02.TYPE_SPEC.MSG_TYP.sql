CREATE TYPE "MSG_TYP" AUTHID DEFINER AS OBJECT
( group$ varchar2(128 char) -- to group together messages, for instance a qualified table name
, context$ varchar2(128 char) -- may be (I)nsert/(U)pdate/(D)elete on DML
, created_utc$ timestamp -- creation timestamp in UTC
/**
This type stores (meta-)information about a message. It is intended as a
generic type that can be used in Oracle Advanced Queueing (AQ).

The group$ will then be used as a queue name (with dots replaced by dollars).

We want to support buffered messages in AQ since it is fast (keeps things in
memory) and then you can not use not null LOBs since the Oracle AQ
documentation states this about enqueuing buffered messages: the queue type
for buffered messaging can be ADT, XML, ANYDATA, or RAW. For ADT types with
LOB attributes, only buffered messages with null LOB attributes can be
enqueued.

Therefore there are some member functions that determine whether a type may
have not null LOBs or a specific object may have them.
**/

, final member procedure construct
  ( self in out nocopy msg_typ
  , p_group$ in varchar2
  , p_context$ in varchar2
  )
/**
This procedure is there since Oracle Object Types do not allow to invoke a
super constructor.  Therefore this procedure can be called instead in a sub
type constructor like this:

(self as msg_typ).construct(p_group$, p_context$);

This procedure also sets created_utc$ to the system timestamp in UTC using
SYS_EXTRACT_UTC(SYSTIMESTAMP()).
**/

, member procedure process
  ( self in msg_typ
  , p_maybe_later in integer default 1 -- True (1) or false (0)
  )
/**
This is the main routine that determines whether to (finally) process a message.

Assuming that you use AQ (MSG_AQ_PKG) like this super type, these are the outcomes:
- not now (and not later), if self.must_be_processed(p_maybe_later) <> 1
- later, if self.must_be_processed(p_maybe_later) = 1 and you invoke self.process$later
- now, if self.must_be_processed(p_maybe_later) = 1 and you invoke self.process$now

This is the default implementation which postpones the actual work:

```
  if self.must_be_processed(p_maybe_later) = 1
  then
    case p_maybe_later
      when 1 then self.process$later;
      when 0 then self.process$now;
    end case;
  end if;
```

Assuming that you use AQ (MSG_AQ_PKG), the call self.process(1) must be
invoked when the message has just been created (for instance in a trigger),
meaning it will be enqueued for later processing.  When dequeued the call
self.process(0) should be invoked to do the actual job. Then
MSG_AQ_PKG.DEQUEUE_PROCESS will invoke self.process(0) for you.  You may
decide to override this in a subtype to force immediate processing like this:

```
  if self.must_be_processed(p_maybe_later) = 1
  then
    case p_maybe_later
      when 1 then self.process$now;
    end case;
  end if;
```
**/

, member function must_be_processed
  ( self in msg_typ
  , p_maybe_later in integer -- True (1) or false (0)
  )
  return integer -- True (1) or false (0)
/**
You must override this function that determines whether you want to process a
message at this stage (when just created or later).  First of all, you want
only to process messages that are interesting: you do NOT want to decrease
performance by queueing messages you will never process, don't you?  The next
thing is that messages may be not interesting later on (p_maybe_later =
0) due to elapsed time or some other reason.
**/

, member procedure process$now
  ( self in msg_typ
  )
/**
This method needs to be overridden: place here your custom code.  This code
should never be used in application code directly, just inside self.process().
**/

, member procedure process$later
  ( self in msg_typ
  )
/**
The code to use to process your message later.
This code should never be used in application code directly, just inside self.process().
This is the actual implementation:

```
MSG_AQ_PKG.ENQUEUE(self, ...);
```
**/

, static
  function deserialize
  ( p_obj_type in varchar2 -- the (schema and) name of the object type to convert to, e.g. MSG_TYP
  , p_obj in clob -- the JSON representation
  )
  return msg_typ
/** Deserialize a JSON object to an Oracle Object Type. **/
  
, final
  member function get_type
  ( self in msg_typ
  )
  return varchar2
/** Get the schema and name of the type, e.g. SYS.NUMBER or MSG_TYP. **/
  
, final
  member function serialize
  ( self in msg_typ
  )
  return clob
/** Serialize an Oracle Object Type to a JSON object. **/
  
, member procedure serialize
  ( self in msg_typ
  , p_json_object in out nocopy json_object_t
  )
/** Serialize this type, every sub type must add its attributes (in capital letters). **/
  
, member function repr
  ( self in msg_typ
  )
  return clob
/** Get the pretty printed JSON representation of a message (or one of its sub types). **/
  
, final
  member procedure print
  ( self in msg_typ
  )
/**
Print the object type and representation using dbug.print() or dbms_output.put_line().
At most 2000 characters are printed for the representation.
**/

, final
  member function lob_attribute_list
  ( self in msg_typ
  )
  return varchar2
/**
Returns the comma separated list of LOB attribute names for this type (self.get_type()).
The list is empty when there are no LOB attributes.
**/

, final
  member function may_have_not_null_lob
  ( self in msg_typ
  )
  return integer
/** Returns 1 (Yes) when self.lob_attribute_list() is not empty, else 0 (No). **/
  
, member function has_not_null_lob
  ( self in msg_typ
  )
  return integer
/** Has this message a not null LOB (BLOB or CLOB)? 0 for No, 1 for Yes. **/  
)
not final;
/

