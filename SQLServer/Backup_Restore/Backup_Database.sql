exec [master].[dbo].[Backup_Database]
@database_name	= 'BPMAINDB, BPWHATIFDB, CentralDWH, CENTRALCONTACT',
@backup_type	='f',
@full_path		= 'E:\MSSQL13.D2WFMUAT\MSSQL\Backup\',
@execution_type	= 2


go
CREATE Procedure [dbo].[Backup_Database](
@database_name	varchar(max),
@backup_type	varchar(1),
@full_path		varchar(2000) = '\\db-nfs-server\backup\',
@execution_type	int)
as
begin
 
declare 
@db_name           varchar(300), 
@sql               varchar(2000), 
@file_name         varchar(1000), 
@week_number       varchar(10), 
@backup_start      varchar(30), 
@date              varchar(10), 
@time              varchar(10), 
@ampm              varchar(2),
@diff_seq          varchar(5),
@log_seq           varchar(5)
 
declare backup_cursor cursor fast_forward
for
select ltrim(rtrim([value]))
from dbo.separator(@database_name,',')
order by id
 
set @date = replace(convert(varchar(10),convert(datetime, getdate(), 120), 120),'-','_')
set @time = replace(convert(varchar(5),convert(datetime, getdate(), 120), 108),':','_')
set @ampm = case when cast(substring(@time, 1, 2) as int) < 12 then 'AM' else 'PM' end
set @file_name = case @backup_type 
when 'F' then @date+'__'+@time+'_'+@ampm+'__'+'Full'
when 'D' then @date+'__'+@time+'_'+@ampm+'__'+'Diff'
when 'L' then @date+'__'+@time+'_'+@ampm+'__'+'TLog'
end

--select @date, @time, @ampm, @file_name

open backup_cursor
fetch next from backup_cursor into @db_name
while @@fetch_status = 0
begin
 
set @sql = 'BACKUP '+case @backup_type 
when 'F' then 'DATABASE' 
when 'D' then 'DATABASE' 
when 'L' then 'LOG' end + ' ['+@db_name+'] 
TO  DISK = N'+''''+@full_path+@db_name+'_'+@file_name+'.bak'' 
WITH '+case @backup_type 
when 'F' then '' 
when 'L' then '' 
when 'D' then 'DIFFERENTIAL, ' end+ 'NOFORMAT, NOINIT,  
NAME = N'+''''+@db_name+'-'+case @backup_type 
when 'F' then 'Full'
when 'D' then 'Diff'
when 'L' then 'TLog'
end+' Database Backup'', SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10'
 
if @execution_type = 1
begin
exec(@sql)
end
else if @execution_type = 2
begin
print(@sql)
print(' ')
end
else if @execution_type = 3
begin
exec(@sql)
print(@sql)
print(' ')
end

fetch next from backup_cursor into @db_name
end
close backup_cursor
deallocate backup_cursor
 
end
GO
