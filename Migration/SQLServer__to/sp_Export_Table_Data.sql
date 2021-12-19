--migrate database from MS SQL Server to 
--1. Oracle
--2. PostgreSQL
--3. MySQL
--4. Mongodb
--5. Cassandra

--v2.1 fixed money conversion datatype
--v2.2 fixed Nchar/Nvarchar/NText nulls
--     added computed columns and customized data types
--v2.3 adding postgresql table conversion

CREATE Procedure [dbo].[sp_Export_Table_Data](
@table varchar(350),                            -- table name included the schema name like [Sales].[SalesOrderHeader]
@migratio_to varchar(300) = 'MS SQL Server',    -- it can be MSSQL, PostgreSQL, MySQL, and Oracle (right now it's just SQL Server)
@top varchar(20)= '0',                          -- obsoleted
@with_computed int = 0,                         -- this to get the structure to be included the computed columns and customized data types
@header bit = 1,                                -- 1 = table structure, 0 = data (records)
@bulk int = 1000,                               -- number of records
@patch int = 0)                                 -- patch sequence to extract to file
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
select '['+column_name+'] '+case when @with_computed = 1 and is_computed = 1 then 'AS '+computed_def else data_type end+' '+case is_identity when 1 then 'identity(1,1)' else '' end+' '+DEFAULT_DATA+' '+
case when @with_computed = 1 and is_computed = 1 then '' else case is_not_null when 1 then 'not null' else 'null' end end+','
from (
select c.column_id, '['+schema_name(t.schema_id)+'].['+t.name+']' table_name, c.name column_name, comp.is_computed, comp.definition computed_def,
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
else
tp.name
end data_type,
case 
when column_default is null then '' 
when column_default like '%NEXT VALUE FOR%' then '' 
else ' DEFAULT '+column_default 
end DEFAULT_DATA, case c.is_nullable when 1 then 0 else 1 end is_not_null,
case when column_default like '%NEXT VALUE FOR%' then 1 else c.is_identity end is_identity
FROM sys.columns c 
inner join sys.tables t
on t.object_id = c.object_id
inner join (
select ut.user_type_id,  
case when ut.is_user_defined = 1 and @with_computed = 1 then '['+schema_name(ut.schema_id)+'].['+ut.name+']' else utp.name end [name], 
ut.max_length, ut.precision, ut.scale, ut.is_nullable
from sys.types ut inner join sys.types utp
on ut.system_type_id = utp.user_type_id)tp
on c.user_type_id = tp.user_type_id
inner join INFORMATION_SCHEMA.COLUMNS cs 
on cs.COLUMN_NAME = c.name
left outer join sys.computed_columns comp
on c.column_id = comp.column_id
and c.object_id = comp.object_id
where object_id('['+cs.TABLE_SCHEMA+'].['+cs.TABLE_NAME+']') = c.object_id
and t.object_id = @object_id)a
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


--select @IS_IDENTITY = COUNT(*) 
--from sys.tables
--where name = @TABLE_NAME
--if @IS_IDENTITY > 0
--begin

--Insert Into @result Select '
--GO
--SET IDENTITY_INSERT '+@TABLE_NAME+' ON'
--end
if @header = 1
begin
set @v$column_desc = substring(@v$column_desc , 1, len(@v$column_desc)-1)
Insert Into @result Select 'create table '+@TABLE_NAME+' ('+@v$column_desc+')'
end
else
begin
declare @col cursor
set @col = cursor local
for
select lower(COLUMN_NAME),lower('@'+COLUMN_NAME),
case 
when data_type = 'char'				then '['+data_type+']'+'('+case when cast(character_maximum_length as varchar(50)) = '-1' then 'max' else cast(character_maximum_length as varchar(50)) end+')'
when data_type = 'nchar'			then '['+data_type+']'+'('+case when cast(character_maximum_length as varchar(50)) = '-1' then 'max' else cast(character_maximum_length as varchar(50)) end+')' 
when data_type = 'varchar'			then '['+data_type+']'+'('+case when cast(character_maximum_length as varchar(50)) = '-1' then 'max' else cast(character_maximum_length as varchar(50)) end+')' 
when data_type = 'nvarchar'			then '['+data_type+']'+'('+case when cast(character_maximum_length as varchar(50)) = '-1' then 'max' else cast(character_maximum_length as varchar(50)) end+')' 
when data_type = 'text'				then '[varchar](8000)'
when data_type = 'ntext'			then '[nvarchar](8000)'
when data_type = 'bit'				then '['+data_type+']'
when data_type = 'numeric'			then '['+data_type+']'+'('+cast(NUMERIC_PRECISION as varchar(50))+','+cast(NUMERIC_SCALE as varchar(50))+')'
when data_type = 'money'			then '['+data_type+']' 
when data_type = 'smallmoney'		then '['+data_type+']'
when data_type = 'uniqueidentifier' then '['+data_type+']'
when data_type = 'float'			then '['+data_type+']' 
when data_type = 'int'				then '['+data_type+']' 
when data_type = 'bigint'			then '['+data_type+']' 
when data_type = 'smallint'			then '['+data_type+']' 
when data_type = 'tinyint'			then '['+data_type+']' 
when data_type = 'datetime'			then '['+data_type+']' 
when data_type = 'date'				then '['+data_type+']' 
when data_type = 'smalldate'		then '['+data_type+']' 
end DATA_TYPE,
case 
when data_type = 'char'				then '+isnull('+''''''''''+'+@'+lower(column_name)+'+'''''''',''NULL'')+'+''
when data_type = 'nchar'			then '+isnull(''N''+'+''''''''''+'+@'+lower(column_name)+'+'''''''',''NULL'')+'+''
when data_type = 'varchar'			then '+isnull('+''''''''''+'+@'+lower(column_name)+'+'''''''',''NULL'')+'+''
when data_type = 'nvarchar'			then '+isnull(''N''+'+''''''''''+'+@'+lower(column_name)+'+'''''''',''NULL'')+'+''
when data_type = 'text'				then '+isnull('+''''''''''+'+@'+lower(column_name)+'+'''''''',''NULL'')+'+''
when data_type = 'ntext'			then '+isnull(''N''+'+''''''''''+'+@'+lower(column_name)+'+'''''''',''NULL'')+'+''
when data_type = 'bit'				then '+isnull(convert(varchar(50), @'+lower(column_name)+', 2),''NULL'')'
when data_type = 'numeric'			then '+isnull(convert(varchar(50), @'+lower(column_name)+', 2),''NULL'')'
when data_type = 'money'			then '+isnull(convert(varchar(50), @'+lower(column_name)+', 2),''NULL'')'
when data_type = 'smallmoney'		then '+isnull(convert(varchar(50), @'+lower(column_name)+', 2),''NULL'')'
when data_type = 'uniqueidentifier'	then '+isnull('+''''''''''+'+cast(@'+lower(column_name)+' as varchar(50))+'+''''''''',''NULL'')+'+''
when data_type = 'float'			then '+isnull(convert(varchar(50), @'+lower(column_name)+', 2),''NULL'')'
when data_type = 'int'				then '+isnull(convert(varchar(50), @'+lower(column_name)+', 2),''NULL'')'
when data_type = 'bigint'			then '+isnull(convert(varchar(50), @'+lower(column_name)+', 2),''NULL'')'
when data_type = 'smallint'			then '+isnull(convert(varchar(50), @'+lower(column_name)+', 2),''NULL'')'
when data_type = 'tinyint'			then '+isnull(convert(varchar(50), @'+lower(column_name)+', 2),''NULL'')'
when data_type = 'datetime'			then ''''+''''+''''+''''+'+isnull(convert(varchar(50),@'+lower(column_name)+',121),''NULL'')+'+''''+''''+''''+''''
when data_type = 'date'				then ''''+''''+''''+''''+'+isnull(convert(varchar(50),@'+lower(column_name)+',121),''NULL'')+'+''''+''''+''''+''''
when data_type = 'smalldate'		then ''''+''''+''''+''''+'+isnull(convert(varchar(50),@'+lower(column_name)+',121),''NULL'')+'+''''+''''+''''+''''
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
deallocate @col
end
close tab

end 
deallocate tab
deallocate @tab

Select Output_Text 
from @Result 
where Row_no between ((@patch * @bulk) + 1) and ((@patch + 1) * @bulk)
order by Row_no

set nocount off
end
