create or replace view ui_apex_messages_v as
select  t.application_id
,       t.name
,       t.language
,       t.message_text
,       t.id
from    table(ui_apex_messages_pkg.get_messages(p_application_id => nv('APP_ID'))) t;

-- create instead of trigger in the same script since recreating the view drops the the trigger
create or replace trigger ui_apex_messages_trg
instead of insert or update or delete
on ui_apex_messages_v
for each row
begin
  if inserting
  then
    ui_apex_messages_pkg.insert_message
    ( p_application_id => :NEW.application_id 
    , p_name => :NEW.name
    , p_language => :NEW.language
    , p_message_text => :NEW.message_text
    );
  end if;

  -- NOTE: a merge delete does an update followed by a delete so try to execute both i.e. no elsif
  if updating
  then
    ui_apex_messages_pkg.update_message
    ( p_application_id => :NEW.application_id 
    , p_name => :NEW.name
    , p_language => :NEW.language
    , p_message_text => :NEW.message_text
    );
  end if;  

  -- see NOTE above
  if deleting
  then
    ui_apex_messages_pkg.delete_message
    ( p_application_id => :OLD.application_id 
    , p_name => :OLD.name
    , p_language => :OLD.language
    );
  end if;
end;
/
