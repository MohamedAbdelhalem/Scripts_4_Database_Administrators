USE [Bak_Config]
GO

--the switch on and off for primary or secondary backup preferences
CREATE TABLE [dbo].[Backup_Preferences](
	[is_primary] [bit] NULL
)
GO

CREATE TABLE [dbo].[Excluded_Databases](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Database_name] [varchar](150) NULL,
	[backup_types] [varchar](10) NULL
)
GO

--log and status table
CREATE TABLE [dbo].[config](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[backup_start] [datetime] NULL,
	[backup_end] [datetime] NULL,
	[week_number] [int] NULL,
	[year] [int] NULL,
	[backup_type] [varchar](1) NULL,
	[Diff_sequence_number] [int] NULL,
	[Log_sequence_number] [int] NULL,
	[status] [int] NULL,
	[tlog_disable_time] [datetime] NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[config] ADD  DEFAULT (getdate()) FOR [backup_start]
GO

ALTER TABLE [dbo].[config] ADD  DEFAULT ((0)) FOR [status]
GO

CREATE SEQUENCE [dbo].[diff_seq] 
AS [bigint]
START WITH 1
INCREMENT BY 1
MINVALUE -9223372036854775808
MAXVALUE 9223372036854775807
CACHE 
GO

CREATE SEQUENCE [dbo].[log_seq] 
AS [bigint]
START WITH 1
INCREMENT BY 1
MINVALUE -9223372036854775808
MAXVALUE 9223372036854775807
CACHE 
GO

CREATE Procedure [dbo].[Backup_Database_v03](
@backup_type varchar(1),
@server_type int,
@full_path varchar(2000) = '\\10.13.32.51\SharedBackup\')
as
begin

declare 
@db_name		varchar(300), 
@sql			varchar(2000), 
@file_name		varchar(1000), 
@week_number	varchar(10), 
@backup_start	varchar(30), 
@date			varchar(10), 
@time			varchar(10), 
@ampm			varchar(2),
@diff_seq		varchar(5),
@log_seq 		varchar(5),
@isPrimary		int

select 
@isPrimary = isnull(primary_recovery_health,0)
from sys.dm_hadr_availability_replica_cluster_nodes n left outer join sys.dm_hadr_availability_group_states g
on g.primary_replica = n.replica_server_name
where n.replica_server_name in (select name from sys.servers where server_id = 0)

print('is it a primary? = '+cast(@isPrimary as varchar(10)))

if @isPrimary = @server_type
begin

declare backup_cursor cursor fast_forward
for
select database_name
from sys.dm_hadr_database_replica_cluster_states dbrc inner join sys.dm_hadr_database_replica_states dbr
on dbrc.replica_id = dbr.replica_id
and dbrc.group_database_id = dbr.group_database_id
inner join sys.dm_hadr_availability_replica_states ar
on dbrc.replica_id = ar.replica_id
and dbr.replica_id = ar.replica_id
where is_failover_ready = 1
and is_pending_secondary_suspend = 0
and is_database_joined = 1
and dbr.synchronization_health = 2
and dbr.is_primary_replica = @server_type
and db_id(database_name) > 4
and database_name not in ('AdventureWorks2017','Bak_Config')
order by database_name

select 
@week_number  = case when len(week_number) = 1 then '0'+cast(week_number as varchar) else cast(week_number as varchar) end, 
@backup_start = backup_start,
@diff_seq = case when len(Diff_sequence_number) = 1 then '0'+cast(Diff_sequence_number as varchar) else cast(Diff_sequence_number as varchar) end,
@log_seq =  case when len(Log_sequence_number) = 1 then '0'+cast(Log_sequence_number as varchar) else cast(Log_sequence_number as varchar) end
from Bak_Config.dbo.config
where backup_type = @backup_type
and status = 0

set @date = replace(convert(varchar(10),convert(datetime, @backup_start, 120), 120),'-','_')
set @time = replace(convert(varchar(5),convert(datetime, @backup_start, 120), 108),':','_')
set @ampm = case when cast(substring(@time, 1, 2) as int) < 12 then 'AM' else 'PM' end
set @file_name = case @backup_type 
when 'F' then @date+'__'+@time+'_'+@ampm+'__Full_'+@week_number
when 'D' then @date+'__'+@time+'_'+@ampm+'__Full_'+@week_number+'__Diff_'+isnull(@diff_seq,'0')
when 'L' then @date+'__'+@time+'_'+@ampm+'__Full_'+@week_number+'__Diff_'+isnull(@diff_seq,'0')+'__TLog_'+@log_seq
end

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
when 'L' then 'LOG' end+ ' Database Backup'', SKIP, NOREWIND, NOUNLOAD, COMPRESSION, '+
case when @server_type = 0 and @backup_type in ('F','D') then 'COPY_ONLY, ' else '' end+ 
'STATS = 10'

exec (@sql)
print(@sql)
print(' ')

fetch next from backup_cursor into @db_name
end
close backup_cursor
deallocate backup_cursor

end
end

GO

CREATE Procedure [dbo].[Backup_Database](
@database_name varchar(max),
@backup_type varchar(1),
@full_path varchar(2000) = '\\db-nfs-server\backup\')
as
begin

declare 
@db_name		varchar(300), 
@sql			varchar(2000), 
@file_name		varchar(1000), 
@week_number	varchar(10), 
@backup_start	varchar(30), 
@date			varchar(10), 
@time			varchar(10), 
@ampm			varchar(2),
@diff_seq		varchar(5),
@log_seq 		varchar(5)

declare backup_cursor cursor fast_forward
for
select Database_name
from Excluded_Databases
where backup_types = @backup_type
order by Database_name

select 
@week_number  = case when len(week_number) = 1 then '0'+cast(week_number as varchar) else cast(week_number as varchar) end, 
@backup_start = backup_start,
@diff_seq = case when len(Diff_sequence_number) = 1 then '0'+cast(Diff_sequence_number as varchar) else cast(Diff_sequence_number as varchar) end,
@log_seq =  case when len(Log_sequence_number) = 1 then '0'+cast(Log_sequence_number as varchar) else cast(Log_sequence_number as varchar) end
from Bak_Config.dbo.config
where backup_type = @backup_type
and status = 0

set @date = replace(convert(varchar(10),convert(datetime, @backup_start, 120), 120),'-','_')
set @time = replace(convert(varchar(5),convert(datetime, @backup_start, 120), 108),':','_')
set @ampm = case when cast(substring(@time, 1, 2) as int) < 12 then 'AM' else 'PM' end
set @file_name = case @backup_type 
when 'F' then @date+'__'+@time+'_'+@ampm+'__Full_'+@week_number
when 'D' then @date+'__'+@time+'_'+@ampm+'__Full_'+@week_number+'__Diff_'+@diff_seq
when 'L' then @date+'__'+@time+'_'+@ampm+'__Full_'+@week_number+'__Diff_'+@diff_seq+'__TLog_'+@log_seq
end

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
NAME = N'+''''+@db_name+'-Full Database Backup'', SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10'

select  case @backup_type 
when 'F' then 'DATABASE' 
when 'D' then 'DATABASE' 
when 'L' then 'LOG' end , ' ['+@db_name+']', @full_path,@db_name,@file_name,
case @backup_type 
when 'F' then '' 
when 'L' then '' 
when 'D' then 'DIFFERENTIAL, ' end,@db_name


exec (@sql)
print(@sql)
print(' ')

fetch next from backup_cursor into @db_name
end
close backup_cursor
deallocate backup_cursor

end
GO

CREATE procedure [dbo].[Delete_Expired_Backup_v02]
(@backup_type	varchar(1),
@full_path		varchar(1000) = '\\10.13.32.51\SharedBackup\')
as
begin

declare @xp_cmdshell varchar(1000), @sql varchar(1000), @file_name varchar(1000), @max_full varchar(2), @max_diff varchar(2), @max_tlog varchar(2)
declare @files table (output_text varchar(1000))
declare @backup_files_type table (file_name varchar(1000))
declare @Backup_files_details table (database_name varchar(300), type varchar(5), backup_date datetime,backup_week int, backup_file_name varchar(2000), backup_file_tree varchar(50))

set nocount on

set @xp_cmdshell = 'xp_cmdshell ''dir cd '+@full_path+''''

insert into @files
exec (@xp_cmdshell)

insert into @Backup_files_details
select database_name, type, backup_date, datepart(week,backup_date) backup_week, backup_file_name, backup_file_tree
from ( 
select database_name, type, 
dateadd(hour, - case right(backup_date,2) when 'AM' then 0 else 12 end,replace(left(left(backup_date,17), 10),'_','-')+' '+
replace(substring(backup_date,13,5),'_',':')+':00') backup_date, 
backup_file_name, --part2, 
replace(replace(replace(part2,'Full_',''),'__Diff_','.'),'__TLog_','.') backup_file_tree
from (
select backup_file_name,  
case 
when part2 not like '%Diff%' then 'Full' 
when part2 not like '%Tlog%' then 'Diff' 
else 'TLog' end type,
reverse(substring(reverse(part1),1, 20)) backup_date, 
reverse(substring(reverse(part1),22, len(part1))) database_name,
substring(ltrim(rtrim(part2)),1,len(ltrim(rtrim(part2)))-4) part2
from (
select backup_file_name, 
substring(backup_file_name, 1,charindex('M__F',backup_file_name)) part1,
substring(backup_file_name, charindex('M__F',backup_file_name)+3, len(backup_file_name)) part2
from (
select substring(output_text, charindex(' ',output_text)+1, len(output_text)) backup_file_name
from (
select ltrim(substring(output_text, charindex('M  ',output_text)+1, len(output_text))) output_text
from @files
where output_text like '%M  %'
and output_text not like '%<DIR>%')a)b)c)d)e
order by database_name, backup_date, backup_file_tree

IF @backup_type = 'F'
begin
Insert into @backup_files_type
select backup_file_name 
from @Backup_files_details
where backup_file_tree != case 
when len(datepart(week,getdate())) = 1 then '0'+cast(datepart(week,getdate()) as varchar) 
else cast(datepart(week,getdate()) as varchar) end

end
else if @backup_type = 'D'
begin
insert into @backup_files_type
select backup_file_name  
from @Backup_files_details
where type in ('diff','tlog')
and backup_file_tree not in ( select max(backup_file_tree) from @Backup_files_details where type in ('diff')) 
end

declare delete_curosr cursor fast_forward
for
select file_name from @backup_files_type

open delete_curosr
fetch next from delete_curosr into @file_name
while @@fetch_status = 0
begin

set @xp_cmdshell = 'xp_cmdshell ''del "'+@full_path+@file_name+'"'+''''
exec (@xp_cmdshell)
print(@xp_cmdshell)

fetch next from delete_curosr into @file_name
end
close delete_curosr
deallocate delete_curosr
set nocount off
end

GO

CREATE procedure [dbo].[sp_change_job_schedule_v02]
(@job_name varchar(350), @start datetime, @end datetime)
as
begin
declare @server_number int

declare 
@start_date		varchar(20),
@start_time		varchar(20),
@end_time		varchar(20),
@id				int,
@remote_id_1	int,
@remote_id_2	int

select @server_number = case left(reverse(substring(name,1,charindex('\', name)-1)),1) when 2 then 1 when 4 then 2 end
from sys.servers
where server_id = 0

set @start_date = replace(convert(varchar(10), @start, 120),'-','')
set @start_time = cast(cast(replace(convert(varchar(10),@start, 108),':','') as int) as varchar(10))
set @end_time   = cast(cast(replace(convert(varchar(10),  @end, 108),':','') as int) as varchar(10))

select @id = schedule_id
from msdb.dbo.sysjobschedules sch inner join msdb.dbo.sysjobs j
on sch.job_id = j.job_id
where name = @job_name

if @server_number = 3
begin
print('server_numer 3')
end
else if @server_number = 2
begin
	select @remote_id_1 = schedule_id
	from [RACPRDTSPOTFIR2\AVGINST].msdb.dbo.sysjobschedules sch inner join [RACPRDTSPOTFIR2\AVGINST].msdb.dbo.sysjobs j
	on sch.job_id = j.job_id
	where name = @job_name
end
else if @server_number = 1
begin
	select @remote_id_1 = schedule_id
	from [RACPRDTSPOTFIR4\AVGINST].msdb.dbo.sysjobschedules sch inner join [RACPRDTSPOTFIR4\AVGINST].msdb.dbo.sysjobs j
	on sch.job_id = j.job_id
	where name = @job_name

end

exec msdb..sp_update_schedule   
@schedule_id = @id,   
@active_start_date = @start_date,
@active_start_time = @start_time,
@active_end_time = @end_time

if @server_number = 2
begin
exec [RACPRDTSPOTFIR2\AVGINST].msdb..sp_update_schedule   
@schedule_id = @remote_id_1,   
@active_start_date = @start_date,
@active_start_time = @start_time,
@active_end_time = @end_time

end
else if @server_number = 1
begin
exec [RACPRDTSPOTFIR4\AVGINST].msdb..sp_update_schedule   
@schedule_id = @remote_id_1,   
@active_start_date = @start_date,
@active_start_time = @start_time,
@active_end_time = @end_time

end

end	

GO

CREATE Procedure [dbo].[sp_jobs_control_v02]
(@jobs varchar(350) = 'All', @status bit)
as
begin
declare @server_number int
declare @schedule_id_table table (id int, location int, row_id int)
set nocount on

select @server_number = case left(reverse(substring(name,1,charindex('\', name)-1)),1) when 2 then 1 when 4 then 2 end
from sys.servers
where server_id = 0

if @jobs = 'All'
begin
	insert into @schedule_id_table
	select schedule_id, 0, 0
	from msdb.dbo.sysjobschedules sch inner join msdb.dbo.sysjobs j
	on sch.job_id = j.job_id
	where name in ('Differential_Backup','Transaction_Log_Backup')

	if @server_number = 3
	begin
	print('server number 3')
	select * from sys.servers

	end
	else if @server_number = 2
	begin
		insert into @schedule_id_table
		select schedule_id, 1, 1
		from [RACPRDTSPOTFIR2\AVGINST].msdb.dbo.sysjobschedules sch inner join [RACPRDTSPOTFIR2\AVGINST].msdb.dbo.sysjobs j
		on sch.job_id = j.job_id
		where name in ('Differential_Backup','Transaction_Log_Backup')

	end
	else if @server_number = 1
	begin
		insert into @schedule_id_table
		select schedule_id, 1, 1
		from [RACPRDTSPOTFIR4\AVGINST].msdb.dbo.sysjobschedules sch inner join [RACPRDTSPOTFIR4\AVGINST].msdb.dbo.sysjobs j
		on sch.job_id = j.job_id
		where name in ('Differential_Backup','Transaction_Log_Backup')

	end
end
else
begin
	insert into @schedule_id_table
	select schedule_id, 0, 0
	from msdb.dbo.sysjobschedules sch inner join msdb.dbo.sysjobs j
	on sch.job_id = j.job_id
	where name in (@jobs)

	if @server_number = 3
	begin
	print('server number 3')
	end
	else if @server_number = 2
	begin
		insert into @schedule_id_table
		select schedule_id, 1, 1
		from [RACPRDTSPOTFIR2\AVGINST].msdb.dbo.sysjobschedules sch inner join [RACPRDTSPOTFIR4\AVGINST].msdb.dbo.sysjobs j
		on sch.job_id = j.job_id
		where name in (@jobs)

	end
	else if @server_number = 1
	begin
		insert into @schedule_id_table
		select schedule_id, 1, 1
		from [RACPRDTSPOTFIR4\AVGINST].msdb.dbo.sysjobschedules sch inner join [RACPRDTSPOTFIR2\AVGINST].msdb.dbo.sysjobs j
		on sch.job_id = j.job_id
		where name in (@jobs)
	end
end

declare @id int, @location int, @row_id int
declare schedule_cursor cursor fast_forward
for
select id, location, row_id from @schedule_id_table

open schedule_cursor 
fetch next from schedule_cursor into @id, @location, @row_id
while @@FETCH_STATUS = 0
begin

if @location = 0
begin
	exec msdb..sp_update_schedule @schedule_id = @id, @enabled = @status
end
else
begin
	if @server_number = 2
	begin
			exec [RACPRDTSPOTFIR2\AVGINST].msdb..sp_update_schedule @schedule_id = @id, @enabled = @status
	end
	else if @server_number = 1
	begin
			exec [RACPRDTSPOTFIR4\AVGINST].msdb..sp_update_schedule @schedule_id = @id, @enabled = @status
	end
end

fetch next from schedule_cursor into @id, @location, @row_id
end
close schedule_cursor
deallocate schedule_cursor

set nocount off
end

GO

CREATE procedure [dbo].[Insert_into_config]
(@type varchar(5))
as
begin
if @type = 'F'
begin
insert into [Bak_Config].dbo.config (week_number, [year], backup_type, Diff_sequence_number, Log_sequence_number) 
values (datepart(week, getdate()), year(getdate()), @type, 0, 0)
end
else if @type = 'D'
begin
insert into [Bak_Config].[dbo].[config] (week_number, [year], backup_type, Diff_sequence_number, Log_sequence_number) 
values (datepart(week, getdate()), year(getdate()), @type, Next Value for diff_seq, 0)
end
else if @type = 'L'
begin
insert into config (week_number, [year], backup_type, Diff_sequence_number, Log_sequence_number) values 
(datepart(week, getdate()), year(getdate()), @type, cast((SELECT current_value FROM sys.sequences WHERE name = 'diff_seq') as int), Next Value for log_seq)
end
end

GO

CREATE procedure [dbo].[Reset_sequence] (@type int)
as
begin
if @type = 0
begin
alter sequence diff_seq restart
alter sequence log_seq restart
end
else if @type = 1
begin
alter sequence diff_seq restart
end
else if @type = 2
begin
alter sequence log_seq restart
end
end

GO

