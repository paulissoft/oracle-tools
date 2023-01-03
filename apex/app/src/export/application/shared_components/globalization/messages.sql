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
,p_default_id_offset=>67978470344966559
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
,p_default_id_offset=>67978470344966559
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(34249929706553357)
,p_name=>'AAA'
,p_message_text=>'gfggf'
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(34249772699550599)
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
,p_default_id_offset=>67978470344966559
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(53359072665018404)
,p_name=>'DBMS_ASSERT.ENQUOTE_NAME'
,p_message_text=>'Can not enclose this "<p1>" name with quotes: <p2>'
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(53358920666018386)
,p_name=>'DBMS_ASSERT.ENQUOTE_NAME'
,p_message_language=>'nl'
,p_message_text=>'Kan geen quotes om deze "<p1>" naam zetten: <p2>'
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(53358642778018386)
,p_name=>'DBMS_ASSERT.QUALIFIED_SQL_NAME'
,p_message_text=>'This is no qualified SQL "<p1>" name: <p2>'
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(53358359222018385)
,p_name=>'DBMS_ASSERT.QUALIFIED_SQL_NAME'
,p_message_language=>'nl'
,p_message_text=>'Dit is geen gekwalificeerde SQL "<p1>" naam: <p2>'
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(53358069312018385)
,p_name=>'DBMS_ASSERT.SCHEMA_NAME'
,p_message_text=>'This is no "<p1>" schema name: <p2>'
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(53357708109018384)
,p_name=>'DBMS_ASSERT.SCHEMA_NAME'
,p_message_language=>'nl'
,p_message_text=>'Dit is geen "<p1>" schemanaam: <p2>'
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(53357422142018383)
,p_name=>'DBMS_ASSERT.SIMPLE_SQL_NAME'
,p_message_text=>'This is no simple SQL "<p1>" name: <p2>'
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(53357124915018383)
,p_name=>'DBMS_ASSERT.SIMPLE_SQL_NAME'
,p_message_language=>'nl'
,p_message_text=>'Dit is geen simpele SQL "<p1>" naam: <p2>'
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(53356772910018383)
,p_name=>'DBMS_ASSERT.SQL_OBJECT_NAME'
,p_message_text=>'This is no SQL "<p1>" object name: <p2>'
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(53356554836018382)
,p_name=>'DBMS_ASSERT.SQL_OBJECT_NAME'
,p_message_language=>'nl'
,p_message_text=>'Dit is geen SQL "<p1>" objectnaam: <p2>'
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
,p_default_id_offset=>67978470344966559
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(30544349742291907)
,p_name=>'ORACLE_TOOLS.FINISH_LOAD_FILE'
,p_message_text=>'This will load just one sheet (the first) from the spreadsheet file. The first row of that sheet must be the only header row. Do you want to continue?'
,p_is_js_message=>true
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(30136206474420853)
,p_name=>'ORACLE_TOOLS.FINISH_LOAD_FILE'
,p_message_language=>'fr'
,p_message_text=>unistr('Cela ne chargera qu''une seule feuille (la premi\00E8re) \00E0 partir du fichier de feuille de calcul et la premi\00E8re ligne de cette feuille doit \00EAtre la seule ligne d''en-t\00EAte. Voulez-vous continuer?')
,p_is_js_message=>true
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(30545874612351281)
,p_name=>'ORACLE_TOOLS.LOAD_FILE_WITHOUT_HISTORY'
,p_message_text=>'Are you sure you want to load this file without previous settings from region "Load file info history"? The first line has the best match.'
,p_is_js_message=>true
);
wwv_flow_api.create_message(
 p_id=>wwv_flow_api.id(30136297663420853)
,p_name=>'ORACLE_TOOLS.LOAD_FILE_WITHOUT_HISTORY'
,p_message_language=>'fr'
,p_message_text=>unistr('Voulez-vous vraiment charger ce fichier sans les param\00E8tres pr\00E9c\00E9dents de la r\00E9gion "Charger l''historique des informations sur le fichier"? La premi\00E8re ligne a le meilleur match.')
,p_is_js_message=>true
);
wwv_flow_api.component_end;
end;
/
