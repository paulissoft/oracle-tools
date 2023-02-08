CREATE OR REPLACE TYPE BODY "REST_WEB_SERVICE_TYP" AS

constructor function rest_web_service_typ
( self in out nocopy rest_web_service_typ
, p_source$ in varchar2
, p_context$ in varchar2
, p_url in varchar2
, p_http_method in varchar2
, p_username in varchar2 default null
, p_password in varchar2 default null
, p_scheme in varchar2 default 'Basic'
, p_proxy_override in varchar2 default null
, p_transfer_timeout in number default 180
, p_body_clob in clob default null
, p_body_blob in blob default null
, p_parms_clob in clob default null
, p_wallet_path in varchar2 default null
, p_wallet_pwd in varchar2 default null
, p_https_host in varchar2 default null
, p_credential_static_id in varchar2 default null
, p_token_url in varchar2 default null
, p_custom_data in clob default null
)
return self as result
is
  c_max_size_vc constant simple_integer := 4000;
  c_max_size_raw constant simple_integer := 2000;
begin
  (self as msg_typ).construct(p_source$, p_context$);
  self.url := p_url;
  self.http_method := p_http_method;
  self.username := p_username;
  self.password := p_password;
  self.scheme := p_scheme;
  self.proxy_override := p_proxy_override;
  self.transfer_timeout := p_transfer_timeout;
  if p_body_clob is not null and lengthb(dbms_lob.substr(lob_loc => p_body_clob, amount => c_max_size_vc + 1)) > c_max_size_vc 
  then
    self.body_vc := null;
    self.body_clob := p_body_clob;
  else
    -- lengthb(dbms_lob.substr(lob_loc => p_body_clob, amount => c_max_size_vc + 1)) <= c_max_size_vc
    -- =>
    -- dbms_lob.substr(lob_loc => p_body_clob, amount => c_max_size_vc) = dbms_lob.substr(lob_loc => p_body_clob, amount => c_max_size_vc + 1)
    self.body_vc := dbms_lob.substr(lob_loc => p_body_clob, amount => c_max_size_vc);
    self.body_clob := null;
  end if;  
  if p_body_blob is not null and utl_raw.length(dbms_lob.substr(lob_loc => p_body_blob, amount => c_max_size_raw + 1)) > c_max_size_raw
  then
    self.body_raw := null;
    self.body_blob := p_body_blob;
  else
    -- same reason as above
    self.body_raw := dbms_lob.substr(lob_loc => p_body_blob, amount => c_max_size_raw);
    self.body_blob := null;
  end if;  
  if p_parms_clob is not null and lengthb(dbms_lob.substr(lob_loc => p_parms_clob, amount => c_max_size_vc + 1)) > c_max_size_vc
  then
    self.parms_vc := null;
    self.parms_clob := p_parms_clob;
  else
    self.parms_vc := dbms_lob.substr(lob_loc => p_parms_clob, amount => c_max_size_vc);
    self.parms_clob := null;
  end if;  
  self.wallet_path := p_wallet_path;
  self.wallet_pwd := p_wallet_pwd;
  self.https_host := p_https_host;
  self.credential_static_id := p_credential_static_id;
  self.token_url := p_token_url;
  self.custom_data := p_custom_data;

  return;
end rest_web_service_typ;

overriding
member function must_be_processed
( self in rest_web_service_typ
, p_msg_just_created in integer -- True (1) or false (0)
)
return integer -- True (1) or false (0)
is
begin
  return 1;
end must_be_processed;

overriding
member procedure process$now
( self in rest_web_service_typ
)
is
  l_clob clob;
begin
  self.process(p_clob => l_clob);
end process$now;  

overriding
member procedure serialize
( self in rest_web_service_typ
, p_json_object in out nocopy json_object_t
)
is
  l_body_vc constant json_object_t := 
    case
      when self.body_vc is not null
      then json_object_t(self.body_vc)
      else null
    end;
  l_body_clob constant json_object_t := 
    case
      when self.body_clob is not null
      then json_object_t(self.body_clob)
      else null
    end;
  l_body_raw constant json_object_t := 
    case
      when self.body_raw is not null
      then json_object_t(to_blob(self.body_raw))
      else null
    end;
  l_body_blob constant json_object_t := 
    case
      when self.body_blob is not null
      then json_object_t(self.body_blob)
      else null
    end;
  l_parms_vc constant json_object_t := 
    case
      when self.parms_vc is not null
      then json_object_t(self.parms_vc)
      else null
    end;
  l_parms_clob constant json_object_t := 
    case
      when self.parms_clob is not null
      then json_object_t(self.parms_clob)
      else null
    end;
begin
  -- every sub type must first start with (self as <super type>).serialize(p_json_object)
  (self as msg_typ).serialize(p_json_object);

  p_json_object.put('URL', self.url);
  p_json_object.put('HTTP_METHOD', self.http_method);
  p_json_object.put('USERNAME', self.username);
  p_json_object.put('PASSWORD', self.password);
  p_json_object.put('SCHEME', self.scheme);
  p_json_object.put('PROXY_OVERRIDE', self.proxy_override);
  p_json_object.put('TRANSFER_TIMEOUT', self.transfer_timeout);
  if l_body_vc is not null
  then
    p_json_object.put('BODY_VC', l_body_vc);
  end if;
  if l_body_clob is not null
  then
    p_json_object.put('BODY_CLOB', l_body_clob);
  end if;
  if l_body_raw is not null
  then
    p_json_object.put('BODY_RAW', l_body_raw);
  end if;
  if l_body_blob is not null
  then
    p_json_object.put('BODY_BLOB', l_body_blob);
  end if;
  if l_parms_vc is not null
  then
    p_json_object.put('PARMS_VC', l_parms_vc);
  end if;
  if l_parms_clob is not null
  then
    p_json_object.put('PARMS_CLOB', l_parms_clob);
  end if;
  p_json_object.put('WALLET_PATH', self.wallet_path);
  p_json_object.put('WALLET_PWD', self.wallet_pwd);
  p_json_object.put('HTTPS_HOST', self.https_host);
  p_json_object.put('CREDENTIAL_STATIC_ID', self.credential_static_id);
  p_json_object.put('TOKEN_URL', self.token_url);
  p_json_object.put('CUSTOM_DATA', self.custom_data);
end serialize;

overriding
member function has_non_empty_lob
( self in rest_web_service_typ
)
return integer
is
begin
  return
    case
      when self.body_clob is not null then 1
      when self.body_blob is not null then 1
      when self.parms_clob is not null then 1
      else 0
    end;
end has_non_empty_lob;

member procedure process_preamble
( self in rest_web_service_typ
)
is
begin
  null;
end process_preamble;

member procedure process
( self in rest_web_service_typ
, p_clob out nocopy clob
)
is
  l_parm_names apex_application_global.vc_arr2 := apex_web_service.empty_vc_arr;
  l_parm_values apex_application_global.vc_arr2 := apex_web_service.empty_vc_arr;
  l_parms constant json_object_t := 
    case
      when self.parms_vc is not null
      then json_object_t(self.parms_vc)
      when self.parms_clob is not null
      then json_object_t(self.parms_clob)
      else null
    end;
  l_parms_keys constant json_key_list :=
    case
      when l_parms is not null
      then l_parms.get_keys
      else null
    end;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESS (1)');
$end

  if l_parms is not null
  then
    for i_idx in l_parms_keys.first .. l_parms_keys.last
    loop
      l_parm_names(l_parm_names.count+1) := l_parms_keys(i_idx);
      l_parm_values(l_parm_names.count+1) := l_parms.get(l_parms_keys(i_idx)).stringify;
    end loop;
  end if;
  
  p_clob := apex_web_service.make_rest_request
            ( p_url => self.url
            , p_http_method => self.http_method
            , p_username => self.username
            , p_password => self.password
            , p_scheme => self.scheme
            , p_proxy_override => self.proxy_override
            , p_transfer_timeout => self.transfer_timeout
            , p_body =>
                case
                  when self.body_vc is not null
                  then to_clob(self.body_vc)
                  when self.body_clob is not null
                  then self.body_clob
                  else empty_clob()
                end
            , p_body_blob =>
                case
                  when self.body_raw is not null
                  then to_blob(self.body_raw)
                  when self.body_blob is not null
                  then self.body_blob
                  else empty_blob()
                end
            , p_parm_name => l_parm_names
            , p_parm_value => l_parm_values
            , p_wallet_path => self.wallet_path
            , p_wallet_pwd => self.wallet_pwd
            , p_https_host => self.https_host
            , p_credential_static_id => self.credential_static_id
            , p_token_url => self.token_url
            );
            
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print
  ( dbug."output"
  , 'p_clob length: %s; contents (max 255 characters): "%s"'
  , dbms_lob.getlength(p_clob)
  , dbms_lob.substr(p_clob, 255)
  );
  dbug.leave;
$end
end process;

member procedure process
( self in rest_web_service_typ
, p_blob out nocopy blob
)
is
  l_parm_names apex_application_global.vc_arr2 := apex_web_service.empty_vc_arr;
  l_parm_values apex_application_global.vc_arr2 := apex_web_service.empty_vc_arr;
  l_parms constant json_object_t := 
    case
      when self.parms_vc is not null
      then json_object_t(self.parms_vc)
      when self.parms_clob is not null
      then json_object_t(self.parms_clob)
      else null
    end;
  l_parms_keys constant json_key_list :=
    case
      when l_parms is not null
      then l_parms.get_keys
      else null
    end;
begin
$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.enter($$PLSQL_UNIT_OWNER || '.' || $$PLSQL_UNIT || '.PROCESS (2)');
$end

  if l_parms is not null
  then
    for i_idx in l_parms_keys.first .. l_parms_keys.last
    loop
      l_parm_names(l_parm_names.count+1) := l_parms_keys(i_idx);
      l_parm_values(l_parm_names.count+1) := l_parms.get(l_parms_keys(i_idx)).stringify;
    end loop;
  end if;
  
  p_blob := apex_web_service.make_rest_request_b
            ( p_url => self.url
            , p_http_method => self.http_method
            , p_username => self.username
            , p_password => self.password
            , p_scheme => self.scheme
            , p_proxy_override => self.proxy_override
            , p_transfer_timeout => self.transfer_timeout
            , p_body =>
                case
                  when self.body_vc is not null
                  then to_clob(self.body_vc)
                  when self.body_clob is not null
                  then self.body_clob
                  else empty_clob()
                end
            , p_body_blob =>
                case
                  when self.body_raw is not null
                  then to_blob(self.body_raw)
                  when self.body_blob is not null
                  then self.body_blob
                  else empty_blob()
                end
            , p_parm_name => l_parm_names
            , p_parm_value => l_parm_values
            , p_wallet_path => self.wallet_path
            , p_wallet_pwd => self.wallet_pwd
            , p_https_host => self.https_host
            , p_credential_static_id => self.credential_static_id
            , p_token_url => self.token_url
            );

$if oracle_tools.cfg_pkg.c_debugging $then
  dbug.print(dbug."output", 'p_blob length: %s', dbms_lob.getlength(p_blob));
  dbug.leave;
$end
end process;

member procedure process_postamble
( self in rest_web_service_typ
)
is
begin
  null;
end process_postamble;

end;
/

