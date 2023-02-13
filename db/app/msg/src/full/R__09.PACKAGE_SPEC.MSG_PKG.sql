CREATE OR REPLACE PACKAGE "MSG_PKG" AS 

procedure data2msg
( p_data_clob in clob
, p_msg_vc out nocopy varchar2
, p_msg_clob out nocopy clob
);

procedure data2msg
( p_data_blob in blob
, p_msg_raw out nocopy raw
, p_msg_blob out nocopy blob
);

end msg_pkg;
/

