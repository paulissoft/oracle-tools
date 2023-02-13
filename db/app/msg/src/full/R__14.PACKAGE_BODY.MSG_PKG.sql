CREATE OR REPLACE PACKAGE BODY "MSG_PKG" AS

c_max_size_vc constant simple_integer := 4000;
c_max_size_raw constant simple_integer := 2000;

procedure data2msg
( p_data_clob in clob
, p_msg_vc out nocopy varchar2
, p_msg_clob out nocopy clob
)
is
begin
  if p_data_clob is not null and
     ( dbms_lob.getlength(lob_loc => p_data_clob) > c_max_size_vc or
       lengthb(dbms_lob.substr(lob_loc => p_data_clob, amount => c_max_size_vc)) > c_max_size_vc )
  then
    p_msg_vc := null;
    p_msg_clob := p_data_clob;
  else
    p_msg_vc := dbms_lob.substr(lob_loc => p_data_clob, amount => c_max_size_vc);
    p_msg_clob := null;
  end if;
end data2msg;

procedure data2msg
( p_data_blob in blob
, p_msg_raw out nocopy raw
, p_msg_blob out nocopy blob
)
is
begin
  if p_data_blob is not null and
     ( dbms_lob.getlength(lob_loc => p_data_blob) > c_max_size_raw or
       utl_raw.length(dbms_lob.substr(lob_loc => p_data_blob, amount => c_max_size_raw)) > c_max_size_raw )
  then
    p_msg_raw := null;
    p_msg_blob := p_data_blob;
  else
    p_msg_raw := dbms_lob.substr(lob_loc => p_data_blob, amount => c_max_size_raw);
    p_msg_blob := null;
  end if;
end data2msg;

end msg_pkg;
/

