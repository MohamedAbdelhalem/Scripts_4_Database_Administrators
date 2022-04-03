use master
go
if exists (select name from sys.objects where name = 'NumberSize')
begin 
drop function [dbo].[numberSize]
end
go
CREATE function [dbo].[numberSize]
(@number numeric(20,2), @type varchar(1))
returns varchar(100)
as
begin
declare @return varchar(100), @B numeric, @K numeric, @M numeric, @G numeric, @T numeric
set @b = 1024
set @k = 1048576
set @m = 1073741824
set @g = 1099511627776
set @t = 1125899906842624

if @type = 'B'
select @return = 
case 
when @number between    0 and @B then cast(round(cast(@number as float)/1,2) as varchar)+' Bytes'
when @number between @b+0 and @K then cast(round(cast(@number as float)/1024,2) as varchar)+' KB'
when @number between @k+0 and @M then cast(round(cast(@number as float)/1024/1024,2) as varchar)+' MB'
when @number between @m+0 and @G then cast(round(cast(@number as float)/1024/1024/1024,2) as varchar)+' GB'
when @number between @g+0 and @T then cast(round(cast(@number as float)/1024/1024/1024/1024,2) as varchar)+' TB'
end

else if @type = 'K'
begin
select @return = 
case 
when @number between    0 and @B then cast(round(cast(@number as float)/1,2) as varchar)+' KB'
when @number between @b+0 and @K then cast(round(cast(@number as float)/1024,2) as varchar)+' MB'
when @number between @k+0 and @M then cast(round(cast(@number as float)/1024/1024,2) as varchar)+' GB'
when @number between @m+0 and @G then cast(round(cast(@number as float)/1024/1024/1024,2) as varchar)+' TB'
end
end

else if @type = 'M'
select @return = 
case 
when @number between    0 and @B then cast(round(cast(@number as float)/1,2) as varchar)+' MB'
when @number between @b+0 and @K then cast(round(cast(@number as float)/1024,2) as varchar)+' GB'
when @number between @k+0 and @M then cast(round(cast(@number as float)/1024/1024,2) as varchar)+' TB'
end

else if @type = 'G'
select @return = 
case 
when @number between    0 and @B then cast(round(cast(@number as float)/1,2) as varchar)+' GB'
when @number between @b+0 and @K then cast(round(cast(@number as float)/1024,2) as varchar)+' TB'
end

else if @type = 'T'
select @return = 
case 
when @number between    0 and @B then cast(round(cast(@number as float)/1,2) as varchar)+' TB'
end

return @return
end
go

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
master.dbo.numbersize(case when cast((available_bytes / (total_bytes/1024.0/1024.0) * 100) as decimal(36,2)) >= 90 then total_bytes * 25 / 100 + total_bytes
else 0 end ,'byte') recommended_extend_size,
master.dbo.numbersize(case when cast((available_bytes / (total_bytes/1024.0/1024.0) * 100) as decimal(36,2)) >= 90 then total_bytes * 25 / 100 
else 0 end ,'byte') requested_extend_size,
physical_name, size, growth, used, free, max_size,
master.dbo.numbersize(sum(size_n) over(),'MB') total_size, 
master.dbo.numbersize(sum(used_n) over(),'MB') total_used,
master.dbo.numbersize(sum(free_n) over(),'MB') total_free
from @db_size s cross apply sys.dm_os_volume_stats(db_id(database_name), [file_id]) v
--where database_name in ('Data_Hub_Voyager','')
--where db_id(database_id) > 4
--where volume_mount_point in ('h:\')
--and s.file_id = 2
order by size_n desc
--order by file_pct_from_disk desc
--dbcc opentran
--F:\ -- 91.74
--H:\ -- 4.05 TB  337.21 GB 91.84
--summary
--479.85 GB
select * from (
select
db_id(database_name) database_id, database_name, count(*) files, 
case when substring(right(physical_name,10),charindex('.',right(physical_name,10))+1,10) = 'ldf' then 'log' else 'data' end [type],  
master.dbo.numbersize(sum(size_n),'MB') database_size, sum(size_n) size_n
from @db_size 
group by database_name, case when substring(right(physical_name,10),charindex('.',right(physical_name,10))+1,10) = 'ldf' then 'log' else 'data' end)a
where database_id > 4
and [type] = 'data'
--and database_name = 'Data_Hub_Voyager'
--and database_name in ('Data_Hub_Cortex','BAB_MIS','Data_Hub_Voyager','Data_Hub_Siebel','Data_Hub_ODS','Data_Hub_MongoDB')
order by size_n desc, database_name



