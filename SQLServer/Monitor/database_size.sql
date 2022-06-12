Exec [master].[dbo].[database_size]
@databases	= '*',
@with_system	= 0,
@threshold_pct	= 85,
@volumes	= '*',
@where_size_gt  = 0,
@datafile	= '*',
@report		= 1


go
USE [master]
GO

CREATE Procedure [dbo].[database_size](
@databases		varchar(max) = '*',
@with_system	bit = 0,
@threshold_pct	int = 85,
@volumes		varchar(300) = '*',
@where_size_gt  int = 0,
@datafile		varchar(10) = '*',
@report			int = 1)
as
begin

declare @db varchar(1000), @vol varchar(300), @file_0 int, @file_1 int
declare @db_size table (id int identity(1,1), 
database_name varchar(300), file_type int, [file_id] int, logical_name varchar(1000), physical_name varchar(2000), 
size_n int, size varchar(50), growth_n int, growth varchar(50), used_n int, used varchar(50), free_n int, free varchar(50), max_size varchar(50))

if @databases = '*'
begin
	if @with_system = 0
	begin
		select @db = isnull(@db+', ','') + name from sys.databases where database_id > 4 order by name
	end
	else
	begin
		select @db = isnull(@db+', ','') + name from sys.databases order by name
	end
end
else
begin
	set @db = @databases
end


insert into @db_size (database_name, file_type, [file_id], logical_name, physical_name, size_n, size, growth_n, growth, used_n, used, free_n, free, max_size)
exec sp_MSforeachdb '
use [?]
select db_name(database_id), case type when 0 then 1 else 2 end file_type, file_id, name, physical_name, 
(cast(size as float) / cast(1024 as float)) * 8.0 size_,
master.dbo.numbersize((cast(size as float) / cast(1024 as float)) * 8.0,''mb'') size,
(cast(growth as float) / cast(1024 as float)) * 8.0 growth_,
master.dbo.numbersize((cast(growth as float)) * 8.0,''kb'') growth,
(cast(fileproperty(name, ''spaceused'') as float) / cast(1024 as float)) * 8.0 used_,
master.dbo.numbersize((cast(fileproperty(name, ''spaceused'') as float) / cast(1024 as float)) * 8.0 ,''Mb'') used_space,
(cast(size - fileproperty(name, ''spaceused'') as float) / cast(1024 as float)) * 8.0 free_,
master.dbo.numbersize((cast(size - fileproperty(name, ''spaceused'') as float) / cast(1024 as float)) * 8.0,''Mb'') free_space,
case when cast(max_size as float) = -1 then ''unlimited'' collate Arabic_100_CI_AS else master.dbo.numbersize((cast(max_size as float) / cast(1024 as float)) * 8.0,''Mb'') end max_size
from sys.master_files
where database_id = db_id() '


if @volumes = '*'
begin
	select @vol =  isnull(@vol+', ','') + volume_mount_point from (select distinct v.volume_mount_point from sys.master_files db cross apply sys.dm_os_volume_stats(db.database_id,db.file_id) v)a

end
else
begin
	set @vol = @volumes
end

if @datafile = 'data'
begin
set @file_0 = 1
set @file_1 = 1
end
else if @datafile = 'log'
begin
set @file_0 = 2
set @file_1 = 2
end
else if @datafile = '*'
begin
set @file_0 = 1
set @file_1 = 2
end

if @report in (1,2)
begin
select database_name, file_id, file_type, logical_name, volume, volume_total_size, volume_free_size, [threshold %], [volume_used %], [file % of disk], recommended_extend_size, total_dbf_size,
case when file_type = 2 then log_wait_reuse else '' end log_wait_reuse,
physical_name, size, growth, used, free, max_size,sum_file_id,
case when file_type = 2 and log_wait_reuse = 'NOTHING' then 'USE ['+database_name+']
DBCC SHRINKFILE (N'+''''+logical_name+''''+' , '+cast(used_n + 1024 as varchar(10)) +')' else '' end shrink_log
from (
select
id, database_name, db.log_reuse_wait_desc log_wait_reuse, used_n, file_type, s.[file_id], sum(s.file_id) over(partition by database_name order by database_name) sum_file_id, logical_name, 
volume_mount_point volume,
master.dbo.numbersize(total_bytes ,'byte') volume_total_size, 
master.dbo.numbersize(available_bytes ,'byte') volume_free_size, @threshold_pct [threshold %],
cast(100 - cast(available_bytes as float)/cast(total_bytes as float) * 100.0 as decimal(5,2)) [volume_used %],
cast((size_n / (total_bytes/1024.0/1024.0) * 100) as decimal(36,2)) [file % of disk], 
master.dbo.numbersize(case when cast(100 - cast(available_bytes as float)/cast(total_bytes as float) * 100.0 as decimal(5,2)) > @threshold_pct 
then total_bytes * (cast(100 - cast(available_bytes as float)/cast(total_bytes as float) * 100.0 as decimal(5,2)) - @threshold_pct) / 100 else 0 end ,'byte') 
recommended_extend_size,
master.dbo.numbersize(sum(size_n) over(partition by database_name order by database_name),'MB') total_dbf_size,
sum(size_n) over(partition by database_name order by database_name) total_dbf_size_n,
physical_name, size, growth, used, free, max_size
from @db_size s cross apply sys.dm_os_volume_stats(db_id(database_name), [file_id]) v
inner join sys.databases db
on s.database_name = db.name
where database_name in (select ltrim(rtrim(value)) from master.dbo.Separator(@db,','))
and volume_mount_point in (select ltrim(rtrim(value)) from master.dbo.Separator(@vol,','))
and file_type between @file_0 and @file_1
)a
where total_dbf_size_n > @where_size_gt
order by total_dbf_size_n desc, database_name

end

if @report in (2,3)
begin
select distinct 
volume_mount_point volume,
master.dbo.numbersize(total_bytes ,'byte') volume_total_size, 
master.dbo.numbersize(available_bytes ,'byte') volume_free_size,
cast(100 - cast(available_bytes as float)/cast(total_bytes as float) * 100.0 as decimal(5,2)) [volume_used %], @threshold_pct  [threshold %],
master.dbo.numbersize(case when cast(100 - cast(available_bytes as float)/cast(total_bytes as float) * 100.0 as decimal(5,2)) > @threshold_pct 
then total_bytes * (cast(100 - cast(available_bytes as float)/cast(total_bytes as float) * 100.0 as decimal(5,2)) - @threshold_pct) / 100 else 0 end ,'byte') 
recommended_extend_size
from @db_size s cross apply sys.dm_os_volume_stats(db_id(database_name), [file_id]) v
where volume_mount_point in (select ltrim(rtrim(value)) from master.dbo.Separator(@vol,','))
order by volume
end

end

