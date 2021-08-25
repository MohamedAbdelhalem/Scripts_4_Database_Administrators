select Operation, Context, [Transaction ID], [Transaction Name], [Slot ID], [Page ID], [Begin Time], [End Time], Description, [RowLog Contents 0] 
from sys.fn_dblog(null,null)
where [Transaction ID] in (
select [Transaction ID]
from (
select count(*) c, [Transaction ID],[Transaction Name]
from sys.fn_dblog(null,null)
where [Transaction Name] = 'splitpage'
group by [Transaction ID],[Transaction Name])a)
and AllocUnitId in (select allocation_unit_id 
					from sys.system_internals_allocation_units iau inner join sys.partitions p
					on 
					(iau.type in (1,3) and iau.container_id = p.hobt_id) 
					or 
					(iau.type in (2) and iau.container_id = p.[partition_id]) 
					inner join sys.indexes i
					on i.object_id = p.object_id
					inner join sys.tables t
					on t.object_id = p.object_id
					where t.type = 'U'
					)
