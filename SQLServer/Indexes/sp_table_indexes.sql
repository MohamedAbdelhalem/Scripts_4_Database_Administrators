create procedure sp_table_indexes
(@table_name varchar(500))
as
begin

declare @object_id bigint, @index_id bigint
declare @indexes table (id int identity(1,1), table_name varchar(500), index_id int, index_name varchar(1000), index_type varchar(100), synatx varchar(max))
declare x cursor fast_forward
for
--select t.object_id, '['+schema_name(t.schema_id)+'].['+t.name+']' table_name,t.type_desc, i.name index_name, i.index_id, i.type_desc, is_primary_key
select t.object_id, i.index_id
from sys.tables t left outer join sys.indexes i
on t.object_id = i.object_id
--where is_primary_key = 0
where i.type_desc != 'HEAP'
and i.object_id = object_id(@table_name)
order by object_id

open x
fetch next from x into @object_id, @index_id
while @@FETCH_STATUS = 0
begin

insert into @indexes (table_name, index_id, index_name, index_type, synatx)
exec [dbo].[sp_index_detail] @P_object_id = @object_id,  @p_index_id = @index_id
fetch next from x into @object_id, @index_id
end
close x
deallocate x

select * from @indexes
end

