prompt --application/shared_components/plugins/region_type/com_oracle_apex_how_to_instructions
begin
--   Manifest
--     PLUGIN: COM.ORACLE.APEX.HOW_TO_INSTRUCTIONS
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>107828709909037496
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_plugin(
 p_id=>wwv_flow_api.id(39662396918384769)
,p_plugin_type=>'REGION TYPE'
,p_name=>'COM.ORACLE.APEX.HOW_TO_INSTRUCTIONS'
,p_display_name=>'How To Instructions'
,p_supported_ui_types=>'DESKTOP'
,p_image_prefix => nvl(wwv_flow_application_install.get_static_plugin_file_prefix('REGION TYPE','COM.ORACLE.APEX.HOW_TO_INSTRUCTIONS'),'')
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'procedure concat (',
'    p_result in out nocopy varchar2,',
'    p_text   in            varchar2 )',
'is',
'begin',
'    if p_text is not null then',
'        p_result := p_result || p_text; ',
'    end if;',
'end concat;',
'',
'function yes_or_no (',
'    p_true_or_false in boolean )',
'    return varchar2',
'is',
'begin',
'    return case when     p_true_or_false then ''Yes''',
'                when not p_true_or_false then ''No''',
'                else null',
'           end;',
'end yes_or_no;',
'',
'procedure tr_td (',
'  l_result in out nocopy varchar2,',
'  l_label  in            varchar2,',
'  l_text   in            varchar2)',
'is',
'  l_text_print varchar2(32767);',
'begin ',
'    if l_label is not null and l_text is not null then',
'        l_text_print := l_text;',
'        if l_text = ''Y'' or l_text= ''N'' then',
'            l_text_print := yes_or_no(l_text = ''Y'');',
'        end if;',
'        concat(l_result, ''<li class="dm-Instructions-listItem"><span class="dm-Instructions-label">'' || l_label || ''</span><span class="dm-Instructions-value">'' || l_text_print || ''</span></li>'');',
'    end if;',
'end tr_td;',
'',
'',
'procedure append_item (',
'    p_result in out nocopy varchar2,',
'    p_text   in            varchar2,',
'    p_prefix in            varchar2 )',
'is',
'begin',
'    if p_text is not null then',
'        concat( p_result, ''<div>'' || p_prefix || '' <strong>'' || p_text || ''</strong></div>''); ',
'    end if;',
'end append_item;',
'',
'procedure write_section_header (',
'  l_result       in out nocopy varchar2,',
'  l_header_title in            varchar2 )',
'is',
'begin',
'  concat(l_result, ''<table><tr><th colspan="2">'' || l_header_title || ''</th></tr>'');',
'end write_section_header;',
'',
'function get_grid_options (',
'    p_table_name in varchar2,',
'    p_id_column  in varchar2,',
'    p_id_value   in number )',
'    return varchar2',
'is',
'    l_result                  varchar2( 32767 );',
'    l_new_grid                varchar(3);',
'    l_new_grid_row            varchar(3);',
'    l_new_grid_column         varchar(3);',
'    l_grid_column             number;',
'    l_grid_column_span        number;',
'    l_grid_column_attributes  varchar(255);',
'    l_grid_column_css_classes varchar(255);',
'begin',
'    execute immediate',
'        ''select new_grid, new_grid_column, grid_column, grid_column_span, grid_column_attributes, grid_column_css_classes from '' || p_table_name || '' where '' || p_id_column || ''= :id''',
'       into l_new_grid, l_new_grid_column, l_grid_column, l_grid_column_span, l_grid_column_attributes, l_grid_column_css_classes',
'      using in p_id_value;',
'',
'    concat(l_result, ''<ul class="dm-Instructions-list">'');',
'    tr_td(l_result, ''New Grid'', yes_or_no(l_new_grid = ''Yes''));',
'    tr_td(l_result, ''New Grid Row'', yes_or_no(l_new_grid_row = ''Yes''));',
'    tr_td(l_result, ''New Grid Column'', yes_or_no(l_new_grid_column = ''Yes''));',
'    if l_grid_column is null then',
'      tr_td(l_result, ''Grid Column'', ''Automatic'');',
'    else',
'      tr_td(l_result, ''Grid Column'', l_grid_column);',
'    end if; ',
'    if l_grid_column_span is null then',
'      tr_td(l_result, ''Grid Column Span'', ''Automatic'');',
'    else',
'      tr_td(l_result, ''Grid Column Span'', l_grid_column_span);',
'    end if; ',
'    tr_td(l_result, ''Column Attributes'', l_grid_column_attributes);',
'    tr_td(l_result, ''Column CSS Classes'', l_grid_column_css_classes);',
'    return l_result || ''</ul>'';',
'end get_grid_options;',
'',
'',
'function get_template_option_descr (',
'    p_template_id      in number,',
'    p_template_type    in varchar2,',
'    p_template_options in varchar2 )',
'    return varchar2',
'is',
'    l_options            wwv_flow_global.vc_arr2;',
'    l_result             varchar2( 32767 ) := ''<ul class="dm-Instructions-list">'';',
'    l_has_result         boolean := false;',
'    l_label              varchar2( 32767 ) := null;',
'    l_text               varchar2( 32767 ) := null;',
'    l_group_display_name apex_appl_template_opt_groups.display_name%type;',
'    l_display_name       apex_appl_template_options.display_name%type;',
'    l_is_advanced        apex_appl_template_opt_groups.is_advanced%type;',
'begin',
'    l_options := wwv_flow_utilities.string_to_table2( p_template_options );',
'',
'    for i in 1 .. l_options.count loop',
'        if l_options(i) = ''#DEFAULT#'' then',
'            l_label:= ''Use Default'';',
'            l_text := ''<strong>Yes</strong>'';',
'        else',
'            /* if the first entry isn''t the #DEFAULT# placeholder, we still want to show that default has to be set to No */',
'            if i = 1 then',
'                tr_td(l_result, ''Use Default'', ''<strong>No</strong>'');',
'            end if;',
'            begin',
'               l_text := l_options( i );',
'               select g.display_name as group_display_name,',
'                      o.display_name,',
'                      g.is_advanced',
'                 into l_group_display_name,',
'                      l_display_name,',
'                      l_is_advanced',
'                 from apex_appl_template_options o,',
'                      apex_appl_template_opt_groups g',
'                where o.application_id = apex_application.g_flow_id',
'                  and o.theme_number   = 42',
'                  and (  ( o.virtual_template_type = p_template_type and o.virtual_template_id = p_template_id )',
'                      or ( o.virtual_template_id is null and o.template_types = p_template_type )',
'                      )',
'                  and o.css_classes    = l_options( i )',
'                  and g.template_opt_group_id (+) = o.group_id;',
'                if l_group_display_name is not null then',
'                    if l_is_advanced = ''Y'' then',
'                        l_label := ''Advanced '' || l_group_display_name;',
'                    else',
'                        l_label := l_group_display_name;',
'                    end if;',
'                    l_text := l_display_name;',
'                else',
'                    l_label := l_display_name;',
'                    l_text := ''Yes'';',
'                end if;',
'            exception when no_data_found then',
'                l_text := ''Unknown Option '' || l_options( i );',
'            end;',
'        end if;',
'        --concat(l_result, l_label);',
'        --concat(l_result, l_text);',
'        tr_td(l_result, l_label, l_text);',
'        l_label := null;',
'        l_text := null;',
'    end loop;',
'    return l_result || ''</ul>'';',
'end get_template_option_descr;',
'',
'function get_region_items_descr (',
'    p_region_id         in number,',
'    p_show_grid_options in boolean )',
'    return varchar2',
'is',
'    l_result    varchar2( 32767 ) := ''<div class="dm-Instructions-title">Region Items<div>'';',
'    l_has_items boolean := false;',
'begin',
'    for l_item in ( select item_id,',
'                           item_name,',
'                           display_as,',
'                           item_template_options,',
'                           item_source_type,',
'                           item_default_type,',
'                           item_data_type',
'                      from apex_application_page_items',
'                     where region_id = p_region_id',
'                     order by display_sequence )',
'    loop',
'        l_has_items := true;',
'        l_result := l_result || ',
'             ''<div><span class="how-to-page-item-title">'' || l_item.display_as || '' <strong>'' ||  l_item.item_name || ''</strong></span><div>Template Options'' || ',
'             get_template_option_descr(',
'                 p_template_options => l_item.item_template_options,',
'                 p_template_type    => ''THEME'',',
'                 p_template_id      => 1',
'             ) || ''</div></div>'';',
'      if p_show_grid_options then',
'          l_result := l_result || ''Grid Options: '' ||',
'                      get_grid_options(',
'                          p_table_name => ''apex_application_page_items'',',
'                          p_id_column  => ''item_id'',',
'                          p_id_value   => l_item.item_id);',
'      end if;',
'      --concat(l_result, ''</div>'');',
'      concat(l_result, l_item.item_source_type || '' - '' || l_item.item_default_type || '' - '' || l_item.item_data_type);',
'      end loop;',
'    concat(l_result, ''</div></div>'');',
'    if not l_has_items then',
'       l_result := null;',
'    end if;',
'    return l_result;',
'end get_region_items_descr;',
'',
'function get_region_buttons_descr (',
'    p_region_id      in number )',
'    return varchar2',
'is',
'    l_result      varchar2( 32767 ) := ''<h4 class="dm-Instructions-subTitle">Region Buttons</h4>'';',
'    l_has_buttons boolean := false;',
'begin',
'    for l_button in ( select button_name,',
'                             button_template,',
'                             display_position,',
'                             button_css_classes,',
'                             icon_css_classes,',
'                             button_template_options,',
'                             button_template_id',
'                        from apex_application_page_buttons',
'                       where region_id = p_region_id',
'                       order by button_sequence )',
'    loop',
'       l_has_buttons := true;',
'       l_result := l_result || ',
'            ''<div class="dm-Instructions-buttonRow"><ul class="dm-Instructions-list"><li class="dm-Instructions-listItem"><span class="dm-Instructions-label">'' || l_button.button_template || ''</span><span class="dm-Instructions-value">'' ||  l_button.'
||'button_name || ''</span></li></ul></div>'' || ',
'            get_template_option_descr(',
'                p_template_options => l_button.button_template_options,',
'                p_template_type    => ''BUTTON'',',
'                p_template_id      => l_button.button_template_id );',
'        concat(l_result, ''<ul class="dm-Instructions-list">'');',
'        tr_td(l_result, ''Button Template'', l_button.button_template);',
'        tr_td(l_result, ''Button Position'', l_button.display_position);',
'        concat(l_result, ''</ul>'');',
'        concat(l_result, ''</div>'');',
'    end loop;',
'    concat(l_result, ''</div></div>'');',
'',
'    if not l_has_buttons then',
'       l_result := null;',
'    end if;',
'    return l_result;',
'end get_region_buttons_descr;',
'',
'function get_plugin_attributes (',
'    p_plugin_name in varchar2,',
'    p_plugin_type in varchar2,',
'    p_values      in apex_application_global.vc_arr2 )',
'    return varchar2',
'is',
'    c_application_id constant number := case when p_plugin_name like ''NATIVE_%'' then 4411 else apex_application.g_flow_id end;',
'',
'    l_result         varchar2( 32767 ) := ''<ul class="dm-Instructions-list">'';',
'    l_display_value  varchar2( 255 );',
'    l_has_attributes boolean := false;',
'begin',
'    for l_attribute in ( select plugin_attribute_id,',
'                                prompt,',
'                                attribute_sequence as attribute_no,',
'                                attribute_type,',
'                                default_value',
'                           from apex_appl_plugins p,',
'                                apex_appl_plugin_attributes a',
'                          where p.application_id  = c_application_id',
'                            and p.name            = substr( p_plugin_name, 8 )',
'                            and p.plugin_type     = p_plugin_type',
'                            and a.plugin_id       = p.plugin_id',
'                            and a.attribute_scope = ''Component''',
'                          order by a.display_sequence )',
'    loop',
'        if not p_values.exists ( l_attribute.attribute_no ) then',
'            continue;',
'        end if;',
'',
'        l_display_value := p_values( l_attribute.attribute_no );',
'',
'        -- No need to show the attribute if it''s the default',
'        if l_display_value = l_attribute.default_value then',
'            continue;',
'        end if;',
'',
'        l_has_attributes := true;',
'        if l_attribute.attribute_type = ''Select List'' then',
'            begin',
'                select display_value',
'                  into l_display_value',
'                  from apex_appl_plugin_attr_values',
'                 where plugin_attribute_id = l_attribute.plugin_attribute_id',
'                   and return_value        = l_display_value;',
'            exception when no_data_found then',
'                l_display_value := l_display_value || ''***'';',
'            end;',
'        end if;',
'        tr_td(l_result, apex_escape.html( l_attribute.prompt ), apex_escape.html( l_display_value ));',
'        --concat( l_result, ''<li>'' || apex_escape.html( l_attribute.prompt ) || '':'' || apex_escape.html( l_display_value ) || ''</li>'' );',
'    end loop;',
'    if not l_has_attributes then',
'        l_result := null;',
'    else',
'        concat( l_result, ''</ul>'' );',
'    end if;',
'    return l_result;',
'end get_plugin_attributes;',
'',
'procedure show_region_descr (',
'    p_region_id               in number,',
'    p_show_template_options   in boolean,',
'    p_show_grid               in boolean,',
'    p_show_sub_regions        in boolean,',
'    p_show_title              in boolean,',
'    p_show_select_region_type in boolean',
')',
'is',
'    l_has_subregions boolean := false;',
'    l_values         apex_application_global.vc_arr2;',
'begin',
'    for l_region in ( select region_name,',
'                             source_type,',
'                             source_type_plugin_name,',
'                             template,',
'                             template_id,',
'                             region_template_options,',
'                             list_template_override,',
'                             list_template_override_id,',
'                             breadcrumb_template,',
'                             breadcrumb_template_id,',
'                             component_template_options,',
'                             report_template,',
'                             report_template_id,',
'                             condition_type',
'                        from apex_application_page_regions',
'                       where region_id = p_region_id )',
'    loop',
'        if l_region.condition_type = ''Never'' then',
'            continue;',
'        end if;',
'',
'        -- get all plug-in attributes',
'        l_values.delete;',
'        for i in ( select attribute_01,',
'                                      attribute_02,',
'                                      attribute_03,',
'                                      attribute_04,',
'                                      attribute_05,',
'                                      attribute_06,',
'                                      attribute_07,',
'                                      attribute_08,',
'                                      attribute_09,',
'                                      attribute_10,',
'                                      attribute_11,',
'                                      attribute_12,',
'                                      attribute_13,',
'                                      attribute_14,',
'                                      attribute_15,',
'                                      attribute_16,',
'                                      attribute_17,',
'                                      attribute_18,',
'                                      attribute_19,',
'                                      attribute_20,',
'                                      attribute_21,',
'                                      attribute_22,',
'                                      attribute_23,',
'                                      attribute_24,',
'                                      attribute_25',
'               from apex_application_page_regions',
'              where region_id = p_region_id )',
'          loop',
'              l_values(1) := i.attribute_01;',
'              l_values(2) := i.attribute_02;',
'              l_values(3) := i.attribute_03;',
'              l_values(4) := i.attribute_04;',
'              l_values(5) := i.attribute_05;',
'              l_values(6) := i.attribute_06;',
'              l_values(7) := i.attribute_07;',
'              l_values(8) := i.attribute_08;',
'              l_values(9) := i.attribute_09;',
'              l_values(10) := i.attribute_10;',
'              l_values(11) := i.attribute_11;',
'              l_values(12) := i.attribute_12;',
'              l_values(13) := i.attribute_13;',
'              l_values(14) := i.attribute_14;',
'              l_values(15) := i.attribute_15;',
'              l_values(16) := i.attribute_16;',
'              l_values(17) := i.attribute_17;',
'              l_values(18) := i.attribute_18;',
'              l_values(19) := i.attribute_19;',
'              l_values(20) := i.attribute_20;',
'              l_values(21) := i.attribute_21;',
'              l_values(22) := i.attribute_22;',
'              l_values(23) := i.attribute_23;',
'              l_values(24) := i.attribute_24;',
'              l_values(25) := i.attribute_25;',
'          end loop;',
'        ',
'        if p_show_title then',
'            sys.htp.p(''<h3>'' || l_region.region_name || ''</h3>'' );',
'        end if;',
'        sys.htp.p( ''<div class="dm-Instructions-section">'' );',
'        if p_show_template_options then',
'            if p_show_select_region_type then',
'                sys.htp.p( ''<div>Select <b>'' || l_region.source_type || ''</b> for Region Type.</div>'' );',
'            end if;',
'            --sys.htp.p( ''<div>Select <b>'' || l_region.template || ''</b> as Region Template.</div>'' );',
'            sys.htp.p(',
'                ''<h3 class="dm-Instructions-title">Region Template Options</h3> '' ||',
'                get_template_option_descr(',
'                    p_template_id      => l_region.template_id,',
'                    p_template_type    => ''REGION'',',
'                    p_template_options => l_region.region_template_options )',
'                );',
'        end if;',
'        if l_region.source_type_plugin_name = ''NATIVE_LIST'' then',
'            --sys.htp.p( ''<div>Use the list template  <b>'' || l_region.list_template_override || ''</b></div>'' );',
'            sys.htp.p(',
'                ''<h3 class="dm-Instructions-title">List Template Options</h3> '' ||',
'                get_template_option_descr(',
'                    p_template_id      => l_region.list_template_override_id,',
'                    p_template_type    => ''LIST'',',
'                    p_template_options => l_region.component_template_options )',
'                );',
'        elsif l_region.source_type_plugin_name = ''NATIVE_BREADCRUMB'' then',
'            --sys.htp.p( ''<div>Breadcrumb Template: '' || l_region.breadcrumb_template || ''</div>'' );',
'            sys.htp.p(',
'                ''<h3 class="dm-Instructions-title">Breadcrumb Template Options</h3> '' ||',
'                get_template_option_descr(',
'                    p_template_id      => l_region.breadcrumb_template_id,',
'                    p_template_type    => ''BREADCRUMB'',',
'                    p_template_options => l_region.component_template_options )',
'                    );',
'        elsif l_region.source_type_plugin_name = ''NATIVE_SQL_REPORT'' then',
'           -- sys.htp.p( ''<div>Report: '' || l_region.report_template || ''</div>'' );',
'            sys.htp.p(',
'                ''<h3 class="dm-Instructions-title">Report Template Options</h3> '' ||',
'                get_template_option_descr(',
'                    p_template_id      => l_region.report_template_id,',
'                    p_template_type    => ''REPORT'',',
'                    p_template_options => l_region.component_template_options )',
'                    );',
'        elsif l_region.source_type_plugin_name = ''NATIVE_IR'' then',
'            --sys.htp.p( ''<div>Interactive Report: '' || l_region.report_template || ''</div>'' );',
'            null;',
'        elsif l_region.source_type_plugin_name = ''NATIVE_CSS_CALENDAR'' then',
'            sys.htp.p(',
'                ''<div>'' ||',
'                get_plugin_attributes(',
'                    p_plugin_name => l_region.source_type_plugin_name,',
'                    p_plugin_type => ''Region Type'',',
'                    p_values      => l_values ) ||',
'                ''</div>'' );',
'        end if;',
'        sys.htp.p( ''</div>'' );',
'        if p_show_grid then',
'            sys.htp.p(',
'                ''<div class="dm-Instructions-section"><h3 class="dm-Instructions-title">Grid Options: '' ||',
'                get_grid_options(',
'                    p_table_name => ''apex_application_page_regions'',',
'                    p_id_column  => ''region_id'',',
'                    p_id_value   => p_region_id ) ||',
'                ''</h3></div>'');',
'        end if;',
'        -- sys.htp.p( ''<div class="dm-Instructions-section">'' );',
'        -- sys.htp.p(get_region_items_descr( p_region_id, p_show_grid ));',
'        -- sys.htp.p( ''</div>'' );',
'        -- sys.htp.p( ''<div class="dm-Instructions-section">'' );',
'        -- sys.htp.p(get_region_buttons_descr( p_region_id ));',
'        -- sys.htp.p( ''</div>'' );',
'        if p_show_sub_regions then',
'            for l_sub_region in ( select region_id',
'                                    from apex_application_page_regions',
'                                   where parent_region_id = p_region_id',
'                                   order by display_sequence )',
'            loop',
'                  if not l_has_subregions then',
'                      sys.htp.p( ''<div class="dm-Instructions-section dm-Instructions-section--sub">'' );',
'                      l_has_subregions := true;',
'                  end if;',
'                  show_region_descr(',
'                      p_region_id               => l_sub_region.region_id,',
'                      p_show_template_options   => p_show_template_options,',
'                      p_show_grid               => p_show_grid,',
'                      p_show_sub_regions        => p_show_sub_regions,',
'                      p_show_title              => p_show_title,',
'                      p_show_select_region_type => p_show_select_region_type );',
'            end loop;',
'            if l_has_subregions = true then',
'                sys.htp.p( ''</div>'' );',
'            end if;',
'        end if;',
'    end loop;',
'',
'end show_region_descr;',
'',
'',
'function render (',
'    p_region              in apex_plugin.t_region,',
'    p_plugin              in apex_plugin.t_plugin,',
'    p_is_printer_friendly in boolean )',
'    return apex_plugin.t_region_render_result',
'is',
'begin',
'    for l_region in ( select r2.region_id',
'                        from apex_application_page_regions r1,',
'                             apex_application_page_regions r2',
'                       where r1.region_id        = p_region.id',
'                         and r2.parent_region_id = r1.parent_region_id',
'                         and r2.region_id       <> r1.region_id )',
'    loop',
'        show_region_descr(',
'            p_region_id               => l_region.region_id,',
'            p_show_template_options   => ( p_region.attribute_01 = ''Y'' ),',
'            p_show_grid               => ( p_region.attribute_02 = ''Y'' ),',
'            p_show_sub_regions        => ( p_region.attribute_03 = ''Y'' ),',
'            p_show_title              => ( p_region.attribute_04 = ''Y'' ),',
'            p_show_select_region_type => ( p_region.attribute_05 = ''Y'' )',
'            );',
'    end loop;',
'',
'    return null;',
'end render;'))
,p_api_version=>1
,p_render_function=>'render'
,p_substitute_attributes=>true
,p_reference_id=>1659439287482598456
,p_subscribe_plugin_settings=>true
,p_version_identifier=>'1.0'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(39662723070384770)
,p_plugin_id=>wwv_flow_api.id(39662396918384769)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_prompt=>'Show Region Template Options'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'Y'
,p_supported_ui_types=>'DESKTOP:JQM_SMARTPHONE'
,p_is_translatable=>false
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(39663146268384770)
,p_plugin_id=>wwv_flow_api.id(39662396918384769)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_prompt=>'Show Grid Values'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'N'
,p_is_translatable=>false
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(39663559345384770)
,p_plugin_id=>wwv_flow_api.id(39662396918384769)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_prompt=>'Show Sub Regions'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'Y'
,p_supported_ui_types=>'DESKTOP:JQM_SMARTPHONE'
,p_is_translatable=>false
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(39663891909384770)
,p_plugin_id=>wwv_flow_api.id(39662396918384769)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_prompt=>'Show Region Title'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'Y'
,p_is_translatable=>false
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(39664368543384770)
,p_plugin_id=>wwv_flow_api.id(39662396918384769)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_prompt=>'Show Select Region Type'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'N'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(39662723070384770)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'Y'
);
wwv_flow_api.component_end;
end;
/
