CREATE OR REPLACE PACKAGE "HTTP_REQUEST_RESPONSE_PKG" AUTHID DEFINER AS 

/**
A package with HTTP request response related functions and procedures.
**/

procedure to_json
( p_cookie_tab in http_cookie_tab_typ
, p_cookies out nocopy json_array_t
);
/** Convert a HTTP cookie table to a JSON array. **/

procedure to_json
( p_http_header_tab in property_tab_typ
, p_http_headers out nocopy json_array_t
);
/** Convert a HTTP header table to a JSON array. **/

procedure copy_parameters
( p_parms in property_tab_typ
, p_url_encode in boolean
, p_parameters out nocopy varchar2
);
/** Create a name=value list (separated by ampersands) where value may be URL encoded. **/

function get_cookie_idx
( p_cookies in http_cookie_tab_typ -- The cookies
, p_name in varchar2 -- The cookie name to search for
, p_ignore_case in boolean default false -- Must we ignore case (default NO)?
)
return positive -- null (not found) or a positive number (found)
deterministic;
/**

> Cookie names are case-sensitive.
> The RFC does not state that explicitly, but each case-insensitive comparison is stated so explicitly, and there is no such explicit statement regarding the name of the cookie.
> Chrome and Firefox both treat cookies as case-sensitive and preserve all case variants as distinct cookies.

See also [Is the name of a cookie case sensitive?](https://stackoverflow.com/questions/11311893/is-the-name-of-a-cookie-case-sensitive).

**/

function get_cookie
( p_cookies in http_cookie_tab_typ -- The cookies
, p_name in varchar2 -- The cookie name to search for
, p_ignore_case in boolean default false -- Must we ignore case (default NO)?
)
return varchar2 -- null (not found) or the cookie (found)
deterministic;
/** Uses get_cookie_idx to return the value when found. **/

function get_property_idx
( p_properties in property_tab_typ -- The properties (for instance HTTP headers)
, p_name in varchar2 -- The property to search for
, p_ignore_case in boolean default true -- Must we ignore case (default YES)?
)
return positive -- null (not found) or a positive number (found)
deterministic;
/**

> HTTP header names are case-insensitive (according to RFC 2616).

See also [Are HTTP headers case-sensitive?](https://stackoverflow.com/questions/5258977/are-http-headers-case-sensitive).
**/

function get_property
( p_properties in property_tab_typ -- The properties (for instance HTTP headers)
, p_name in varchar2 -- The property to search for
, p_ignore_case in boolean default true -- Must we ignore case (default YES)?
)
return varchar2 -- null (not found) or the property (found)
deterministic;
/** Uses get_property_idx to return the value when found. **/

function get_http_status_descr
( p_http_status_code in positiven -- Should be > 0
)
return varchar2
deterministic;
  
end http_request_response_pkg;
/

