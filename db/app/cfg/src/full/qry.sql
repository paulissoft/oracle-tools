with src1 as (
  select  object_name
  ,       object_type
  ,       name
  ,       type
  ,       usage
  ,       usage_context_id
  ,       usage_id
  ,       line
  ,       col
  from    user_identifiers 
  where   object_name = 'UT_CODE_CHECK_PKG'
  and     object_type in ('PACKAGE', 'PACKAGE BODY')
)
, src2 as (
  select  src1.*
  ,       rtrim(replace(sys_connect_by_path(case when usage = 'DEFINITION' then usage_id || '.' end, '|'), '|'), '.') as usage_id_scope
  from    src1
  start with
          usage_id = 1
  connect by  
          usage_context_id = prior usage_id
)
, src3 as (
  select  object_name
  ,       object_type
  ,       name
  ,       type
  ,       usage
  ,       usage_context_id
  ,       usage_id
  ,       line
  ,       col
  ,       usage_id_scope
  ,       row_number() over (partition by object_name, object_type, name, type, usage_id order by length(usage_id_scope) desc nulls last) as seq -- longest usage_id_scope first
  from    src2
), identifiers as (
  select  object_name
  ,       object_type
  ,       name
  ,       type
  ,       usage
  ,       usage_context_id
  ,       usage_id
  ,       line
  ,       col
  ,       usage_id_scope
  from    src3
  where   seq = 1
)
, declarations as (
  select  *
  from    identifiers
  where   usage = 'DECLARATION'
)
, non_declarations as (
  select  i.*
  ,       di.usage_id_scope as declaration_usage_id_scope
  from    identifiers i
          left outer join declarations di
          on di.object_name = i.object_name and
             di.object_type = i.object_type and
             di.name = i.name and
             di.type = i.type and
             i.usage_id_scope like di.usage_id_scope || '%'
  where   i.usage != 'DECLARATION'        
)
, unused_identifiers as (
  select  d.*
  ,       1 as message_number
  ,       'is declared but never used' as text
  from    declarations d
          left outer join non_declarations nd
          -- skip assignments to a variable/constant but not for instance to a parameter
          on not(nd.usage = 'ASSIGNMENT' and nd.type in ('VARIABLE', 'CONSTANT')) and
             nd.object_name = d.object_name and
             nd.object_type = d.object_type and
             nd.name = d.name and
             nd.type = d.type and
             nd.declaration_usage_id_scope = d.usage_id_scope
  where   d.object_type not in ('PACKAGE', 'TYPE')
  and     d.type not in ('FUNCTION', 'PROCEDURE') -- skip unused functions/procedures
  and     nd.name is null
)
, assignments as (
  select  nd.*
  ,       first_value(usage_id) over (partition by object_name, object_type, name, type, usage, usage_context_id order by line desc) last_usage_id
  from    non_declarations nd
  where   nd.usage = 'ASSIGNMENT'
)
, references as (
  select  nd.*
  ,       first_value(usage_id) over (partition by object_name, object_type, name, type, usage, usage_context_id order by line asc) first_usage_id
  from    non_declarations nd
  where   nd.usage = 'REFERENCE'
)
, unset_identifiers as (
  -- Variables that are referenced but never assigned a value (before that reference)
  select  d.*
  ,       2 as message_number
  ,       'is referenced but never assigned a value (before that reference)' as text
  from    declarations d
          inner join references r
          on r.object_name = d.object_name and
             r.object_type = d.object_type and
             r.name = d.name and
             r.type = d.type and
             r.declaration_usage_id_scope = d.usage_id_scope and
             r.usage_id = r.first_usage_id -- first reference
          left outer join assignments a
          on a.object_name = d.object_name and
             a.object_type = d.object_type and
             a.name = d.name and
             a.type = d.type and
             a.declaration_usage_id_scope = d.usage_id_scope and
             a.usage_id < r.usage_id -- the assignment is before the (first) reference
  where   d.type in ('CONSTANT', 'VARIABLE')
  and     d.object_type not in ('PACKAGE', 'TYPE')
  and     a.name is null -- there is nu such an assignment
)
, assigned_unused_identifiers as (
  select  d.*
  ,       3 as message_number
  ,       'is assigned a value but never used (after that assignment)' as text
  from    declarations d
          inner join assignments a
          on a.object_name = d.object_name and
             a.object_type = d.object_type and
             a.name = d.name and
             a.type = d.type and
             a.declaration_usage_id_scope = d.usage_id_scope and
             a.usage_id = a.last_usage_id and
             a.usage_context_id != d.usage_id -- last assignment (but not initialization)
          left outer join references r
          on r.object_name = d.object_name and
             r.object_type = d.object_type and
             r.name = d.name and
             r.type = d.type and
             r.declaration_usage_id_scope = d.usage_id_scope and
             r.usage_id > a.usage_id -- after last assignment
  where   d.type in ('CONSTANT', 'VARIABLE')
  and     d.object_type not in ('PACKAGE', 'TYPE')
  and     r.name is null -- there is none
)
, unset_output_parameters as (
  select  d.*
  ,       4 as message_number
  ,       '(' || replace(d.type, 'FORMAL ') || ') should be assigned a value' as text
  from    declarations d
          left outer join assignments a
          on a.object_name = d.object_name and
             a.object_type = d.object_type and
             a.name = d.name and
             a.type = d.type and
             a.declaration_usage_id_scope = d.usage_id_scope
  where   d.type in ('FORMAL IN OUT', 'FORMAL OUT')
  and     d.object_type not in ('PACKAGE', 'TYPE')
  and     a.name is null -- there is none
)
, function_output_parameters as (
  select  d.*
  ,       5 as message_number
  ,       '(' || replace(d.type, 'FORMAL ') || ') should not be used in a function' as text
  from    declarations d
          inner join identifiers i
          on i.object_name = d.object_name and
             i.object_type = d.object_type and
             i.usage_id = d.usage_context_id and
             i.type = 'FUNCTION'
  where   d.type in ('FORMAL IN OUT', 'FORMAL OUT')
)
, shadowing_identifiers as (
  select  distinct -- every time when an identifier shadows another it is listed (just once)
          d2.*
  ,       6 as message_number
  ,       'shadows another identifier of the same name' as text
  from    declarations d1
          inner join declarations d2
          on d2.object_name = d1.object_name and
             d2.object_type = d1.object_type and
             d2.name = d1.name and
             d2.usage_context_id = d1.usage_context_id and
             d2.usage_id > d1.usage_id
  where   d1.object_type not in ('PACKAGE', 'TYPE')
  and     d2.object_type not in ('PACKAGE', 'TYPE')
)
, no_global_public_variables as (
  select  d.*
  ,       7 as message_number
  ,       '(global public variable) should not be declared, use setters and getters instead' as text
  from    declarations d
  where   d.object_type = 'PACKAGE'
  and     d.type = 'VARIABLE'
)
, checks as (
  select  object_name
  ,       object_type
  ,       line
  ,       col
  ,       name
  ,       type
  ,       usage
  ,       usage_id
  ,       usage_context_id
  ,       message_number
  ,       text
  from    unused_identifiers
  union all
  select  object_name
  ,       object_type
  ,       line
  ,       col
  ,       name
  ,       type
  ,       usage
  ,       usage_id
  ,       usage_context_id
  ,       message_number
  ,       text
  from    unset_identifiers
  union all
  select  object_name
  ,       object_type
  ,       line
  ,       col
  ,       name
  ,       type
  ,       usage
  ,       usage_id
  ,       usage_context_id
  ,       message_number
  ,       text
  from    assigned_unused_identifiers
  union all
  select  object_name
  ,       object_type
  ,       line
  ,       col
  ,       name
  ,       type
  ,       usage
  ,       usage_id
  ,       usage_context_id
  ,       message_number
  ,       text
  from    unset_output_parameters 
  union all
  select  object_name
  ,       object_type
  ,       line
  ,       col
  ,       name
  ,       type
  ,       usage
  ,       usage_id
  ,       usage_context_id
  ,       message_number
  ,       text
  from    function_output_parameters 
  union all
  select  object_name
  ,       object_type
  ,       line
  ,       col
  ,       name
  ,       type
  ,       usage
  ,       usage_id
  ,       usage_context_id
  ,       message_number
  ,       text
  from    shadowing_identifiers
  union all
  select  object_name
  ,       object_type
  ,       line
  ,       col
  ,       name
  ,       type
  ,       usage
  ,       usage_id
  ,       usage_context_id
  ,       message_number
  ,       text
  from    no_global_public_variables
)
-- turn it into user_errors
select  object_name as name
,       object_type as type
,       to_number(null) as sequence
,       line
,       col as position
,       'PLC-' || to_char(c.message_number, 'FM00000') || ': ' || case when c.type like 'FORMAL %' then 'parameter' else lower(c.type) end || ' ' || c.name || ' ' || c.text as text
,       'CHECK' as attribute
,       message_number
from    checks c
where   message_number = 6
order by
        object_name
,       object_type
,       line
,       col
,       message_number
;
