select 
table_name, 
case when sum(isnull(COLUMNPROPERTY(object_id(table_name), column_name, 'IsDeterministic'),0)) > 0 then 'does not eligable to create indexed view' else 'okay' end [status]
from INFORMATION_SCHEMA.COLUMNS
group by table_name

