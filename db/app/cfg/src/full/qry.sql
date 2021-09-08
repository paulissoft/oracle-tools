with src as (
  select  line
  ,       name
  ,       type
  ,       usage
  ,       usage_id
  ,       usage_context_id
  from    user_identifiers 
  where   object_name = 'UT_CODE_CHECK_PKG'
  and     object_type = 'PACKAGE BODY'
  ), identifiers as (
  select  src.*
  ,       rtrim(replace(sys_connect_by_path(case when usage = 'DEFINITION' then name || '.' end, '|'), '|'), '.') as name_scope
  ,       rtrim(replace(sys_connect_by_path(case when usage = 'DEFINITION' then usage_id || '.' end, '|'), '|'), '.') as usage_id_scope
  from    src
  start with
          usage_id = 1
  connect by  
          usage_context_id = prior usage_id
)
, declarations as (
  select  *
  from    identifiers
  where   usage = 'DECLARATION'
)
, non_declarations as (
  select  i.*
  ,       di.usage_id_scope as declaration_usage_id_scope
  ,       row_number() over (partition by i.name, i.type, i.usage_id order by length(di.usage_id_scope) desc) as seq -- longest usage_id_scope first, i.e. prefer innermost declaration
  from    identifiers i
          left outer join declarations di
          on di.name = i.name and di.type = i.type and i.usage_id_scope like di.usage_id_scope || '%'
  where   i.usage != 'DECLARATION'        
)
, unused_identifiers as (
  select  d.*
  from    declarations d
          left outer join non_declarations nd
          -- skip assignments to a variable/constant but not for instance to a parameter
          on not(nd.usage = 'ASSIGNMENT' and nd.type in ('VARIABLE', 'CONSTANT')) and nd.name = d.name and nd.type = d.type and nd.declaration_usage_id_scope = d.usage_id_scope
  where   d.type not in ('PACKAGE BODY', 'FUNCTION', 'PROCEDURE')
  and     nd.name is null
)
select  *
from    unused_identifiers
order by
        line
