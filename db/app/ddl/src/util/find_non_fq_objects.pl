use strict;

# Usage: perl find_non_fq_objects.pl *.take

# Take the list between ( and ) from pom.xml

my $line_no = 0;
my $file = '';

sub match($);

while (<>) {
    if ($ARGV ne $file) {
        $line_no = 0;
    }

    $file = $ARGV;
    $line_no++;

    my $object = match('oracle_tools');
    
    printf("[%s#%04d] %s", $file, $line_no, $_)
        if ( defined($object) && !m/("ORACLE_TOOLS"."|constructor function |end |--.*|dbug.print\(.*|'|`|"|\/\*.*)$object/i );
}

sub match($) {
    my ($look_behind) = @_;
    
    if (m/
(?<!$look_behind\.)\b
( ddl_crud_api
| f_generate_ddl
| generate_ddl_configurations
| generate_ddl_sessions
| generate_ddl_session_batches
| generate_ddl_session_schema_objects
| generate_ddls
| generate_ddl_statements
| generate_ddl_statement_chunks
| pkg_ddl_error
| pkg_ddl_util
| pkg_replicate_util
| pkg_schema_object_filter
| pkg_str_util
| p_generate_ddl
| schema_objects
| schema_objects_api
| schema_object_filters
| schema_object_filter_results
| t_argument_object
| t_argument_object_tab
| t_cluster_object
| t_comment_ddl
| t_comment_object
| t_constraint_ddl
| t_constraint_object
| t_ddl
| t_ddl_sequence
| t_ddl_tab
| t_dependent_or_granted_object
| t_display_ddl_sql_rec
| t_display_ddl_sql_tab
| t_function_object
| t_index_ddl
| t_index_object
| t_java_source_object
| t_materialized_view_ddl
| t_materialized_view_log_object
| t_materialized_view_object
| t_member_object
| t_named_object
| t_object_grant_ddl
| t_object_grant_object
| t_package_body_object
| t_package_spec_object
| t_procedure_object
| t_procobj_ddl
| t_procobj_object
| t_refresh_group_ddl
| t_refresh_group_object
| t_ref_constraint_object
| t_schema_ddl
| t_schema_ddl_tab
| t_schema_object
| t_schema_object_filter
| t_schema_object_tab
| t_sequence_ddl
| t_sequence_object
| t_synonym_ddl
| t_synonym_object
| t_table_column_ddl
| t_table_column_object
| t_table_ddl
| t_table_object
| t_text_tab
| t_trigger_ddl
| t_trigger_object
| t_type_attribute_ddl
| t_type_attribute_object
| t_type_body_object
| t_type_method_ddl
| t_type_method_object
| t_type_spec_ddl
| t_type_spec_object
| t_view_object
| v_all_schema_objects
| v_dependent_or_granted_object_types
| v_display_ddl_sql
| v_my_generate_ddl_sessions
| v_my_generate_ddl_session_batches
| v_my_generate_ddl_session_batches_no_schema_export
| v_my_include_objects
| v_my_named_schema_objects
| v_my_schema_ddls
| v_my_schema_objects
| v_my_schema_objects_no_ddl_yet
| v_my_schema_object_filter
| v_my_schema_object_info
)\b
/ix) { return $1; };
    return undef;
}
