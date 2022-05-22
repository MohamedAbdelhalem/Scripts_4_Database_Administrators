declare 
@databases		varchar(max) = 'tempdb',
@threshold_pct	int = 93

declare @db_size table (id int identity(1,1), 
database_name varchar(300), [file_id] int, logical_name varchar(1000), physical_name varchar(2000), 
size_n int, size varchar(50), growth_n int, growth varchar(50), used_n int, used varchar(50), free_n int, free varchar(50), max_size varchar(50))

insert into @db_size (database_name, [file_id], logical_name, physical_name, size_n, size, growth_n, growth, used_n, used, free_n, free, max_size)
exec sp_MSforeachdb '
use [?]
select db_name(database_id), file_id, name, physical_name, 
(cast(size as float) / cast(1024 as float)) * 8.0 size_,
master.dbo.numbersize((cast(size as float) / cast(1024 as float)) * 8.0,''Mb'') size,
(cast(growth as float) / cast(1024 as float)) * 8.0 growth_,
master.dbo.numbersize((cast(growth as float) / cast(1024 as float)) * 8.0,''Mb'') growth,
(cast(fileproperty(name, ''spaceused'') as float) / cast(1024 as float)) * 8.0 used_,
master.dbo.numbersize((cast(fileproperty(name, ''spaceused'') as float) / cast(1024 as float)) * 8.0 ,''Mb'') used_space,
(cast(size - fileproperty(name, ''spaceused'') as float) / cast(1024 as float)) * 8.0 free_,
master.dbo.numbersize((cast(size - fileproperty(name, ''spaceused'') as float) / cast(1024 as float)) * 8.0,''Mb'') free_space,
case when cast(max_size as float) = -1 then ''unlimited'' collate Arabic_100_CI_AS else master.dbo.numbersize((cast(max_size as float) / cast(1024 as float)) * 8.0,''Mb'') end max_size
from sys.master_files
where database_id = db_id() '

select
id, database_name, s.[file_id], logical_name, 
volume_mount_point volume,
master.dbo.numbersize(total_bytes ,'byte') volume_total_size, 
master.dbo.numbersize(available_bytes ,'byte') volume_free_size,
cast(100 - cast(available_bytes as float)/cast(total_bytes as float) * 100.0 as decimal(5,2)) volume_used_pct,
cast((size_n / (total_bytes/1024.0/1024.0) * 100) as decimal(36,2)) file_pct_from_disk, 
master.dbo.numbersize(case when cast(100 - cast(available_bytes as float)/cast(total_bytes as float) * 100.0 as decimal(5,2)) > @threshold_pct 
then total_bytes * (cast(100 - cast(available_bytes as float)/cast(total_bytes as float) * 100.0 as decimal(5,2)) - @threshold_pct) / 100 else 0 end ,'byte') 
recommended_extend_size,
physical_name, size, growth, used, free, max_size,
master.dbo.numbersize(sum(size_n) over(),'MB') total_size, 
master.dbo.numbersize(sum(used_n) over(),'MB') total_used,
master.dbo.numbersize(sum(free_n) over(),'MB') total_free
from @db_size s cross apply sys.dm_os_volume_stats(db_id(database_name), [file_id]) v
where db_id(database_name) not in (1,3,4)
and database_name in (select ltrim(rtrim(value)) from master.dbo.Separator(@databases,','))
--and volume_mount_point in ('T:\')
--and growth != '0 MB'--
--and s.[file_id] = 2
--where database_name = 'BABmfreportsdbPROD'
--F:\
--D:\
--I:\
--J:\
--E:\
--G:\
--C:\
--and s.file_id = 2
order by file_pct_from_disk desc 

--select db_name(database_id), * from sys.master_files

--select distinct 
--volume_mount_point volume,
--master.dbo.numbersize(total_bytes ,'byte') volume_total_size, 
--master.dbo.numbersize(available_bytes ,'byte') volume_free_size,
--cast(100 - cast(available_bytes as float)/cast(total_bytes as float) * 100.0 as decimal(5,2)) volume_used_pct,
--master.dbo.numbersize(case when cast(100 - cast(available_bytes as float)/cast(total_bytes as float) * 100.0 as decimal(5,2)) > @threshold_pct 
--then total_bytes * (cast(100 - cast(available_bytes as float)/cast(total_bytes as float) * 100.0 as decimal(5,2)) - @threshold_pct) / 100 else 0 end ,'byte') 
--recommended_extend_size
--from @db_size s cross apply sys.dm_os_volume_stats(db_id(database_name), [file_id]) v
--where volume_mount_point not in ('M:\','N:\')
--order by volume
