--This script allow you to have a physical file for each YEAR and for each day a single partition

declare @year_f int = 2005, @year_t int = 2025
declare @db_name varchar(300) = 'Data_Hub_Cortex', @filegroup_name varchar(100) = 'DH_Cortex'
declare @loop int = @year_f, @sql varchar(max)
declare @datestart datetime, @dateend datetime, @x int = 0
select @datestart = convert(datetime,cast(@year_f as varchar)+'-01-01',121)
select @dateend = convert(datetime,convert(varchar(10),dateadd(s,-1,convert(datetime,cast(@year_t+1 as varchar)+'-01-01',121)),121),121)

while @loop between @year_f and @year_t
begin 
set @sql= '
alter database ['+@db_name+'] add filegroup '+@filegroup_name+'_'+cast(@loop as varchar(10))+';
alter database ['+@db_name+'] add file (name='''+@filegroup_name+'_'+cast(@loop as varchar(10))+''', filename=''C:\dataFiles\'+@filegroup_name+'_'+cast(@loop as varchar(10))+'.ndf'', size = 10mb, filegrowth= 128mb, maxsize=unlimited) 
to filegroup '+@filegroup_name+'_'+cast(@loop as varchar(10))+';'
--select @sql
exec(@sql)
set @loop = @loop + 1
end

set @sql = ''
set @x = 0
while dateadd(day,@x,convert(datetime,cast(@year_f as varchar)+'-01-01',121)) between @datestart and @dateend
begin
	set @sql = isnull(@sql+',',' ')+'N'+''''+convert(varchar(30),dateadd(day,@x, @datestart),121)+'''' + case when (@x +1) % 8 = 0 then char(13) else '' end
	set @x = @x + 1
end
select @sql = 'CREATE PARTITION FUNCTION pf_datetime_daily(datetime) AS RANGE RIGHT FOR VALUES (
'+@sql+')'

--select @sql
--print(@sql)
exec(@sql)

set @sql = ''
set @x = 0
while dateadd(day,@x,convert(datetime,cast(@year_f as varchar)+'-01-01',121)) between @datestart and @dateend
begin
	set @sql = isnull(@sql+',',' ')+'['+@filegroup_name+'_'+cast(year(convert(varchar(30),dateadd(day,@x, @datestart),121)) as varchar)+']'
	+ case when (@x +1) % 12 = 0 then char(13) else '' end
	set @x = @x + 1
end
select @sql = 'CREATE PARTITION SCHEME ps_datetime_daily TO ([PRIMARY],
'+@sql+')'

--select @sql
--print(@sql)
exec(@sql)

