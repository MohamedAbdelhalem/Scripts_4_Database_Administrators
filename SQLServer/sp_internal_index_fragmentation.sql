CREATE Function [dbo].[internal_index_columns] (@object_id float, @index_id int)
returns @table table (table_name varchar(500), index_name varchar(500), is_clustered int, [count] smallint, index_keys_count smallint, included_columns_count smallint, 
has_unique smallint, mapping_keys_count smallint, [Columns] varchar(max))
as
begin

insert into @table
select table_name, name index_name, 
case when [count] - index_keys_count = 0 then 0 else 1 end is_clustered,  
[count], 
index_keys_count, included_columns_count, has_unique, mapping_keys_count, substring([columns],1,len([columns])-1) columns
from (
select table_name, [count], index_keys_count, included_columns_count, has_unique, mapping_keys_count, 
isnull([1]+',','')+isnull([2]+',','')+isnull([3]+',','')+isnull([4]+',','')+isnull([5]+',','')+isnull([6]+',','')+
isnull([7]+',','')+isnull([8]+',','')+isnull([9]+',','')+isnull([10]+',','')+isnull([11]+',','')+isnull([12]+',','')+
isnull([13]+',','')+isnull([14]+',','')+isnull([15]+',','')+isnull([16]+',','')+isnull([17]+',','')+isnull([18]+',','')+
isnull([19]+',','')+isnull([20]+',','')+isnull([21]+',','')+isnull([22]+',','')+isnull([23]+',','')+isnull([24]+',','') [columns]
from (
select row_number() over(order by is_included_column, index_id desc, key_ordinal, index_column_id) header_id,
table_name,
column_name,
count(*) over() [count],
sum(index_keys) over() index_keys_count,
sum(case is_included_column when 1 then 1 else 0 end) over() included_columns_count,
u.has_unique,
sum(mapping_keys) over() mapping_keys_count
from (
select object_id, table_name, index_id, index_name, index_column_id, column_id, 
column_name,  
case when is_included_column = 0 and index_id > 1 then 1 else 0 end index_keys,
key_ordinal, is_included_column, mapping_keys,
row_number() over(partition by column_id order by is_included_column, index_id desc, key_ordinal) part
from (
select object_name(c.object_id) table_name,c.object_id, i.index_id,i.name index_name, index_column_id, ic.column_id, 
case when tp.name in ('nchar','char','nvarchar','varchar') then '['+c.name+' (key)] '+tp.name+' ('+cast(c.max_length as varchar)+')' 
else '['+c.name+' (key)] '+tp.name end 
column_name, key_ordinal, is_included_column, 0 mapping_keys
from sys.index_columns ic inner join sys.columns c 
on ic.column_id = c.column_id 
and ic.object_id = c.object_id
inner join sys.indexes i
on i.index_id = ic.index_id
and i.object_id = ic.object_id
inner join sys.types tp
on c.user_type_id = tp.user_type_id
where i.index_id = @index_id
and c.object_id = @object_id
union all
select object_name(c.object_id),c.object_id,i.index_id,i.name, index_column_id,ic.column_id,
case when tp.name in ('nchar','char','nvarchar','varchar') then '['+c.name+' (key)] '+tp.name+' ('+cast(c.max_length as varchar)+')' 
else '['+c.name+' (key)] '+tp.name end column_name,key_ordinal,is_included_column, 1
from sys.index_columns ic inner join sys.columns c 
on ic.column_id = c.column_id 
and ic.object_id = c.object_id
inner join sys.indexes i
on i.index_id = ic.index_id
and i.object_id = ic.object_id
inner join sys.types tp
on c.user_type_id = tp.user_type_id
where i.index_id in (0,1)
and c.object_id = @object_id

)a
)b inner join (select object_id,sum(case 
									when is_unique = 1 and type = 1 then 1 
									when is_primary_key = 1 then 1
									else 0 end) has_unique
									from sys.indexes
									group by object_id) u
on b.object_id = u.object_id
where part = 1
)c
pivot
(max(column_name) for 
header_id in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24]))piv)a
cross apply (select name from sys.indexes where object_id = @object_id and index_id = @index_id)i

return
end
GO


declare @table_name nvarchar(500) = 'sales.salesorderdetail', @index_id int = 3
declare @sql nvarchar(max), @columns nvarchar(max), @index_keys_columns int, @clustered_keys_columns int, @included_keys_columns int

select 
@clustered_keys_columns = case is_clustered when 1 then [count] - index_keys_count else 0 end, 
@index_keys_columns = index_keys_count, 
@included_keys_columns = included_columns_count, 
@columns = [columns] + case is_clustered when 1 then '' else ', [HEAP RID] binary(8)' end 
from [dbo].[internal_index_columns](object_id(@table_name),@index_id)

set @sql = 'Create Table #temp_index_total_pages (FileId tinyint, PageId int, Row smallint, Level tinyint, '+@columns+', [KeyHashValue] char(14), [Row Size] tinyint)
declare @page_id int, @exec nvarchar(200)
declare i cursor fast_forward
for
select allocated_page_page_id
from sys.dm_db_database_page_allocations(db_id(), object_id('+''''+@table_name+''''+'),'+cast(@index_id as varchar)+',null,''detailed'') 
where is_allocated = 1
and page_type = 2
and page_level = 0

open i 
fetch next from i into @page_id
while @@fetch_status = 0
begin
set @exec = ''dbcc page(0,1,''+cast(@page_id as varchar)+'',3)''
insert into #temp_index_total_pages
exec (@exec)
fetch next from i into @page_id
end
close i
deallocate i

select sum(max_number) total_fill_est, sum(free) total_fill_free, sum(max_number) - sum(free) total_fill_actual, 
round(cast(sum(free) as float) / cast(sum(max_number) as float) * 100.0, 4) internal_fragmentation_pct,
100 - round(cast(sum(free) as float) / cast(sum(max_number) as float) * 100.0, 4) pages_space_used_pct,
round(cast(avg(number_of_rows) as float) / cast(sum(max_number) as float) * 100.0, 4) avg_rows_pct
from (
select count(*) over() pages, max(number_of_rows) over() max_number, 
max(number_of_rows) over() - number_of_rows free, number_of_rows, PageId 
from (
select count(*) number_of_rows, PageId 
from #temp_index_total_pages 
group by PageId)a)b

select count(*) number_of_rows, PageId 
from #temp_index_total_pages 
group by PageId
order by count(*)

drop table #temp_index_total_pages
'
exec sp_executesql @sql
select * from sys.dm_db_index_physical_stats(db_id(), object_id('sales.salesorderdetail'), 3,null,'detailed')
