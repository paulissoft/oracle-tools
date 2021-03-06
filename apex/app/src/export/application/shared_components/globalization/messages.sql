prompt --application/shared_components/globalization/messages
begin
--   Manifest
--     MESSAGES: 138
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>114929092615904275
,p_default_owner=>'ORACLE_TOOLS'
);
null;
wwv_flow_api.component_end;
end;
/
begin
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>114929092615904275
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(54129572710794891)
,p_name=>'AAA'
,p_message_text=>'gfggf'
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(54129729717797649)
,p_name=>'AAA'
,p_message_language=>'fr'
,p_message_text=>'gfggf'
);
wwv_flow_api.component_end;
end;
/
begin
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>114929092615904275
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(57835152675056341)
,p_name=>'ORACLE_TOOLS.FINISH_LOAD_FILE'
,p_message_text=>'This will load just one sheet (the first) from the spreadsheet file. The first row of that sheet must be the only header row. Do you want to continue?'
,p_is_js_message=>true
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(58243295942927395)
,p_name=>'ORACLE_TOOLS.FINISH_LOAD_FILE'
,p_message_language=>'fr'
,p_message_text=>unistr('Cela ne chargera qu''une seule feuille (la premi\00E8re) \00E0 partir du fichier de feuille de calcul et la premi\00E8re ligne de cette feuille doit \00EAtre la seule ligne d''en-t\00EAte. Voulez-vous continuer?')
,p_is_js_message=>true
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(57833627804996967)
,p_name=>'ORACLE_TOOLS.LOAD_FILE_WITHOUT_HISTORY'
,p_message_text=>'Are you sure you want to load this file without previous settings from region "Load file info history"? The first line has the best match.'
,p_is_js_message=>true
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(58243204753927395)
,p_name=>'ORACLE_TOOLS.LOAD_FILE_WITHOUT_HISTORY'
,p_message_language=>'fr'
,p_message_text=>unistr('Voulez-vous vraiment charger ce fichier sans les param\00E8tres pr\00E9c\00E9dents de la r\00E9gion "Charger l''historique des informations sur le fichier"? La premi\00E8re ligne a le meilleur match.')
,p_is_js_message=>true
);
wwv_flow_api.component_end;
end;
/
