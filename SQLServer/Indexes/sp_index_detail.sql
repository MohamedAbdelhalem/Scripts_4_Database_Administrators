CREATE PROCEDURE [dbo].[sp_index_detail]
(@P_object_id int, @p_index_id int)
as
begin
declare
@P_table_Name varchar(200), @P_index_Name varchar(200), @index_type varchar(100), @is_unique int, @is_unique_constraint int, @is_primary_key int

select 
@P_table_Name = '['+schema_name(t.schema_id)+'].['+t.name+']', 
@P_index_Name = i.name, 
@index_type = i.type, 
@is_unique = i.is_unique, 
@is_unique_constraint = i.is_unique_constraint, 
@is_primary_key = i.is_primary_key
from sys.indexes i inner join sys.tables t
on i.object_id = t.object_id
where i.object_id = @P_object_id 
and index_id = @p_index_id

declare @index_id int, @index_name varchar(100), @column_name varchar(100), @sql varchar(max), @is_include int
declare i cursor fast_forward
for
SELECT index_id, index_name, 
case is_included_column 
when 0 then (
case when (select max(key_ordinal) 
FROM sys.indexes AS i INNER JOIN sys.index_columns AS ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id 
WHERE i.name = @P_Index_Name and ic.is_included_column = 0) = 1 then substring(COLUMN_NAME,1,charindex(',',COLUMN_NAME)-1)+')' else column_name end)
when 1 then (
case when (select count(*) 
FROM sys.indexes AS i INNER JOIN sys.index_columns AS ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id 
WHERE i.name = @P_Index_Name and ic.is_included_column = 1) = 1 then substring(COLUMN_NAME,1,charindex(',',COLUMN_NAME)-1)+')' else column_name end) 
end column_name,
index_column_id
from(
SELECT i.index_id, '['+i.name+']' AS index_name ,
case index_column_id
when (select min(key_ordinal) FROM sys.indexes AS i INNER JOIN sys.index_columns AS ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id WHERE i.name = @P_Index_Name and ic.is_included_column = 0) then '('+'['+COL_NAME(ic.object_id,ic.column_id)+']'+','
when (select max(key_ordinal) FROM sys.indexes AS i INNER JOIN sys.index_columns AS ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id WHERE i.name = @P_Index_Name and ic.is_included_column = 0) then '['+COL_NAME(ic.object_id,ic.column_id)+']'+')'
else '['+COL_NAME(ic.object_id,ic.column_id)+']'+',' end COLUMN_NAME,
ic.index_column_id, ic.key_ordinal, ic.is_included_column
FROM sys.indexes AS i INNER JOIN sys.index_columns AS ic 
ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.name = @P_Index_Name
and i.object_id = object_id(@P_table_name)
and is_included_column = 0
union all
SELECT i.index_id, '['+i.name+']' AS index_name ,case index_column_id
when (select min(index_column_id) FROM sys.indexes AS i INNER JOIN sys.index_columns AS ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id WHERE i.name = @P_Index_Name and ic.is_included_column = 1) then ' Include ('+'['+COL_NAME(ic.object_id,ic.column_id)+']'+','
when (select max(index_column_id) FROM sys.indexes AS i INNER JOIN sys.index_columns AS ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id WHERE i.name = @P_Index_Name and ic.is_included_column = 1) then '['+COL_NAME(ic.object_id,ic.column_id)+']'+')'
else '['+COL_NAME(ic.object_id,ic.column_id)+']'+',' end COLUMN_NAME,
ic.index_column_id, ic.key_ordinal,
ic.is_included_column
FROM sys.indexes AS i INNER JOIN sys.index_columns AS ic 
ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.name = @P_Index_Name
and i.object_id = object_id(@P_table_name)
and is_included_column = 1)A
order by index_column_id

set @sql = ''
open i
fetch next from i into @index_id, @index_name, @column_name, @is_include
while @@fetch_status = 0
begin
set @sql = @sql+' '+@column_name

fetch next from i into @index_id, @index_name, @column_name, @is_include
end
close i
deallocate i
if @is_primary_key = 1
begin
set @sql = 'ALTER TABLE '+@p_table_name+' ADD CONSTRAINT ['+@p_index_name+'] PRIMARY KEY '+ case when @index_id = 1 then 'CLUSTERED ' else 'NONCLUSTERED ' end + @sql
end
else
begin
if @is_unique_constraint = 1
begin

set @sql = 'ALTER TABLE '+@p_table_name+' ADD CONSTRAINT ['+@p_index_name+'] UNIQUE '+ case when @index_id = 1 then 'CLUSTERED ' else 'NONCLUSTERED ' end + @sql
end
else
begin
set @sql = 'CREATE '+case @is_unique when 1 then 'Unique ' else '' end+
Case @index_type 
when 1 then 'CLUSTERED' 
when 2 then 'NONCLUSTERED' 
end + ' INDEX ['+@P_index_Name+'] ON '+@P_table_Name+' '+@sql
end
end
select @P_table_Name, @p_index_id, @P_index_Name,Case @index_type 
when 1 then 'CLUSTERED' 
when 2 then 'NONCLUSTERED' 
end, @sql
end

go

declare @object_id bigint, @index_id bigint
declare @indexes table (id int identity(1,1), table_name varchar(500), index_id int, index_name varchar(1000), index_type varchar(100), synatx varchar(max))
declare x cursor fast_forward
for
--select t.object_id, '['+schema_name(t.schema_id)+'].['+t.name+']' table_name,t.type_desc, i.name index_name, i.index_id, i.type_desc, is_primary_key
select t.object_id, i.index_id
from sys.tables t left outer join sys.indexes i
on t.object_id = i.object_id
where is_primary_key = 0
and i.type_desc != 'HEAP'
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
