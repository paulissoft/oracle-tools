CREATE OR REPLACE PACKAGE "MSG_PKG" AS 

procedure data2msg
( p_data_clob in clob
, p_msg_vc out nocopy varchar2
, p_msg_clob out nocopy clob
);

procedure msg2data
( p_msg_vc in varchar2
, p_msg_clob in clob
, p_data_json out nocopy json_element_t
);

procedure data2msg
( p_data_blob in blob
, p_msg_raw out nocopy raw
, p_msg_blob out nocopy blob
);

procedure msg2data
( p_msg_raw in raw
, p_msg_blob in blob
, p_data_json out nocopy json_element_t
);

end msg_pkg;
/

