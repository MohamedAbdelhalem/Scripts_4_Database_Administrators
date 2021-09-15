--Create 3 jobs in all instances (primary and secondary) the same
--and put those 3 procedures (Full, Differential, and Transaction log) for each job and name the jobs as it mentained.
--Full backup job is *Full_Backup_Database*
--Differential backup job is *Differential_Backup*
--Transaction Log backup job is *Transaction_Log_Backup*

CREATE PROCEDURE [dbo].[Full_Backup_Databases_step1]
as
begin

declare @is_primary int, @server_number int, @isPrimary bit
select @isPrimary = is_primary 
from Backup_Preferences

select @is_primary = case when name = (select Primary_replica from sys.dm_hadr_availability_group_states) then 1 else 0 end,
@server_number = case left(reverse(substring(name,1,charindex('\', name)-1)),1) when 2 then 1 when 4 then 2 end
from sys.servers
where server_id = 0

IF @is_primary = @isPrimary and @is_primary = 0
begin
	if @server_number = 2
	begin
		exec [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].[sp_jobs_control_v02] @status = 0
		exec [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].[Insert_into_config] @type = 'F'
		exec [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].[reset_sequence] @type = 0
	end
	if @server_number = 1
	begin
		exec [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].[sp_jobs_control_v02] @status = 0
		exec [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].[Insert_into_config] @type = 'F'
		exec [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].[reset_sequence] @type = 0
	end
waitfor delay '00:00:10'
end
else
begin
		exec [Bak_Config].[dbo].[sp_jobs_control_v02] @status = 0
		exec [Bak_Config].[dbo].[Insert_into_config] @type = 'F'
		exec [Bak_Config].[dbo].[reset_sequence] @type = 0
end
end

GO

CREATE PROCEDURE [dbo].[Full_Backup_Databases_step2]
as
begin

declare @is_primary int, @isPrimary bit
select @isPrimary = is_primary 
from Backup_Preferences
select @is_primary = case when name = (select Primary_replica from sys.dm_hadr_availability_group_states) then 1 else 0 end
from sys.servers
where server_id = 0

IF @is_primary = @isPrimary
begin
exec [dbo].[backup_database_v03] @backup_type = 'F', @server_type = @isPrimary

end
end

GO

CREATE PROCEDURE [dbo].[Full_Backup_Databases_step3]
as
begin
declare @is_primary int, @server_number int, @isPrimary bit
select @isPrimary = is_primary 
from Backup_Preferences
select @is_primary = case when name = (select Primary_replica from sys.dm_hadr_availability_group_states) then 1 else 0 end
from sys.servers
where server_id = 0

select @server_number = case left(reverse(substring(name,1,charindex('\', name)-1)),1) when 2 then 1 when 4 then 2 end
from sys.servers
where server_id = 0

IF @is_primary = @isPrimary and @is_primary = 0
begin
	if @server_number = 2
	begin
	update [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].[config] set 
	backup_end = getdate(), 
	status = 1
	where status = 0
	and backup_type = 'F'

	exec [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].[Delete_Expired_Backup_v02] @backup_type = 'F'
	exec [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].[sp_jobs_control_v02] @jobs = 'All', @status = 1
	end
	else if @server_number = 1
	begin
	update [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].[config] set 
	backup_end = getdate(), 
	status = 1
	where status = 0
	and backup_type = 'F'

	exec [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].[Delete_Expired_Backup_v02] @backup_type = 'F'
	exec [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].[sp_jobs_control_v02] @jobs = 'All', @status = 1
	end
end
else
	begin
	update [Bak_Config].[dbo].[config] set 
	backup_end = getdate(), 
	status = 1
	where status = 0
	and backup_type = 'F'

	exec [Bak_Config].[dbo].[Delete_Expired_Backup_v02] @backup_type = 'F'
	exec [Bak_Config].[dbo].[sp_jobs_control_v02] @jobs = 'All', @status = 1
end
	exec msdb.dbo.sp_start_job @job_name = 'Transaction_Log_Backup'
end

GO

CREATE PROCEDURE [dbo].[Differential_Backup_databases_step1]
as
begin
declare @is_primary int, @is_critical int, @server_number int, @isPrimary bit

select @isPrimary = is_primary 
from Backup_Preferences

select 
@is_primary = case when name = (select Primary_replica from sys.dm_hadr_availability_group_states) then 1 else 0 end,
@server_number = case left(reverse(substring(name,1,charindex('\', name)-1)),1) when 2 then 1 when 4 then 2 end
from sys.servers
where server_id = 0

select @is_critical =
case 
when datepart(WEEKDAY, getdate())  = 7 and getdate() < dateadd(hour, 19, convert(datetime,convert(date, getdate(),120),120)) 
then 0
when datepart(WEEKDAY, getdate())  < 7 
then 0 
else 1 end

IF @is_primary = @isPrimary and @is_critical = 0 and @is_primary = 0
begin
	if @server_number = 2
	begin
		exec [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].[sp_jobs_control_v02] @jobs = 'Transaction_Log_Backup', @status = 0
		exec [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].[Insert_into_Config] @type = 'D'
		exec [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].[reset_sequence] @type = 2
	end
	else if @server_number = 1
	begin
		exec [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].[sp_jobs_control_v02] @jobs = 'Transaction_Log_Backup', @status = 0
		exec [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].[Insert_into_Config] @type = 'D'
		exec [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].[reset_sequence] @type = 2
	end
waitfor delay '00:00:10'
end
else
begin
		exec [Bak_Config].[dbo].[sp_jobs_control_v02] @jobs = 'Transaction_Log_Backup', @status = 0
		exec [Bak_Config].[dbo].[Insert_into_Config] @type = 'D'
		exec [Bak_Config].[dbo].[reset_sequence] @type = 2
end
end

GO

CREATE PROCEDURE [dbo].[Differential_Backup_databases_step2]
as
begin
declare @is_primary int, @is_critical int, @isPrimary bit

select @isPrimary = is_primary 
from Backup_Preferences

select 
@is_primary = case when name = (select Primary_replica from sys.dm_hadr_availability_group_states) then 1 else 0 end
from sys.servers
where server_id = 0

select @is_critical =
case 
when datepart(WEEKDAY, getdate())  = 7 and getdate() < dateadd(hour, 19, convert(datetime,convert(date, getdate(),120),120)) 
then 0
when datepart(WEEKDAY, getdate())  < 7 
then 0 
else 1 end

IF @is_primary = @isPrimary and @is_critical = 0
begin
exec [dbo].[backup_database_v03] @backup_type = 'D', @server_type = @isPrimary
end

end

GO

CREATE PROCEDURE [dbo].[Differential_Backup_databases_step3]
as
begin
declare @is_primary int, @is_critical int, @server_number int, @isPrimary bit
declare @start_date datetime, @end_date datetime

select @isPrimary = is_primary 
from Backup_Preferences

select 
@is_primary = case when name = (select Primary_replica from sys.dm_hadr_availability_group_states) then 1 else 0 end,
@server_number = case left(reverse(substring(name,1,charindex('\', name)-1)),1) when 2 then 1 when 4 then 2 end
from sys.servers
where server_id = 0

select @is_critical =
case 
when datepart(WEEKDAY, getdate())  = 7 and getdate() < dateadd(hour, 19, convert(datetime,convert(date, getdate(),120),120)) 
then 0
when datepart(WEEKDAY, getdate())  < 7 
then 0 
else 1 end

IF @is_primary = @isPrimary and @is_critical = 0 and @is_primary = 0
begin
	if @server_number = 2
	begin
		update [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].config set 
		backup_end = getdate(), 
		status = 1
		where status = 0
		and backup_type = 'D'
	
		exec [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].[Delete_Expired_Backup_v02] @backup_type = 'D'

		select 
		@start_date = dateadd(minute, 15, backup_end),
		@end_date = dateadd(minute, 15 * 40, backup_end)
		from [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].[config]
		where backup_type = 'D'
		and status = 1
		and backup_start in (select max(backup_start) from (select backup_start, backup_type from config where backup_type = 'D')a)

		exec [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].[sp_change_job_schedule_v02] @job_name = 'Transaction_Log_Backup', @start = @start_date, @end = @end_date	
		exec [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].[sp_jobs_control_v02] @jobs = 'Transaction_Log_Backup', @status = 1
	end
	else if @server_number = 1
	begin
		update [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].config set 
		backup_end = getdate(), 
		status = 1
		where status = 0
		and backup_type = 'D'
	
		exec [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].[Delete_Expired_Backup_v02] @backup_type = 'D'

		select 
		@start_date = dateadd(minute, 15, backup_end),
		@end_date = dateadd(minute, 15 * 40, backup_end)
		from [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].[config]
		where backup_type = 'D'
		and status = 1
		and backup_start in (select max(backup_start) from (select backup_start, backup_type from config where backup_type = 'D')a)

		exec [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].[sp_change_job_schedule_v02] @job_name = 'Transaction_Log_Backup', @start = @start_date, @end = @end_date	
		exec [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].[sp_jobs_control_v02] @jobs = 'Transaction_Log_Backup', @status = 1
	end
end
else
begin
	update [Bak_Config].[dbo].config set 
	backup_end = getdate(), 
	status = 1
	where status = 0
	and backup_type = 'D'
	
	exec [Bak_Config].[dbo].[Delete_Expired_Backup_v02] @backup_type = 'D'

	select 
	@start_date = dateadd(minute, 15, backup_end),
	@end_date = dateadd(minute, 15 * 40, backup_end)
	from [Bak_Config].[dbo].[config]
	where backup_type = 'D'
	and status = 1
	and backup_start in (select max(backup_start) from (select backup_start, backup_type from config where backup_type = 'D')a)

	exec [Bak_Config].[dbo].[sp_change_job_schedule_v02] @job_name = 'Transaction_Log_Backup', @start = @start_date, @end = @end_date	
	exec [Bak_Config].[dbo].[sp_jobs_control_v02] @jobs = 'Transaction_Log_Backup', @status = 1
end
end

GO

CREATE PROCEDURE [dbo].[Transaction_Log_Backup_step1]
as
begin
declare @is_primary int, @is_critical int, @server_number int, @isPrimary bit
select @isPrimary = is_primary 
from Backup_Preferences

select 
@is_primary = case when name = (select Primary_replica from sys.dm_hadr_availability_group_states) then 1 else 0 end,
@server_number = case left(reverse(substring(name,1,charindex('\', name)-1)),1) when 2 then 1 when 4 then 2 end
from sys.servers
where server_id = 0

select @is_critical =
case 
when datepart(WEEKDAY, getdate())  = 7 and getdate() < dateadd(hour, 19, convert(datetime,convert(date, getdate(),120),120)) 
then 0
when datepart(WEEKDAY, getdate())  < 7 
then 0 
else 1 end

IF @is_primary = @isPrimary and @is_critical = 0 and @is_primary = 0
begin
	if @server_number = 2
	begin
		IF (select count(*) from [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].[config] where backup_type = 'L' and status = 0) = 0
		Begin
			exec [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].[Insert_into_Config] @type = 'L'
		End
	end
	else if @server_number = 1
	begin
		IF (select count(*) from [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].[config] where backup_type = 'L' and status = 0) = 0
		Begin
			exec [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].[Insert_into_Config] @type = 'L'
		End
	end
waitfor delay '00:00:10'
end
else
begin
	IF (select count(*) from [Bak_Config].[dbo].[config] where backup_type = 'L' and status = 0) = 0
	Begin
		exec [Bak_Config].[dbo].[Insert_into_Config] @type = 'L'
	End
end
end

GO

CREATE PROCEDURE [dbo].[Transaction_Log_Backup_step3]
as
begin
declare @is_primary int, @is_critical int, @server_number int, @isPrimary bit
select @isPrimary = is_primary 
from Backup_Preferences

select 
@is_primary = case when name = (select Primary_replica from sys.dm_hadr_availability_group_states) then 1 else 0 end,
@server_number = case left(reverse(substring(name,1,charindex('\', name)-1)),1) when 2 then 1 when 4 then 2 end
from sys.servers
where server_id = 0

select @is_critical =
case 
when datepart(WEEKDAY, getdate()) = 7 and getdate() < dateadd(minute, 15, dateadd(hour, 23, convert(datetime,convert(date, getdate(),120),120)))
then 0
when datepart(WEEKDAY, getdate())  < 7 
then 0 
else 1 end

IF @is_primary = @isPrimary and @is_critical = 0 and @is_primary = 0
begin
	IF 
	(select count(*) from config where backup_type = 'L' and status = 0) = 1 and
	(select count(*) from sys.dm_exec_requests where command = 'Backup Log') = 0
	Begin
		if @server_number = 2
		begin
			update [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].[config] set 
			backup_end = getdate(), 
			status = 1
			where status = 0
			and backup_type = 'L'
		end
		else if @server_number = 1
		begin
			update [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].[config] set 
			backup_end = getdate(), 
			status = 1
			where status = 0
			and backup_type = 'L'
		end
	end
End
else
begin
	IF 
	(select count(*) from config where backup_type = 'L' and status = 0) = 1 and
	(select count(*) from sys.dm_exec_requests where command = 'Backup Log') = 0
	Begin
			update [Bak_Config].[dbo].[config] set 
		backup_end = getdate(), 
		status = 1
		where status = 0
		and backup_type = 'L'
	end
end
end

GO

CREATE PROCEDURE [dbo].[Transaction_Log_Backup_step2]
as
begin

declare @is_primary int, @is_critical int, @isPrimary bit
select @isPrimary = is_primary 
from Backup_Preferences

select @is_primary = case when name = (select Primary_replica from sys.dm_hadr_availability_group_states) then 1 else 0 end
from sys.servers
where server_id = 0

select @is_critical =
case 
when datepart(WEEKDAY, getdate()) = 7 and getdate() < dateadd(minute, 15, dateadd(hour, 23, convert(datetime,convert(date, getdate(),120),120)))
then 0
when datepart(WEEKDAY, getdate())  < 7 
then 0 
else 1 end

IF @is_primary = @isPrimary and @is_critical = 0
begin
	IF 
	(select count(*) from config where backup_type = 'L' and status = 0) = 1 and
	(select count(*) from sys.dm_exec_requests where command = 'Backup Log') = 0
	Begin
		exec [dbo].[backup_database_v03] @backup_type = 'L', @server_type = @isPrimary
	End
end
end

GO

CREATE PROCEDURE [dbo].[Transaction_Log_Backup_step3]
as
begin
declare @is_primary int, @is_critical int, @server_number int, @isPrimary bit
select @isPrimary = is_primary 
from Backup_Preferences

select 
@is_primary = case when name = (select Primary_replica from sys.dm_hadr_availability_group_states) then 1 else 0 end,
@server_number = case left(reverse(substring(name,1,charindex('\', name)-1)),1) when 2 then 1 when 4 then 2 end
from sys.servers
where server_id = 0

select @is_critical =
case 
when datepart(WEEKDAY, getdate()) = 7 and getdate() < dateadd(minute, 15, dateadd(hour, 23, convert(datetime,convert(date, getdate(),120),120)))
then 0
when datepart(WEEKDAY, getdate())  < 7 
then 0 
else 1 end

IF @is_primary = @isPrimary and @is_critical = 0 and @is_primary = 0
begin
	IF 
	(select count(*) from config where backup_type = 'L' and status = 0) = 1 and
	(select count(*) from sys.dm_exec_requests where command = 'Backup Log') = 0
	Begin
		if @server_number = 2
		begin
			update [RACPRDTSPOTFIR2\AVGINST].[Bak_Config].[dbo].[config] set 
			backup_end = getdate(), 
			status = 1
			where status = 0
			and backup_type = 'L'
		end
		else if @server_number = 1
		begin
			update [RACPRDTSPOTFIR4\AVGINST].[Bak_Config].[dbo].[config] set 
			backup_end = getdate(), 
			status = 1
			where status = 0
			and backup_type = 'L'
		end
	end
End
else
begin
	IF 
	(select count(*) from config where backup_type = 'L' and status = 0) = 1 and
	(select count(*) from sys.dm_exec_requests where command = 'Backup Log') = 0
	Begin
			update [Bak_Config].[dbo].[config] set 
		backup_end = getdate(), 
		status = 1
		where status = 0
		and backup_type = 'L'
	end
end
end
