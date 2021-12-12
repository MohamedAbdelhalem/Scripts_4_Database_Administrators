--migrate database from MS SQL Server to 
--1. Oracle
--2. PostgreSQL
--3. MySQL
--4. Mongodb
--5. Cassandra
--and from 1..5 to MS SQL Server

CREATE Procedure [dbo].[sp_Export_Table_Data]
(@table varchar(250) = '[Sales].[SalesPerson]', @top varchar(20)= '0')
as
begin
declare @object_id int = object_id(@table), @table_id int
declare @result Table (Output_Text nvarchar(max), Row_no int identity(1,1))
declare
@table_name varchar(250),
@column_name varchar(250),
@vcolumn_name varchar(250),
@count_columns int,
@loop int,
@vcol varchar(50),
@datatype varchar(50),
@values_datatype varchar(100),
@V$declare varchar(max),
@V$select varchar(max),
@V$variables varchar(max),
@V$conca varchar(max),
@v$values varchar(max),
@v$column_desc varchar(max),
@COLUMN_DESC VARCHAR(300),
@IS_IDENTITY INT

set nocount on 
declare tab cursor fast_forward
for
select '['+schema_name(schema_id)+'].['+name+']' , @object_id
from sys.tables
WHERE object_id = @object_id
order by name

declare @col cursor
declare @tab cursor

open tab
fetch next from tab into @table_name, @table_id
while @@FETCH_STATUS = 0
begin

set @V$declare = ''
set @V$select = ''
set @V$variables = ''
set @V$conca = ''
set @v$values = ''
set @v$column_desc = ''

set @tab = cursor local
for
select '['+column_name+'] '+data_type+' '+case is_identity when 1 then 'identity(1,1)' else '' end+' '+DEFAULT_DATA+' '+case is_not_null when 1 then 'not null' else 'null' end+','
from (
select c.column_id, '['+schema_name(t.schema_id)+'].['+t.name+']' table_name, c.name column_name, 
tp.name , case 
when tp.name = 'char'      then '['+tp.name+']'+'('+case when cast(c.max_length as varchar) = '-1' then 'max' else cast(c.max_length as varchar) end+')'
when tp.name = 'nchar'     then '['+tp.name+']'+'('+case when cast(c.max_length as varchar) = '-1' then 'max' else cast(c.max_length as varchar) end+')' 
when tp.name = 'varchar'   then '['+tp.name+']'+'('+case when cast(c.max_length as varchar) = '-1' then 'max' else cast(c.max_length as varchar) end+')' 
when tp.name = 'nvarchar'  then '['+tp.name+']'+'('+case when cast(c.max_length as varchar) = '-1' then 'max' else cast(c.max_length as varchar) end+')' 
when tp.name = 'text'      then '['+tp.name+']'
when tp.name = 'ntext'     then '['+tp.name+']'
when tp.name = 'bit'       then '['+tp.name+']'
when tp.name = 'decimal'   then '['+tp.name+']'+'('+cast(c.scale as varchar)+','+cast(c.scale  as varchar)+')'
when tp.name = 'numeric'   then '['+tp.name+']'+'('+cast(c.scale as varchar)+','+cast(c.scale  as varchar)+')'
when tp.name = 'money'     then '['+tp.name+']' 
when tp.name = 'smallmoney'then '['+tp.name+']' 
when tp.name = 'float'     then '['+tp.name+']' 
when tp.name = 'int'       then '['+tp.name+']' 
when tp.name = 'bigint'    then '['+tp.name+']' 
when tp.name = 'smallint'  then '['+tp.name+']' 
when tp.name = 'tinyint'   then '['+tp.name+']' 
when tp.name = 'uniqueidentifier' then '['+tp.name+']'
when tp.name = 'datetime'  then '['+tp.name+']' 
when tp.name = 'date'      then '['+tp.name+']' 
when tp.name = 'smalldate' then '['+tp.name+']' 
when tp.name = 'varbinary' then '['+tp.name+']'+'('+case when cast(c.max_length as varchar) = '-1' then 'max' else cast(c.max_length as varchar) end+')'
when tp.name = 'binary'    then '['+tp.name+']'+'('+case when cast(c.max_length as varchar) = '-1' then 'max' else cast(c.max_length as varchar) end+')'
when tp.name = 'real'      then '['+tp.name+']'
when tp.name = 'image'     then '['+tp.name+']'
end data_type,
case 
when column_default is null then '' 
when column_default like '%NEXT VALUE FOR%' then '' 
else ' DEFAULT '+column_default 
end DEFAULT_DATA, case c.is_nullable when 1 then 0 else 1 end is_not_null,
case when column_default like '%NEXT VALUE FOR%' then 1 else IS_IDENTITY end IS_IDENTITY
FROM sys.columns c 
inner join sys.tables t
on t.object_id = c.object_id
inner join sys.types tp
on c.user_type_id = tp.user_type_id
inner join INFORMATION_SCHEMA.COLUMNS cs 
on cs.COLUMN_NAME = c.name
and object_id('['+cs.TABLE_SCHEMA+'].['+cs.TABLE_NAME+']') = c.object_id
where t.object_id = @object_id)aa
union all
SELECT 'CONSTRAINT ['+CONSTRAINT_NAME+'] PRIMARY KEY (['+COLUMN_NAME+']),'
FROM [INFORMATION_SCHEMA].[KEY_COLUMN_USAGE] KC 
INNER JOIN [sys].[key_constraints] KCON
ON KC.CONSTRAINT_NAME = KCON.NAME
where object_id('['+constraint_schema+'].['+table_name+']') = @object_id

open @tab
fetch next from @TAB into @COLUMN_DESC
while @@FETCH_STATUS = 0
begin
set @v$column_desc = @v$column_desc+'
'+@COLUMN_DESC
fetch next from @TAB into @COLUMN_DESC
end
close @tab

set @v$column_desc = substring(@v$column_desc , 1, len(@v$column_desc)-1)
Insert Into @result Select 'create table '+@TABLE_NAME+' ('+@v$column_desc+')'

select @IS_IDENTITY = COUNT(*) 
from sys.tables
where name = @TABLE_NAME
if @IS_IDENTITY > 0
begin

Insert Into @result Select '
GO
SET IDENTITY_INSERT '+@TABLE_NAME+' ON'
end
set @col = cursor local
for
select lower(COLUMN_NAME),lower('@'+COLUMN_NAME),
case 
when data_type = 'char'      then '['+data_type+']'+'('+case when cast(character_maximum_length as varchar) = '-1' then 'max' else cast(character_maximum_length as varchar) end+')'
when data_type = 'nchar'     then '['+data_type+']'+'('+case when cast(character_maximum_length as varchar) = '-1' then 'max' else cast(character_maximum_length as varchar) end+')' 
when data_type = 'varchar'   then '['+data_type+']'+'('+case when cast(character_maximum_length as varchar) = '-1' then 'max' else cast(character_maximum_length as varchar) end+')' 
when data_type = 'nvarchar'  then '['+data_type+']'+'('+case when cast(character_maximum_length as varchar) = '-1' then 'max' else cast(character_maximum_length as varchar) end+')' 
when data_type = 'text'      then '[varchar](8000)'
when data_type = 'ntext'     then '[nvarchar](4000)'
when data_type = 'bit'       then '['+data_type+']'
when data_type = 'numeric'   then '['+data_type+']'+'('+cast(NUMERIC_PRECISION as varchar)+','+cast(NUMERIC_SCALE as varchar)+')'
when data_type = 'money'     then '['+data_type+']' 
when data_type = 'smallmoney'then '['+data_type+']'
when data_type = 'uniqueidentifier' then '['+data_type+']'
when data_type = 'float'     then '['+data_type+']' 
when data_type = 'int'       then '['+data_type+']' 
when data_type = 'bigint'    then '['+data_type+']' 
when data_type = 'smallint'  then '['+data_type+']' 
when data_type = 'tinyint'   then '['+data_type+']' 
when data_type = 'datetime'  then '['+data_type+']' 
when data_type = 'date'      then '['+data_type+']' 
when data_type = 'smalldate' then '['+data_type+']' 
end DATA_TYPE,
case 
when data_type = 'char'      then ''''+''''+''''+''''+'+isnull(@'+lower(column_name)+',''NULL'')+'+''''+''''+''''+''''
when data_type = 'nchar'     then '''N''+'+''''+''''+''''+''''+'+isnull(@'+lower(column_name)+',''NULL'')+'+''''+''''+''''+''''
when data_type = 'varchar'   then ''''+''''+''''+''''+'+isnull(@'+lower(column_name)+',''NULL'')+'+''''+''''+''''+''''
when data_type = 'nvarchar'  then '''N''+'+''''+''''+''''+''''+'+isnull(@'+lower(column_name)+',''NULL'')+'+''''+''''+''''+''''
when data_type = 'text'      then ''''+''''+''''+''''+'+isnull(@'+lower(column_name)+',''NULL'')+'+''''+''''+''''+''''
when data_type = 'ntext'     then '''N''+'+''''+''''+''''+''''+'+isnull(@'+lower(column_name)+',''NULL'')+'+''''+''''+''''+''''
when data_type = 'bit'       then '+isnull(cast(@'+lower(column_name)+' as varchar),''NULL'')'
when data_type = 'numeric'   then '+isnull(cast(@'+lower(column_name)+' as varchar),''NULL'')'
when data_type = 'money'     then '+isnull(cast(@'+lower(column_name)+' as varchar),''NULL'')'
when data_type = 'smallmoney'then '+isnull(cast(@'+lower(column_name)+' as varchar),''NULL'')'
when data_type = 'uniqueidentifier'then ''''+''''+''''+''''+'+isnull(cast(@'+lower(column_name)+' as varchar(50)),''NULL'')+'+''''+''''+''''+''''
when data_type = 'float'     then '+isnull(cast(@'+lower(column_name)+' as varchar),''NULL'')'
when data_type = 'int'       then '+isnull(cast(@'+lower(column_name)+' as varchar),''NULL'')'
when data_type = 'bigint'    then '+isnull(cast(@'+lower(column_name)+' as varchar),''NULL'')'
when data_type = 'smallint'  then '+isnull(cast(@'+lower(column_name)+' as varchar),''NULL'')'
when data_type = 'tinyint'   then '+isnull(cast(@'+lower(column_name)+' as varchar),''NULL'')'
when data_type = 'datetime'  then ''''+''''+''''+''''+'+isnull(convert(varchar(25),@'+lower(column_name)+',121),''NULL'')+'+''''+''''+''''+''''
when data_type = 'date'      then ''''+''''+''''+''''+'+isnull(convert(varchar(25),@'+lower(column_name)+',121),''NULL'')+'+''''+''''+''''+''''
when data_type = 'smalldate' then ''''+''''+''''+''''+'+isnull(convert(varchar(25),@'+lower(column_name)+',121),''NULL'')+'+''''+''''+''''+''''
end DATA_TYPE
FROM INFORMATION_SCHEMA.columns c
where '['+c.TABLE_SCHEMA+'].['+TABLE_NAME+']' = @table_name
order by ordinal_position

open @col
fetch next from @col into @column_name , @vcolumn_name, @datatype, @values_datatype
while @@FETCH_STATUS = 0
begin
set @V$declare = @V$declare + '
'+@vcolumn_name+' '+@datatype+','
set @V$select = @V$select +@column_name+','
set @V$variables = @V$variables + @vcolumn_name+','
SET @V$conca = @V$conca + @vcolumn_name+'+'
set @v$values = @v$values+' '+@values_datatype+'+'',''+'
fetch next from @col into @column_name , @vcolumn_name, @datatype, @values_datatype
end
close @col

set @V$declare = substring(@V$declare, 1, len(@V$declare)-1)
set @V$select = substring(@V$select, 1, len(@V$select)-1)
set @V$variables = substring(@V$variables,1,len(@V$variables)-1)
set @V$conca = substring(@V$conca,1,len(@V$conca)-1)
set @v$values = substring(@v$values, 1, len(@v$values)-3)

set @top = case when @top = '0' then '100 Percent' else @top end
Insert Into @Result 
exec('
declare 
'+@V$declare+'
declare CURSOR_COLUMN cursor fast_forward
for
select top '+@TOP+' '+@V$select+'
from '+@table_name+'

open CURSOR_COLUMN
fetch next from CURSOR_COLUMN into '+@V$variables+'
while @@fetch_status = 0
begin
--print(''insert into '+@table_name+' 
--('+@V$SELECT+') 
--values 
--('''+@V$values+')'')
Select ''insert into '+@table_name+' ('+@V$SELECT+') VALUES ('''+@V$values+')''

fetch next from CURSOR_COLUMN into '+@V$variables+'
end
close CURSOR_COLUMN
deallocate CURSOR_COLUMN')

fetch next from tab into @table_name, @table_id
end
close tab

deallocate tab
deallocate @tab
deallocate @col

Select Output_Text 
from @Result 
order by Row_no

set nocount off
end
