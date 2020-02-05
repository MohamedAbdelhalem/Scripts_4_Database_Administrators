CREATE PROCEDURE sp_get_index
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
print(@sql)
end

GO

CREATE PROCEDURE sp_get_table_indexes
(@P_object_id int)
as
begin
declare @index_id int
declare index_cursor cursor fast_forward
for
select index_id 
from sys.indexes
where object_id = @P_object_id

open index_cursor 
fetch next from index_cursor into @index_id
while @@FETCH_STATUS = 0
begin

if @index_id > 0
exec sp_get_index @p_object_id, @index_id

fetch next from index_cursor into @index_id
end
close index_cursor  
deallocate index_cursor 
end

GO

CREATE Procedure sp_export_indexes
(@objid int = 0)
as
begin
declare @tables table (object_id bigint, table_name varchar(350))
set nocount on

if @objid = 0
insert into @tables
select object_id , '['+schema_name(schema_id)+'].['+name+']'
from sys.tables 
where type = 'U'
else
insert into @tables
select object_id , '['+schema_name(schema_id)+'].['+name+']'
from sys.tables 
where type = 'U'
and object_id = @objid

declare @object_id int, @table_name varchar(350)
declare indexes_cursor cursor fast_forward
for
select object_id, table_name 
from @tables 
order by table_name

open indexes_cursor
fetch next from indexes_cursor into @object_id, @table_name 
while @@FETCH_STATUS = 0
begin

print('-- '+@table_name)
exec dbo.sp_get_table_indexes @object_id

fetch next from indexes_cursor into @object_id, @table_name 
end
close indexes_cursor
deallocate indexes_cursor

set nocount off
end
GO

exec dbo.sp_export_indexes