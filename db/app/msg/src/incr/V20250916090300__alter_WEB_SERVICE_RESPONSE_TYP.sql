alter type web_service_response_typ add
final member procedure get
( self in web_service_response_typ
, p_body_clob out nocopy clob
) cascade;

alter type web_service_response_typ add
final member procedure get
( self in web_service_response_typ
, p_body_blob out nocopy blob
) cascade;
