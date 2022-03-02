--This script allow you to have a physical file for each YEAR and for each day a single partition

declare 
@year_f 	int = 2005, 
@year_t 	int = 2025,
@db_name 	varchar(300) = 'Data_Hub_Cortex_Years', 
@filegroup_name varchar(100) = 'DH_Cortex',
@files_location varchar(300) = 'E:\Data_Hub_Cortex_Years\Partition_DB_Files'

declare 
@loop 		int = @year_f, 
@sql 		varchar(max),
@datestart 	datetime, 
@dateend 	datetime, 
@number 	int = 0

select @datestart = convert(datetime,cast(@year_f as varchar)+'-01-01',121)
select @dateend = convert(datetime,convert(varchar(10),dateadd(s,-1,convert(datetime,cast(@year_t+1 as varchar)+'-01-01',121)),121),121)

set nocount on

if right(@files_location,1) != '\' 
begin
set @files_location = @files_location+'\'
end

while @loop between @year_f and @year_t
begin 
set @sql= '
Use ['+@db_name+']
Alter Database ['+@db_name+'] Add Filegroup '+@filegroup_name+'_'+cast(@loop as varchar(10))+';
Alter Database ['+@db_name+'] Add File (name='''+@filegroup_name+'_'+cast(@loop as varchar(10))+''', filename='''+@files_location+@filegroup_name+'_'+cast(@loop as varchar(10))+'.ndf'', size = 10mb, filegrowth= 128mb, maxsize=unlimited) 
To Filegroup '+@filegroup_name+'_'+cast(@loop as varchar(10))+';'

--select @sql
exec(@sql)
set @loop = @loop + 1
end

set @sql = null
set @number = 0
while dateadd(day,@number,convert(datetime,cast(@year_f as varchar)+'-01-01',121)) between @datestart and @dateend
begin
	set @sql = isnull(@sql+',',' ')+'N'+''''+convert(varchar(30),dateadd(day,@number, @datestart),121)+'''' 
	+ case when (@number +1) % 8 = 0 then char(13) else '' end
	set @number = @number + 1
end
select @sql = '
Use ['+@db_name+']
CREATE PARTITION FUNCTION [pf_datetime_daily] (datetime) AS RANGE RIGHT FOR VALUES (
'+@sql+')'

--select @sql
--print(@sql)
exec(@sql)

set @sql = null
set @number = 0
while dateadd(day,@number,convert(datetime,cast(@year_f as varchar)+'-01-01',121)) between @datestart and @dateend
begin
	set @sql = isnull(@sql+',',' ')+'['+@filegroup_name+'_'+cast(year(convert(varchar(30),dateadd(day,@number, @datestart),121)) as varchar)+']'
	+ case when (@number +1) % 12 = 0 then char(13) else '' end
	set @number = @number + 1
end
select @sql = '
Use ['+@db_name+']
CREATE PARTITION SCHEME [ps_datetime_daily] AS PARTITION [pf_datetime_daily] TO ([PRIMARY],
'+@sql+')'

--select @sql
--print(@sql)
exec(@sql)

set nocount off


GO
CREATE TABLE [dbo].[FactSales_by_year_days](
	[DateId] [int] NOT NULL,
	[ArticleId] [int] NOT NULL,
	[BranchId] [int] NOT NULL,
	[OrderId] [int] NOT NULL,
	[Quantity] [decimal](9, 3) NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[Amount] [money] NOT NULL,
	[DiscountPcnt] [decimal](6, 3) NOT NULL,
	[DiscountAmt] [money] NOT NULL,
	[TaxAmt] [money] NOT NULL,
	[ADate] [datetime] NOT NULL,
 CONSTRAINT [PK_FactSales_pbyd] PRIMARY KEY CLUSTERED 
([DateId],[ArticleId],[BranchId],[OrderId],[ADate])) on ps_datetime_daily([ADate]) 
GO

select '['+schema_name(schema_id)+'].['+t.name+']' table_name, 
index_id, case when fg.name != 'PRIMARY' then partition_number - 1 else partition_number end partition_number, 
master.dbo.format(rows,-1) rows, fg.name [filegroup_name], 
dateadd(day, 
row_number() over(partition by fg.name order by partition_number) - 1, 
reverse(substring(reverse(fg.name), 1, charindex('_',reverse(fg.name))-1))+'-01-01') partition_function_Range
from sys.partitions p inner join sys.allocation_units a
on (a.type in (1,3) and a.container_id = p.partition_id)
or (a.type in (2) and a.container_id = p.hobt_id)
inner join sys.filegroups fg 
on a.data_space_id = fg.data_space_id
inner join sys.tables t
on p.object_id = t.object_id
where p.object_id in (object_id('[dbo].[FactSales_by_year_days]'))
and fg.name != 'PRIMARY'
order by partition_number

