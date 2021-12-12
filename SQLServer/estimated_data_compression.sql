
--USE [AdventureWorks2014]
--ALTER INDEX [AK_Address_rowguid] ON [Person].[Address] REBUILD PARTITION = ALL 
--WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, DATA_COMPRESSION = ROW)

CREATE procedure [dbo].[estimated_data_compression]
(@P_object_id int = 0, @compress_type varchar(5) = 'Page')
as
begin

declare  @object_id int, @schema_name varchar(300), @object_name  varchar(300)
declare @estimated_data_compression_savings table (
object_id int, object_name varchar(700), object_type varchar(50), 
index_id int, index_name varchar(500), type_desc varchar(100), is_unique int, is_disabled int, is_primary_key int, is_unique_constraint int, partition_number int, rows int, 
current_compression varchar(20), requested_compression varchar(20), compression_pct float)

declare @estimated_data_compression_savings_temp table (object_name varchar(200), schema_name varchar(200), index_id int, partition_number int, 
size_with_current_compression_setting_KB int,
size_with_requested_compression_setting_KB int,
simple_size_with_current_compression_setting_KB int,
simple_size_with_requested_compression_setting_KB int)

set nocount on
if @P_object_id > 0
begin
declare comp_objects cursor fast_forward
for
select distinct object_id, substring(object_name,1, charindex('.',object_name)-1) schema_name,substring(object_name,charindex('.',object_name)+1,len(object_name)) object_name
from (
select i.object_id, isnull(schema_name(t.schema_id)+'.'+t.name,schema_name(v.schema_id)+'.'+v.name) [object_name]
from sys.indexes i left outer join sys.tables t
on i.object_id = t.object_id
left outer join sys.views v
on i.object_id = v.object_id
where (t.type = 'U' or v.type = 'V'))a
where object_id = @P_object_id
order by schema_name, object_name
end
else
begin
declare comp_objects cursor fast_forward
for
select distinct object_id, substring(object_name,1, charindex('.',object_name)-1) schema_name,substring(object_name,charindex('.',object_name)+1,len(object_name)) object_name
from (
select i.object_id, isnull(schema_name(t.schema_id)+'.'+t.name,schema_name(v.schema_id)+'.'+v.name) [object_name]
from sys.indexes i left outer join sys.tables t
on i.object_id = t.object_id
left outer join sys.views v
on i.object_id = v.object_id
where (t.type = 'U' or v.type = 'V'))a
order by schema_name, object_name
end

open comp_objects
fetch next from comp_objects into @object_id, @schema_name, @object_name
while @@FETCH_STATUS = 0
begin

insert into @estimated_data_compression_savings_temp
exec [sys].[sp_estimate_data_compression_savings]
@schema_name =@schema_name,
@object_name = @object_name,
@index_id = NULL,
@partition_number = NULL,
@data_compression = @compress_type

insert into @estimated_data_compression_savings
select details.*, 
master.dbo.numberSize(size_with_current_compression_setting_KB,'kb'),
master.dbo.numberSize(size_with_requested_compression_setting_KB,'kb'),
case size_with_requested_compression_setting_KB when 0 then 0 else round(Abs((cast(size_with_requested_compression_setting_KB as float) / cast(size_with_current_compression_setting_KB as float) * 100) - 100),2) end
from (
select index_id, grouping(index_id)g,
sum(size_with_current_compression_setting_KB) size_with_current_compression_setting_KB,
sum(size_with_requested_compression_setting_KB) size_with_requested_compression_setting_KB
from @estimated_data_compression_savings_temp
group by index_id with rollup) est left outer join (
select * from (
SELECT i.object_id, isnull('['+schema_name(t.schema_id)+'].['+t.name+']','['+schema_name(v.schema_id)+'].['+v.name+']') [object_name], isnull(t.type_desc,v.type_desc) object_type, 
i.index_id, i.name index_name, i.type_desc, i.is_unique, i.is_disabled, i.is_primary_key, i.is_unique_constraint, p.partition_number, p.rows
from sys.partitions p left outer join sys.indexes i 
on p.object_id = i.object_id
and p.index_id = i.index_id
left outer join sys.tables t
on i.object_id = t.object_id
left outer join sys.views v
on i.object_id = v.object_id
where (t.type = 'U' or v.type = 'V'))a
where object_id = @object_id) details
on est.index_id = details.index_id

delete @estimated_data_compression_savings_temp

fetch next from comp_objects into @object_id, @schema_name, @object_name
end
close comp_objects 
deallocate comp_objects 

select * 
from @estimated_data_compression_savings

set nocount off

end
