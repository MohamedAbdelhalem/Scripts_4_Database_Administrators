CREATE PROCEDURE [dbo].[Azure_Tables_Consolidation]
(@year int)
as
begin
set nocount on
declare @table_name varchar(500), @sql varchar(max), @column_datatype varchar(max), @count int, @pct float, @loop int = 1, @prev int = 0, @prog int = 1
select @count = count(*) from sys.tables
where name like '%'+cast(@year as varchar)+'%'

set @pct = 100.00 / cast(@count as float)

declare insert_cursor cursor fast_forward
for
select name from sys.tables
where name like '%'+cast(@year as varchar)+'%'
order by name

open insert_cursor
fetch next from insert_cursor into @table_name
while @@FETCH_STATUS = 0
begin

if (select count(*) from sys.tables where name = (select top 1 substring(name,1,charindex('_'+cast(@year as varchar), name)-1) from sys.tables where name like '%'+cast(@year as varchar)+'%')) = 0
begin
declare create_tb_cursor cursor fast_forward
for
select '['+column_name+'] '+data_type+case when column_id = (select max(column_id) from sys.columns col where col.object_id = object_id(@table_name)) 
then '' else ',' end
from (
SELECT 
column_id, table_name, column_name, 
case 
when data_type = 'char'      then '['+data_type+']'+'('+case when cast(max_length as varchar) = '-1' then 'max' else cast(max_length as varchar) end+')'
when data_type = 'nchar'     then '['+data_type+']'+'('+case when cast(max_length as varchar) = '-1' then 'max' else cast(max_length as varchar) end+')' 
when data_type = 'varchar'   then '['+data_type+']'+'('+case when cast(max_length as varchar) = '-1' then 'max' else cast(max_length as varchar) end+')' 
when data_type = 'nvarchar'  then '['+data_type+']'+'('+case when cast(max_length as varchar) = '-1' then 'max' else cast(max_length as varchar) end+')' 
when data_type = 'text'      then '['+data_type+']'
when data_type = 'uniqueidentifier'     then '['+data_type+']'
when data_type = 'ntext'     then '['+data_type+']'
when data_type = 'bit'       then '['+data_type+']'
when data_type = 'numeric'   then '['+data_type+']'+'('+cast(precision as varchar)+','+cast(scale as varchar)+')'
when data_type = 'money'     then '['+data_type+']' 
when data_type = 'smallmoney'then '['+data_type+']' 
when data_type = 'float'     then '['+data_type+']' 
when data_type = 'int'       then '['+data_type+']' 
when data_type = 'bigint'    then '['+data_type+']' 
when data_type = 'smallint'  then '['+data_type+']' 
when data_type = 'tinyint'   then '['+data_type+']' 
when data_type = 'datetime'  then '['+data_type+']' 
when data_type = 'date'      then '['+data_type+']' 
when data_type = 'smalldate' then '['+data_type+']' 
when data_type = 'varbinary' then '['+data_type+']'+'('+case when cast(max_length as varchar) = '-1' then 'max' else cast(max_length as varchar) end+')'
when data_type = 'binary'    then '['+data_type+']'+'('+case when cast(max_length as varchar) = '-1' then 'max' else cast(max_length as varchar) end+')'
when data_type = 'real'      then '['+data_type+']'
when data_type = 'image'     then '['+data_type+']'
end DATA_TYPE
from (
select  
column_id, column_name, table_name, t.name data_type, max(t.scale) scale, max(a.max_length) max_length, max(a.precision) precision
from (
select
substring(object_name(object_id), 1, charindex('_'+cast(@year as varchar),object_name(object_id))-1) table_name,  
name column_name, column_id, user_type_id, max_length, precision from sys.columns where object_id in (
select object_id from sys.tables where schema_id = 1))a inner join sys.types t
on a.user_type_id = t.user_type_id
group by column_name, column_id, table_name, t.name)b)c
order by column_name, column_id

open create_tb_cursor
fetch next from create_tb_cursor into @column_datatype
while @@FETCH_STATUS = 0
begin
set @sql = isnull(@sql,'')+@column_datatype
fetch next from create_tb_cursor into @column_datatype
end
close create_tb_cursor
deallocate create_tb_cursor
set @sql = 'CREATE TABLE '+SUBSTRING(@table_name,1,CHARINDEX('_'+cast(@year as varchar), @table_name)-1)+' (
'+@sql+')'
exec(@sql)
end

set @sql = 'INSERT INTO '+SUBSTRING(@table_name,1,CHARINDEX('_'+cast(@year as varchar), @table_name)-1)+'
SELECT * from '+@table_name
exec(@sql)

SET @prog = CEILING(@pct * @loop)
IF @prev != @prog 
PRINT(@prog)
SET @loop = @loop + 1
SET @prev = @prog

fetch next from insert_cursor into @table_name
end
close insert_cursor
deallocate insert_cursor
set nocount off
end
