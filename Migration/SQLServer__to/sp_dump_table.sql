--Migrate database from MS SQL Server to 
--1. MS SQL Server 
--2. PostgreSQL
--3. MySQL
--4. Oracle
--5. Mongodb
--6. Cassandra

--v2.1 fixed money conversion datatype
--v2.2 fixed Nchar/Nvarchar/NText nulls
--     added computed columns and customized data types
--     fixed multi-column for primary key 
--v2.3 added postgresql table conversion and data insertion
--v2.3 add new table name
--v2.4 fixed column names with space 
--v2.4 added XML to SQL Server 
--v2.5 added where condition parameter to select a specific rows
--v2.5 adding patches for big tables with xml
--v2.5 adding feature to exclude columns from the insert statement (dump table)

declare @bulk int = 100000
declare @table table (id int primary key, recid varchar(255))
insert into @table 
select top (2345678) row_number() over(order by [recid]) id, [recid] 
from FBNK_FUNDS_TRANSFER#HIS
order by [recid]

--select count(*) over() - patch_id - count(*) over(order by id) unique_id, * 
--from (
--select id % @bulk patch_id, id, recid
--from @table)a
--where patch_id in (0,1)

--create table msdb.dbo.[keys___FBNK_FUNDS_TRANSFER#HIS] (id int primary key, unique_id int, from_id bigint, to_id bigint, from_recid varchar(255), to_recid varchar(255))  
--insert into msdb.dbo.[keys___FBNK_FUNDS_TRANSFER#HIS] 
select row_number() over(order by unique_id desc) id, unique_id, min(id), max(id), min(recid), max(recid)
from (
select count(*) over() - patch_id - count(*) over(order by id) unique_id, * 
from (
select id % @bulk patch_id, id, recid
from @table)a
where patch_id in (0,1))b
group by unique_id
order by unique_id desc

use [AdventureWorks2017]
GO
exec [dbo].[sp_dump_table]
@table = '[Sales].[SalesOrderDetail]', 
@new_name = '[dbo].[SalesOrderDetail]', 
@migrated_to = 'MS SQL Server', 
@where_records_condition = 'where productid = 772 
and OrderQty > 5
order by OrderQty desc',
@with_computed = 0, 
@header = 0, 
@bulk = 1000, 
@patch = 0

GO
CREATE Procedure [dbo].[sp_dump_table]
(
@table varchar(350), 
@new_name varchar(350) = 'default', 
@migrated_to varchar(300) = 'MS SQL Server', 
@where_records_condition varchar(300) = 'default',
@with_computed int = 0, 
@header bit = 1, 
@bulk int = 1000, 
@patch int = 0)
as
begin
declare @object_id int

select @object_id = object_id
from sys.tables
where object_id = object_id(@table)

declare @result Table (Output_Text nvarchar(max), Row_no int identity(1,1) primary key)
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
@V$insert_columns varchar(max),
@V$variables_cursor varchar(max),
@v$values varchar(max),
@v$column_desc varchar(max),
@column_desc varchar(300),
@is_identity int

set nocount on 
declare @tab cursor

set @V$declare = ''
set @V$select = ''
set @V$variables = ''
set @V$conca = ''
set @v$values = ''
set @v$column_desc = ''
set @V$insert_columns = ''
set @V$variables_cursor = ''
declare @table_structure table (id int identity(1,1), table_syntax nvarchar(500))

if @migrated_to = 'MS SQL Server' and @object_id is not null
begin
	insert into @table_structure (table_syntax)
	select '['+column_name+'] '+case when @with_computed = 1 and is_computed = 1 then 'AS '+computed_def else data_type end+' '+case is_identity when 1 then 'identity(1,1) ' else '' end+DEFAULT_DATA+
	case when @with_computed = 1 and is_computed = 1 then '' else case is_not_null when 1 then 'not null' else 'null' end end+','
	from (
		select	c.column_id, '['+schema_name(t.schema_id)+'].['+t.name+']' table_name, c.name column_name, comp.is_computed, comp.definition computed_def,
				tp.name , case 
				when tp.name = 'char'      then '['+tp.name+']'+'('+case when cast(c.max_length as varchar) = '-1' then 'max' else cast(c.max_length as varchar) end+')'
				when tp.name = 'nchar'     then '['+tp.name+']'+'('+case when cast(c.max_length as varchar) = '-1' then 'max' else cast(c.max_length as varchar) end+')' 
				when tp.name = 'varchar'   then '['+tp.name+']'+'('+case when cast(c.max_length as varchar) = '-1' then 'max' else cast(c.max_length as varchar) end+')' 
				when tp.name = 'nvarchar'  then '['+tp.name+']'+'('+case when cast(c.max_length as varchar) = '-1' then 'max' else cast(c.max_length as varchar) end+')' 
				when tp.name = 'text'      then '['+tp.name+']'
				when tp.name = 'ntext'     then '['+tp.name+']'
				when tp.name = 'bit'       then '['+tp.name+']'
				when tp.name = 'decimal'   then '['+tp.name+']'+'('+cast(c.precision as varchar)+','+cast(c.scale  as varchar)+')'
				when tp.name = 'numeric'   then '['+tp.name+']'+'('+cast(c.precision as varchar)+','+cast(c.scale  as varchar)+')'
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
				when tp.name = 'datetime2'		then '['+tp.name+']' 
				when tp.name = 'DATETIMEOFFSET'	then '['+tp.name+']' 
				when tp.name = 'smalldate' then '['+tp.name+']' 
				when tp.name = 'smalldatetime' then '['+tp.name+']' 
				when tp.name = 'varbinary' then '['+tp.name+']'+'('+case when cast(c.max_length as varchar) = '-1' then 'max' else cast(c.max_length as varchar) end+')'
				when tp.name = 'binary'    then '['+tp.name+']'+'('+case when cast(c.max_length as varchar) = '-1' then 'max' else cast(c.max_length as varchar) end+')'
				when tp.name = 'real'      then '['+tp.name+']'
				when tp.name = 'image'     then '['+tp.name+']'
				when tp.name = 'xml'				then '['+tp.name+']'
				when tp.name = 'ROWVERSION'			then '['+tp.name+']'
				else
				tp.name
				end data_type,
				case 
				when column_default is null then '' 
				when column_default like '%NEXT VALUE FOR%' then '' 
				else ' DEFAULT '+column_default+' ' 
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
	select 'CONSTRAINT ['+constraint_name+'] PRIMARY KEY ('+isnull( '['+[1]+']','')+isnull(',['+[2]+']','')+isnull(',['+[3]+']','')+isnull(',['+[4]+']','')+
															isnull(',['+[5]+']','')+isnull(',['+[6]+']','')+isnull(',['+[7]+']','')+isnull(',['+[8]+']','')+'),'
	from (
	select top 100 percent constraint_name, column_name, ordinal_position
	from [information_schema].[key_column_usage] kc 
	inner join [sys].[key_constraints] kcon
	on kc.constraint_name = kcon.name
	where object_id('['+constraint_schema+'].['+table_name+']') = @object_id
	order by ordinal_position)a
	pivot
	(max(column_name) for ordinal_position in ([1],[2],[3],[4],[5],[6],[7],[8]))pvt
end
else if @migrated_to = 'PostgreSQL' and @object_id is not null
begin
	insert into @table_structure (table_syntax)
	select 
	case is_space_name when 1 then '"'+column_name+'"' else column_name end
	+' '+case when @with_computed = 1 and is_computed = 1 then 'AS '+computed_def else data_type end+' '+DEFAULT_DATA+
	case when @with_computed = 1 and is_computed = 1 then '' else case is_not_null when 1 then 'not null' else 'null' end end+','
	from (
		select	c.column_id, '['+schema_name(t.schema_id)+'].['+t.name+']' table_name, c.name column_name, comp.is_computed, comp.definition computed_def,
				tp.name , case 
				when tp.name = 'char'				then case when c.max_length between 1 and 8000 then    'CHAR('+cast(c.max_length as varchar(20))+')' else 'TEXT' end
				when tp.name = 'nchar'				then case when c.max_length between 1 and 8000 then    'CHAR('+cast(c.max_length as varchar(20))+')' else 'TEXT' end
				when tp.name = 'varchar'			then case when c.max_length between 1 and 8000 then 'VARCHAR('+cast(c.max_length as varchar(20))+')' else 'TEXT' end
				when tp.name = 'nvarchar'			then case when c.max_length between 1 and 8000 then 'VARCHAR('+cast(c.max_length as varchar(20))+')' else 'TEXT' end
				when tp.name = 'text'				then 'TEXT'
				when tp.name = 'ntext'				then 'TEXT'
				when tp.name = 'bit'				then 'BOOLEAN'
				when tp.name = 'decimal'			then tp.name+'('+cast(c.precision as varchar)+','+cast(c.scale  as varchar)+')'
				when tp.name = 'numeric'			then tp.name+'('+cast(c.precision as varchar)+','+cast(c.scale  as varchar)+')'
				when tp.name = 'money'				then tp.name 
				when tp.name = 'smallmoney'			then 'MONEY'
				when tp.name = 'float'				then 'FLOAT' 
				when tp.name = 'int'				then tp.name 
				when tp.name = 'bigint'				then tp.name 
				when tp.name = 'smallint'			then tp.name 
				when tp.name = 'tinyint'			then 'SMALLINT'
				when tp.name = 'uniqueidentifier'	then 'CHAR(36)'
				when tp.name = 'datetime'			then 'TIMESTAMP(0)' 
				when tp.name = 'datetime2'			then 'TIMESTAMP(3)' 
				when tp.name = 'DATETIMEOFFSET'		then 'TIMESTAMP(3) WITH TIME ZONE' 
				when tp.name = 'Date'				then 'DATE'
				when tp.name = 'smalldate'			then tp.name 
				when tp.name = 'smalldatetime'		then 'TIMESTAMP(0)'
				when tp.name = 'varbinary'			then 'BYTEA'
				when tp.name = 'binary'				then 'BYTEA'
				when tp.name = 'real'				then 'REAL'
				when tp.name = 'image'				then 'BYTEA'
				when tp.name = 'xml'				then 'XML'
				when tp.name = 'ROWVERSION'			then 'BYTEA'
				else
				tp.name
				end data_type,
				case 
				when column_default is null then '' 
				when column_default like '%NEXT VALUE FOR%' then '' 
				else ' DEFAULT '+case 
				when ltrim(rtrim(column_default)) = '(getdate())'	then 'now()::timestamp(0)' 
				when ltrim(rtrim(column_default)) = '(Newid())'	then 'uuid_generate_v4 ()' 
				when ltrim(rtrim(column_default)) = '((1))'	and tp.name = 'bit' then 'true' 
				when ltrim(rtrim(column_default)) = '((0))'	and tp.name = 'bit' then 'false' 
				else ltrim(rtrim(column_default)) end+' ' 
				end DEFAULT_DATA, case c.is_nullable when 1 then 0 else 1 end is_not_null,
				case when column_default like '%NEXT VALUE FOR%' then 1 else c.is_identity end is_identity, 
				case when charindex(' ', c.name) > 0 then 1 else 0 end is_space_name
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
	select 'CONSTRAINT '+constraint_name+' PRIMARY KEY ('+isnull(    [1],'')+isnull(','+[2],'')+isnull(','+[3],'')+isnull(','+[4],'')+
														  isnull(','+[5],'')+isnull(','+[6],'')+isnull(','+[7],'')+isnull(','+[8],'')+'),'
	from (
	select top 100 percent constraint_name, column_name, ordinal_position
	from [information_schema].[key_column_usage] kc 
	inner join [sys].[key_constraints] kcon
	on kc.constraint_name = kcon.name
	where object_id('['+constraint_schema+'].['+table_name+']') = @object_id
	order by ordinal_position)a
	pivot
	(max(column_name) for ordinal_position in ([1],[2],[3],[4],[5],[6],[7],[8]))pvt
end

if @object_id is not null
begin

set @tab = cursor local
for
select table_syntax 
  from @table_structure
 order by id

open @tab
fetch next from @tab into @column_desc
while @@FETCH_STATUS = 0
begin
	set @v$column_desc = @v$column_desc+' '+@column_desc
fetch next from @tab into @column_desc
end
close @tab
deallocate @tab

declare @insert_syntax table (column_name varchar(300), v_column_name varchar(300), data_type varchar(300), inserted_data_type varchar(1000))
if @header = 1
begin
	set @v$column_desc = substring(@v$column_desc , 1, len(@v$column_desc)-1)
	Insert Into @result Select 'Create Table '+
			case @migrated_to when 'MS SQL Server' 
		then 
			case 
				when @new_name = 'default' or replace(replace(@new_name,']',''),'[','') = replace(replace(@table,']',''),'[','') then 
					@table
				else 
					@new_name 
			end
		else 
			case 
				when @new_name = 'default' or replace(replace(@new_name,']',''),'[','') = replace(replace(@table,']',''),'[','') then 
					replace(replace(@table,']',''),'[','')
				else 
					replace(replace(@new_name,']',''),'[','') 
			end
		end+' ('+@v$column_desc+');'
end
else
begin
	if @migrated_to = 'MS SQL Server'
	begin
		insert into @insert_syntax
		select	lower(case when charindex(' ',column_name) > 0 then '['+COLUMN_NAME+']' else column_name end),
				lower('@'+case when charindex(' ',column_name) > 0 then replace(COLUMN_NAME,' ','') else column_name end),
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
				when data_type = 'smalldatetime'	then '['+data_type+']' 
				when data_type = 'xml'				then '['+data_type+']' 
				end DATA_TYPE,
				case 
				when data_type = 'char'				then '+isnull('+''''''''''+'+@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+'+'''''''',''NULL'')+'+''
				when data_type = 'nchar'			then '+isnull(''N''+'+''''''''''+'+@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+'+'''''''',''NULL'')+'+''
				when data_type = 'varchar'			then '+isnull('+''''''''''+'+@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+'+'''''''',''NULL'')+'+''
				when data_type = 'nvarchar'			then '+isnull(''N''+'+''''''''''+'+@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+'+'''''''',''NULL'')+'+''
				when data_type = 'text'				then '+isnull('+''''''''''+'+@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+'+'''''''',''NULL'')+'+''
				when data_type = 'ntext'			then '+isnull(''N''+'+''''''''''+'+@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+'+'''''''',''NULL'')+'+''
				when data_type = 'bit'				then '+isnull(convert(varchar(50), @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+', 2),''NULL'')'
				when data_type = 'numeric'			then '+isnull(convert(varchar(50), @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+', 2),''NULL'')'
				when data_type = 'money'			then '+isnull(convert(varchar(50), @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+', 2),''NULL'')'
				when data_type = 'smallmoney'		then '+isnull(convert(varchar(50), @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+', 2),''NULL'')'
				when data_type = 'uniqueidentifier'	then '+isnull('+''''''''''+'+cast(@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+' as varchar(50))+'+''''''''',''NULL'')+'+''
				when data_type = 'float'			then '+isnull(convert(varchar(50), @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+', 2),''NULL'')'
				when data_type = 'int'				then '+isnull(convert(varchar(50), @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+', 2),''NULL'')'
				when data_type = 'bigint'			then '+isnull(convert(varchar(50), @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+', 2),''NULL'')'
				when data_type = 'smallint'			then '+isnull(convert(varchar(50), @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+', 2),''NULL'')'
				when data_type = 'tinyint'			then '+isnull(convert(varchar(50), @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+', 2),''NULL'')'
				when data_type = 'datetime'			then ''''+''''+''''+''''+'+isnull(convert(varchar(50),@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+',121),''NULL'')+'+''''+''''+''''+''''
				when data_type = 'datetime2'		then ''''+''''+''''+''''+'+isnull(convert(varchar(50),@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+',121),''NULL'')+'+''''+''''+''''+''''
				when data_type = 'date'				then ''''+''''+''''+''''+'+isnull(convert(varchar(50),@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+',121),''NULL'')+'+''''+''''+''''+''''
				when data_type = 'smalldate'		then ''''+''''+''''+''''+'+isnull(convert(varchar(50),@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+',121),''NULL'')+'+''''+''''+''''+''''
				when data_type = 'smalldatetime'	then ''''+''''+''''+''''+'+isnull(convert(varchar(50),@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+',121),''NULL'')+'+''''+''''+''''+''''
				when data_type = 'xml'				then '+@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+'+'+''
				end DATA_TYPE
		from INFORMATION_SCHEMA.columns c
		where object_id('['+c.TABLE_SCHEMA+'].['+TABLE_NAME+']') = @object_id
		order by ordinal_position
	end
	else if @migrated_to = 'PostgreSQL'
	begin
		insert into @insert_syntax
		select	lower(case when charindex(' ',column_name) > 0 then '"'+COLUMN_NAME+'"' else column_name end),
				lower('@'+case when charindex(' ',column_name) > 0 then replace(COLUMN_NAME,' ','') else column_name end),
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
				when data_type = 'smalldatetime'	then '['+data_type+']' 
				end DATA_TYPE,
				case 
				when data_type = 'char'				then '+isnull('+''''''''''+'+@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+'+'''''''',''NULL'')+'+''
				when data_type = 'nchar'			then '+isnull('+''''''''''+'+@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+'+'''''''',''NULL'')+'+''
				when data_type = 'varchar'			then '+isnull('+''''''''''+'+@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+'+'''''''',''NULL'')+'+''
				when data_type = 'nvarchar'			then '+isnull('+''''''''''+'+@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+'+'''''''',''NULL'')+'+''
				when data_type = 'text'				then '+isnull('+''''''''''+'+@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+'+'''''''',''NULL'')+'+''
				when data_type = 'ntext'			then '+isnull('+''''''''''+'+@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+'+'''''''',''NULL'')+'+''
				when data_type = 'bit'				then '+isnull(convert(varchar(50), case @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+' when 1 then ''true'' else ''false'' end, 2),''NULL'')'
				when data_type = 'numeric'			then '+isnull(convert(varchar(50), @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+', 2),''NULL'')'
				when data_type = 'money'			then '+isnull(convert(varchar(50), @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+', 2),''NULL'')'
				when data_type = 'smallmoney'		then '+isnull(convert(varchar(50), @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+', 2),''NULL'')'
				when data_type = 'uniqueidentifier'	then '+isnull('+''''''''''+'+cast(@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+' as varchar(50))+'+''''''''',''NULL'')+'+''
				when data_type = 'float'			then '+isnull(convert(varchar(50), @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+', 2),''NULL'')'
				when data_type = 'int'				then '+isnull(convert(varchar(50), @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+', 2),''NULL'')'
				when data_type = 'bigint'			then '+isnull(convert(varchar(50), @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+', 2),''NULL'')'
				when data_type = 'smallint'			then '+isnull(convert(varchar(50), @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+', 2),''NULL'')'
				when data_type = 'tinyint'			then '+isnull(convert(varchar(50), @'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+', 2),''NULL'')'
				when data_type = 'datetime'			then ''''+''''+''''+''''+'+isnull(convert(varchar(50),@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+',121),''NULL'')+'+''''+''''+''''+''''
				when data_type = 'datetime2'		then ''''+''''+''''+''''+'+isnull(convert(varchar(50),@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+',121),''NULL'')+'+''''+''''+''''+''''
				when data_type = 'date'				then ''''+''''+''''+''''+'+isnull(convert(varchar(50),@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+',121),''NULL'')+'+''''+''''+''''+''''
				when data_type = 'smalldate'		then ''''+''''+''''+''''+'+isnull(convert(varchar(50),@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+',121),''NULL'')+'+''''+''''+''''+''''
				when data_type = 'smalldatetime'	then ''''+''''+''''+''''+'+isnull(convert(varchar(50),@'+lower(case when charindex(' ',column_name) > 0 then replace(column_name,' ','') else column_name end)+',121),''NULL'')+'+''''+''''+''''+''''
				end DATA_TYPE
		from INFORMATION_SCHEMA.columns c
		where object_id('['+c.TABLE_SCHEMA+'].['+TABLE_NAME+']') = @object_id
		order by ordinal_position
	end

	declare @col cursor
	set @col = cursor local
	for
	select column_name, v_column_name, data_type, inserted_data_type 
	from @insert_syntax

	open @col
	fetch next from @col into @column_name , @vcolumn_name, @datatype, @values_datatype
	while @@FETCH_STATUS = 0
	begin
		set @V$declare = @V$declare+ @vcolumn_name+' '+case @datatype when '[xml]' then '[nvarchar](max)' else @datatype end+','
		set @V$insert_columns = @V$insert_columns + '['+@column_name+'],'
		set @V$select = @V$select + case @datatype when '[xml]' 
		then 'isnull(convert(nvarchar(max),convert(varbinary(max),'+lower(case when charindex(' ',@column_name) > 0 
		then replace('['+@column_name+']',' ','') else '['+@column_name+']' end)+',2),2),''NULL'')' else '['+@column_name+']' end+','
		set @V$variables_cursor = @V$variables_cursor +'@'+@column_name+','
		set @V$variables = @V$variables + case @datatype when '[xml]' 
		then 'isnull(convert(nvarchar(max),convert(varbinary(max),'+lower(case when charindex(' ',@column_name) > 0 
		then replace('@'+@column_name,' ','') else '@'+@column_name end)+',2),2),''NULL'')' else '@'+@column_name end+','
		set @V$conca = @V$conca + @vcolumn_name+'+'
		set @v$values = @v$values+' '+
		case @datatype when '[xml]' then 
		'''convert(xml,convert(varbinary(max),0x'''+@values_datatype+''', 2),2)'''
		else @values_datatype end+'+'',''+'
	fetch next from @col into @column_name , @vcolumn_name, @datatype, @values_datatype
	end
	close @col
	deallocate @col

	set @V$declare = substring(@V$declare, 1, len(@V$declare)-1)
	set @V$select = substring(@V$select, 1, len(@V$select)-1)
	set @V$variables = substring(@V$variables,1,len(@V$variables)-1)
	set @V$variables_cursor = substring(@V$variables_cursor,1,len(@V$variables_cursor)-1)
	set @V$insert_columns = substring(@V$insert_columns,1,len(@V$insert_columns)-1)
	set @V$conca = substring(@V$conca,1,len(@V$conca)-1)
	set @v$values = substring(@v$values, 1, len(@v$values)-3)
	
	declare @sql varchar(max)
	set @sql = 'declare 
	'+@V$declare+'
	declare CURSOR_COLUMN cursor fast_forward
	for
	select '+@V$select+'
	from '+case @migrated_to when 'MS SQL Server' then @table else replace(replace(@table,']',''),'[','') end+'
	'+case when isnull(@where_records_condition,'default') = 'default' then '' else @where_records_condition end+' 
	open CURSOR_COLUMN
	fetch next from CURSOR_COLUMN into '+@V$variables_cursor+'
	while @@fetch_status = 0
	begin
		Select ''insert into '+
		case @migrated_to when 'MS SQL Server' 
		then 
			case 
				when @new_name = 'default' or replace(replace(@new_name,']',''),'[','') = replace(replace(@table,']',''),'[','') then 
					@table
				else 
					@new_name 
			end
		else 
			case 
				when @new_name = 'default' or replace(replace(@new_name,']',''),'[','') = replace(replace(@table,']',''),'[','') then 
					replace(replace(@table,']',''),'[','')
				else 
					replace(replace(@new_name,']',''),'[','') 
			end
		end+' ('+@V$insert_columns+') 
		values ('''+@V$values+');''
	fetch next from CURSOR_COLUMN into '+@V$variables_cursor+'
	end
	close CURSOR_COLUMN
	deallocate CURSOR_COLUMN'
	print(@sql)
	Insert Into @Result
	exec(@sql)
end

Select Output_Text [--]
from @Result 
where Row_no between ((@patch * @bulk) + 1) and ((@patch + 1) * @bulk)
order by Row_no

end
else
begin
print('This table does not exist, please re-enter the correct name with the schema name, like, dbo.table_name')
end
set nocount off

end
