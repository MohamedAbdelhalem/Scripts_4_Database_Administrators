--This script allow you to have a physical file for each YEAR and for each day a single partition

declare 
@year_f 	int = 2015, 
@year_t 	int = 2020,
@db_name 	varchar(300) = 'Albilad', 
@filegroup_name varchar(100) = 'DH_Cortex',
@files_location varchar(300) = 'C:\dataFiles'

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
alter database ['+@db_name+'] add filegroup '+@filegroup_name+'_'+cast(@loop as varchar(10))+';
alter database ['+@db_name+'] add file (name='''+@filegroup_name+'_'+cast(@loop as varchar(10))+''', filename='''+@files_location+@filegroup_name+'_'+cast(@loop as varchar(10))+'.ndf'', size = 10mb, filegrowth= 128mb, maxsize=unlimited) 
to filegroup '+@filegroup_name+'_'+cast(@loop as varchar(10))+';'

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
select @sql = 'CREATE PARTITION FUNCTION [pf_datetime_daily] (datetime) AS RANGE RIGHT FOR VALUES (
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
select @sql = 'CREATE PARTITION SCHEME ps_datetime_daily AS PARTITION [pf_datetime_daily] TO ([PRIMARY],
'+@sql+')'

--select @sql
--print(@sql)
exec(@sql)

set nocount off
