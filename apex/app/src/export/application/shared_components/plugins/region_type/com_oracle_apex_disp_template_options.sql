prompt --application/shared_components/plugins/region_type/com_oracle_apex_disp_template_options
begin
--   Manifest
--     PLUGIN: COM.ORACLE.APEX.DISP_TEMPLATE_OPTIONS
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>67978470344966559
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_plugin(
 p_id=>wwv_flow_api.id(20187235773695490)
,p_plugin_type=>'REGION TYPE'
,p_name=>'COM.ORACLE.APEX.DISP_TEMPLATE_OPTIONS'
,p_display_name=>'Display Template Options'
,p_supported_ui_types=>'DESKTOP'
,p_image_prefix => nvl(wwv_flow_application_install.get_static_plugin_file_prefix('REGION TYPE','COM.ORACLE.APEX.DISP_TEMPLATE_OPTIONS'),'')
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'function is_default (',
'  p_template_type   in varchar2,',
'  p_template_name   in varchar2,',
'  p_css             in varchar2',
') return varchar2',
'is',
'    l_vc_arr2       APEX_APPLICATION_GLOBAL.VC_ARR2;',
'    stmt            varchar2(4000);',
'    l_table_name    varchar2(255);',
'    l_def_opt       varchar2(255);',
'    l_preset_opt    varchar2(255);',
'    l_flag          varchar2(1) := ''N'';',
'    ',
'begin',
'',
'  if p_template_type = ''REGION'' then',
'    l_table_name := ''APEX_APPLICATION_TEMP_REGION'';',
'  elsif p_template_type = ''BUTTON'' then',
'    l_table_name := ''APEX_APPLICATION_TEMP_BUTTON'';',
'  elsif p_template_type = ''PAGE'' then',
'    l_table_name := ''APEX_APPLICATION_TEMP_PAGE'';',
'  elsif p_template_type = ''REPORT'' then',
'    l_table_name := ''APEX_APPLICATION_TEMP_REPORT'';',
'  elsif p_template_type = ''FIELD'' then',
'    l_table_name := ''APEX_APPLICATION_TEMP_LABEL'';',
'  elsif p_template_type = ''LIST'' then',
'    l_table_name := ''APEX_APPLICATION_TEMP_LIST'';',
'  end if;',
'    ',
'  stmt := ''begin ',
'            select default_template_options, preset_template_options ',
'              into :into_bind_default, :into_bind_preset  from  '' ',
'                || l_table_name ',
'                || '' where template_name = :bind_name and application_id = ''||v(''APP_ID'')||''; end;'';',
'  ',
'   execute immediate stmt',
'               using out l_def_opt,',
'                     out l_preset_opt, ',
'                      IN p_template_name;',
'',
'    ',
'    if l_def_opt = p_css then',
'      l_flag :=''Y'';',
'    else',
'      l_vc_arr2 := APEX_UTIL.STRING_TO_TABLE(l_preset_opt);',
'      FOR z IN 1..l_vc_arr2.count LOOP',
'          if p_css = l_vc_arr2(z) then',
'            l_flag := ''Y'';',
'          end if;',
'      END LOOP;',
'    end if;',
'    ',
'    return l_flag;',
'    ',
'    exception when others then return ''N'';',
'    ',
'end is_default;',
'',
'',
'FUNCTION render(',
'    p_region              IN apex_plugin.t_region,',
'    p_plugin              IN apex_plugin.t_plugin,',
'    p_is_printer_friendly IN BOOLEAN )',
'  RETURN apex_plugin.t_region_render_result',
'IS',
'  p_template_type               varchar2(100) := p_region.attribute_01;',
'  p_template_name               varchar2(100) := COALESCE( p_region.attribute_02,',
'                                                           p_region.attribute_03,',
'                                                           p_region.attribute_04,',
'                                                           p_region.attribute_05,',
'                                                           p_region.attribute_06,',
'                                                           p_region.attribute_07);',
'  l_output_li                   clob;',
'  l_advanced_html               varchar2(100);',
'  l_advanced_class              varchar2(100);',
'  l_is_default_class            varchar2(100);',
'  l_default_icon                varchar2(100);',
'  l_general_icon                varchar2(100);',
'',
'  l_is_default                  varchar2(1);',
'  is_postfix_added              boolean := false;',
'  is_default_added_for_global   boolean := false;',
'  is_default_found              boolean := false;',
'  is_outside_set                boolean := true;',
'  l_rows                        clob;',
'',
'BEGIN',
'',
'    for c1 in ( select distinct',
'                    o.application_id,',
'                    nvl(g.display_name, ''General'') as group_name,',
'                    nvl(g.display_sequence, 0) display_sequence,',
'                    nvl(g.is_advanced, ''N'') is_advanced,',
'                    ''N'' as is_global,',
'                    g.null_text as default_text,',
'                    g.help_text,',
'                    o.group_id',
'                from apex_appl_template_options o,',
'                    apex_appl_template_opt_groups g',
'                where o.application_id = v(''APP_ID'')',
'                    and o.group_id         = g.template_opt_group_id (+)',
'                    and o.theme_number     = 42',
'                    and case p_template_type',
'                            when ''BUTTON'' then o.button_template',
'                            when ''REPORT'' then o.report_template',
'                            when ''REGION'' then o.region_template',
'                            when ''LIST''   then o.list_template',
'                            when ''PAGE''   then o.page_template',
'                        end = p_template_name',
'                union all',
'                select distinct',
'                    o.application_id,',
'                    nvl(g.display_name, ''General'') as group_name,',
'                    nvl(g.display_sequence, 0) display_sequence,',
'                    nvl(g.is_advanced, ''N'') is_advanced,',
'                    ''Y'' as is_global,',
'                    g.null_text as default_text,',
'                    g.help_text,',
'                    o.group_id',
'                from apex_appl_template_options o,',
'                    apex_appl_template_opt_groups g',
'                where o.application_id   = v(''APP_ID'')',
'                    and o.group_id = g.template_opt_group_id (+)',
'                    and o.theme_number = 42',
'                    and virtual_template_id is null',
'                    and o.template_types = p_template_type',
'                order by is_advanced,',
'                    display_sequence,',
'                    group_name ) loop',
'        -- Are we advanced?',
'        if c1.is_advanced = ''Y'' then',
'            l_advanced_html    := ''<span class="dm-TO-groupType">Advanced</span>'';',
'            l_advanced_class   := '' is-advanced'';',
'        end if;',
'        -- Emit the header',
'        l_output_li := l_output_li||''<li class="dm-TO-group''||l_advanced_class||'' row">',
'            <div class="dm-TO-info col col-4">''||l_advanced_html||',
'            ''<h3 class="dm-TO-groupTitle">''||c1.group_name||''</h3>',
'            <p class="dm-TO-groupDesc">'' || c1.help_text || ''</p>',
'            </div><div class="dm-TO-body col col-8">',
'            <ul class="dm-TO-optionsList container">'';',
'',
'        -- Do the rows',
'        is_default_found := false;',
'        l_rows           := null;',
'',
'        for c2 in ( select case p_template_type',
'                            when ''BUTTON'' then button_template',
'                            when ''REPORT'' then report_template',
'                            when ''FIELD''  then field_template',
'                            when ''REGION'' then region_template',
'                            when ''LIST''   then list_template',
'                            when ''PAGE''   then page_template',
'                        end as template_type,',
'                        o.display_name,',
'                        o.css_classes,',
'                        o.help_text,',
'                        nvl(o.display_sequence, 0) display_sequence',
'                    from apex_appl_template_options o',
'                    where o.application_id = c1.application_id',
'                        and o.theme_number = 42',
'                        and case p_template_type',
'                                when ''BUTTON'' then o.button_template',
'                                when ''REPORT'' then o.report_template',
'                                when ''REGION'' then o.region_template',
'                                when ''LIST''   then o.list_template',
'                                when ''PAGE''   then o.page_template',
'                            end = p_template_name',
'                        and ( (c1.group_id is null and o.group_id is null)',
'                            or o.group_id = c1.group_id )',
'                    union all',
'                    select ''Global'' as template_type,',
'                        o.display_name,',
'                        o.css_classes,',
'                        o.help_text,',
'                        nvl(o.display_sequence, 0) display_sequence',
'                    from apex_appl_template_options o',
'                    where o.application_id = c1.application_id',
'                        and o.theme_number = 42',
'                        and o.virtual_template_id is null',
'                        and o.template_types = p_template_type',
'                        and ( (c1.group_id is null and o.group_id is null)',
'                            or o.group_id = c1.group_id )',
'                    order by display_sequence ) loop',
'                    ',
'            if is_default(p_template_type, c2.template_type, c2.css_classes) = ''Y'' then',
'                is_default_found    := true;',
'                l_is_default_class  := ''is-default'';',
'                l_default_icon      := ''<span class="t-Icon fa fa-check-circle"></span>'';',
'                l_general_icon      := null;',
'            else',
'                l_is_default_class  := null;',
'                l_default_icon      := null;',
'                if c1.group_name = ''General'' then',
'                  l_general_icon    := ''<span class="t-Icon fa fa-square-o"></span>'';',
'                else',
'                  l_general_icon := null;',
'                end if;',
'            end if;',
'            ',
'            l_rows := l_rows || ''<li class="dm-TO-options '' || l_is_default_class || '' row">',
'                                <div class="dm-TO-option col col-4">'' || l_default_icon || l_general_icon || c2.display_name || ''</div>',
'                                <div class="dm-TO-desc col col-8">'' || c2.help_text ||''</div>',
'                              </li>'';',
'        end loop;',
'',
'        if is_default_found = false then',
'            if c1.default_text is not null then',
'                l_rows := ''<li class="dm-TO-options is-default row">',
'                                <div class="dm-TO-option col col-4"><span class="t-Icon fa fa-check-circle"></span>'' || c1.default_text || ''</div>',
'                                <div class="dm-TO-desc col col-8"></div>',
'                              </li>'' || l_rows;',
'            else',
'                l_rows := ''<li class="dm-TO-options is-default row">',
'                    <div class="dm-TO-option col col-4"><span class="t-Icon fa fa-check-square"></span>Use Template Defaults</div>',
'                    <div class="dm-TO-desc col col-8"></div>',
'                  </li>'' || l_rows;',
'            end if;',
'        end if;',
'            ',
'        l_output_li := l_output_li || l_rows;',
'        l_output_li := l_output_li || ''</ul></div></li>'';',
'    end loop;',
'',
'    sys.htp.p(''<div class="dm-TO"><ul class="dm-TO-list container">'' || l_output_li || ''</ul></div>'');',
'    return null;',
'END render;',
''))
,p_api_version=>1
,p_render_function=>'render'
,p_substitute_attributes=>true
,p_reference_id=>822240971540272233
,p_subscribe_plugin_settings=>true
,p_version_identifier=>'1.0'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(20187548121695497)
,p_plugin_id=>wwv_flow_api.id(20187235773695490)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_prompt=>'Template Type'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'BUTTON'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20187926822695498)
,p_plugin_attribute_id=>wwv_flow_api.id(20187548121695497)
,p_display_sequence=>10
,p_display_value=>'BUTTON'
,p_return_value=>'BUTTON'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20188409777695499)
,p_plugin_attribute_id=>wwv_flow_api.id(20187548121695497)
,p_display_sequence=>20
,p_display_value=>'REPORT'
,p_return_value=>'REPORT'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20188882191695499)
,p_plugin_attribute_id=>wwv_flow_api.id(20187548121695497)
,p_display_sequence=>30
,p_display_value=>'FIELD'
,p_return_value=>'FIELD'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20189400043695499)
,p_plugin_attribute_id=>wwv_flow_api.id(20187548121695497)
,p_display_sequence=>40
,p_display_value=>'REGION'
,p_return_value=>'REGION'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20189902366695499)
,p_plugin_attribute_id=>wwv_flow_api.id(20187548121695497)
,p_display_sequence=>50
,p_display_value=>'LIST'
,p_return_value=>'LIST'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20190398715695499)
,p_plugin_attribute_id=>wwv_flow_api.id(20187548121695497)
,p_display_sequence=>60
,p_display_value=>'PAGE'
,p_return_value=>'PAGE'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(20190900827695500)
,p_plugin_id=>wwv_flow_api.id(20187235773695490)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_prompt=>'Region'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>false
,p_default_value=>'Alert'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(20187548121695497)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'REGION'
,p_lov_type=>'STATIC'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20191343032695500)
,p_plugin_attribute_id=>wwv_flow_api.id(20190900827695500)
,p_display_sequence=>10
,p_display_value=>'Alert'
,p_return_value=>'Alert'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20191768176695500)
,p_plugin_attribute_id=>wwv_flow_api.id(20190900827695500)
,p_display_sequence=>20
,p_display_value=>'Hero'
,p_return_value=>'Hero'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20192346086695500)
,p_plugin_attribute_id=>wwv_flow_api.id(20190900827695500)
,p_display_sequence=>30
,p_display_value=>'Inline Dialog'
,p_return_value=>'Inline Dialog'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20192823404695500)
,p_plugin_attribute_id=>wwv_flow_api.id(20190900827695500)
,p_display_sequence=>40
,p_display_value=>'Collapsible'
,p_return_value=>'Collapsible'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20193309169695500)
,p_plugin_attribute_id=>wwv_flow_api.id(20190900827695500)
,p_display_sequence=>50
,p_display_value=>'Buttons Container'
,p_return_value=>'Buttons Container'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20193805015695501)
,p_plugin_attribute_id=>wwv_flow_api.id(20190900827695500)
,p_display_sequence=>60
,p_display_value=>'Tabs Container'
,p_return_value=>'Tabs Container'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20194282917695501)
,p_plugin_attribute_id=>wwv_flow_api.id(20190900827695500)
,p_display_sequence=>70
,p_display_value=>'Title Bar'
,p_return_value=>'Title Bar'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20194819892695501)
,p_plugin_attribute_id=>wwv_flow_api.id(20190900827695500)
,p_display_sequence=>80
,p_display_value=>'Standard'
,p_return_value=>'Standard'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20195364871695501)
,p_plugin_attribute_id=>wwv_flow_api.id(20190900827695500)
,p_display_sequence=>90
,p_display_value=>'Carousel Container'
,p_return_value=>'Carousel Container'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20195771185695501)
,p_plugin_attribute_id=>wwv_flow_api.id(20190900827695500)
,p_display_sequence=>100
,p_display_value=>'Interactive Report'
,p_return_value=>'Interactive Report'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20196268953695501)
,p_plugin_attribute_id=>wwv_flow_api.id(20190900827695500)
,p_display_sequence=>110
,p_display_value=>'Wizard Container'
,p_return_value=>'Wizard Container'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20196774745695501)
,p_plugin_attribute_id=>wwv_flow_api.id(20190900827695500)
,p_display_sequence=>120
,p_display_value=>'Blank with Attributes'
,p_return_value=>'Blank with Attributes'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(20197331590695502)
,p_plugin_id=>wwv_flow_api.id(20187235773695490)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_prompt=>'Page'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>false
,p_default_value=>'Modal Dialog'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(20187548121695497)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'PAGE'
,p_lov_type=>'STATIC'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20197725177695502)
,p_plugin_attribute_id=>wwv_flow_api.id(20197331590695502)
,p_display_sequence=>10
,p_display_value=>'Modal Dialog'
,p_return_value=>'Modal Dialog'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20198248787695502)
,p_plugin_attribute_id=>wwv_flow_api.id(20197331590695502)
,p_display_sequence=>20
,p_display_value=>'Wizard Modal Dialog'
,p_return_value=>'Wizard Modal Dialog'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(20198756452695502)
,p_plugin_id=>wwv_flow_api.id(20187235773695490)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_prompt=>'List'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>false
,p_default_value=>'Wizard Progress'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(20187548121695497)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'LIST'
,p_lov_type=>'STATIC'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20199161716695502)
,p_plugin_attribute_id=>wwv_flow_api.id(20198756452695502)
,p_display_sequence=>10
,p_display_value=>'Wizard Progress'
,p_return_value=>'Wizard Progress'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20199633483695502)
,p_plugin_attribute_id=>wwv_flow_api.id(20198756452695502)
,p_display_sequence=>20
,p_display_value=>'Top Navigation Menu'
,p_return_value=>'Top Navigation Menu'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20200090255695502)
,p_plugin_attribute_id=>wwv_flow_api.id(20198756452695502)
,p_display_sequence=>30
,p_display_value=>'Links List'
,p_return_value=>'Links List'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20200641389695503)
,p_plugin_attribute_id=>wwv_flow_api.id(20198756452695502)
,p_display_sequence=>40
,p_display_value=>'Menu Bar'
,p_return_value=>'Menu Bar'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20201140456695503)
,p_plugin_attribute_id=>wwv_flow_api.id(20198756452695502)
,p_display_sequence=>50
,p_display_value=>'Badge List'
,p_return_value=>'Badge List'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20201648811695503)
,p_plugin_attribute_id=>wwv_flow_api.id(20198756452695502)
,p_display_sequence=>60
,p_display_value=>'Media List'
,p_return_value=>'Media List'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20202157352695503)
,p_plugin_attribute_id=>wwv_flow_api.id(20198756452695502)
,p_display_sequence=>70
,p_display_value=>'Cards'
,p_return_value=>'Cards'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20202627033695503)
,p_plugin_attribute_id=>wwv_flow_api.id(20198756452695502)
,p_display_sequence=>80
,p_display_value=>'Tabs'
,p_return_value=>'Tabs'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20203144384695503)
,p_plugin_attribute_id=>wwv_flow_api.id(20198756452695502)
,p_display_sequence=>90
,p_display_value=>'Side Navigation Menu'
,p_return_value=>'Side Navigation Menu'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20203566555695503)
,p_plugin_attribute_id=>wwv_flow_api.id(20198756452695502)
,p_display_sequence=>100
,p_display_value=>'Top Navigation Tabs'
,p_return_value=>'Top Navigation Tabs'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(20204150482695504)
,p_plugin_id=>wwv_flow_api.id(20187235773695490)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_prompt=>'Report'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>false
,p_default_value=>'Standard'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(20187548121695497)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'REPORT'
,p_lov_type=>'STATIC'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20204554626695504)
,p_plugin_attribute_id=>wwv_flow_api.id(20204150482695504)
,p_display_sequence=>10
,p_display_value=>'Standard'
,p_return_value=>'Standard'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20204993205695504)
,p_plugin_attribute_id=>wwv_flow_api.id(20204150482695504)
,p_display_sequence=>20
,p_display_value=>'Cards'
,p_return_value=>'Cards'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20205554408695504)
,p_plugin_attribute_id=>wwv_flow_api.id(20204150482695504)
,p_display_sequence=>30
,p_display_value=>'Timeline'
,p_return_value=>'Timeline'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20206012692695504)
,p_plugin_attribute_id=>wwv_flow_api.id(20204150482695504)
,p_display_sequence=>40
,p_display_value=>'Badge List'
,p_return_value=>'Badge List'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20206467821695504)
,p_plugin_attribute_id=>wwv_flow_api.id(20204150482695504)
,p_display_sequence=>50
,p_display_value=>'Comments'
,p_return_value=>'Comments'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20206972851695504)
,p_plugin_attribute_id=>wwv_flow_api.id(20204150482695504)
,p_display_sequence=>60
,p_display_value=>'Value Attribute Pairs - Row'
,p_return_value=>'Value Attribute Pairs - Row'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20207496834695505)
,p_plugin_attribute_id=>wwv_flow_api.id(20204150482695504)
,p_display_sequence=>70
,p_display_value=>'Value Attribute Pairs - Column'
,p_return_value=>'Value Attribute Pairs - Column'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(20208031975695505)
,p_plugin_id=>wwv_flow_api.id(20187235773695490)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>60
,p_prompt=>'Button'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>false
,p_default_value=>'Text with Icon'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(20187548121695497)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'BUTTON'
,p_lov_type=>'STATIC'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20208387821695505)
,p_plugin_attribute_id=>wwv_flow_api.id(20208031975695505)
,p_display_sequence=>10
,p_display_value=>'Text with Icon'
,p_return_value=>'Text with Icon'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20208960200695505)
,p_plugin_attribute_id=>wwv_flow_api.id(20208031975695505)
,p_display_sequence=>20
,p_display_value=>'Icon Only'
,p_return_value=>'-'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20209461691695505)
,p_plugin_attribute_id=>wwv_flow_api.id(20208031975695505)
,p_display_sequence=>30
,p_display_value=>'Text Only'
,p_return_value=>'-'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(20209878737695505)
,p_plugin_id=>wwv_flow_api.id(20187235773695490)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>7
,p_display_sequence=>70
,p_prompt=>'Field'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>false
,p_default_value=>'Field'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(20187548121695497)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'FIELD'
,p_lov_type=>'STATIC'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(20210311700695505)
,p_plugin_attribute_id=>wwv_flow_api.id(20209878737695505)
,p_display_sequence=>10
,p_display_value=>'Field'
,p_return_value=>'Field'
);
wwv_flow_api.component_end;
end;
/
