
select 
o.name, sum(COLUMNPROPERTY(o.object_id, c.column_name, 'IsDeterministic')),
isnull(case when sum(COLUMNPROPERTY(o.object_id, c.column_name, 'IsDeterministic')) > 0 then 'does not eligable to create indexed view' else 'okay' end,'not a view') [status]
from INFORMATION_SCHEMA.COLUMNS c inner join sys.objects o
on o.name = c.table_name
where o.name = 'view name'
group by o.object_id, o.name
order by status
