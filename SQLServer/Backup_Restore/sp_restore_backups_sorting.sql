CREATE Procedure [dbo].[sp_restore_backups_sorting]
(
@db_name					varchar(500), 
@before_date				datetime,
@db_new_name				varchar(500)	= 'default',
@P_option_01				int				= 0,
@P_option_02				int				= 0,
@P_restore_loc				varchar(1000)	= 'default',
@P_option_03				int				= 0,
@P_restore_loc_data			varchar(1000)	= 'default',
@P_restore_loc_log			varchar(1000)	= 'default',
@P_option_04				int				= 0,
@P_number_of_files_per_type	varchar(100)	= 'default',
@P_restore_loction_groups	varchar(1500)	= 'default',
@P_percent					int				= 5,
@P_password					varchar(100)	= 'default',
@P_action					int				= 1
)
as
begin
declare 
@last_diff_finish_date		datetime,
@last_full_finish_date		datetime,
@backup_file_full_path		varchar(2500),
@backupType					int, 
@recovery					int, 
@log_number					int, 
@log_count					int, 
@LSN_match					int,
@loop						int = 1

set nocount on

create table #backup_files_headeronly (main_id int, typeid int,
	[DatabaseName] [nvarchar](512) NULL,
	[BackupType] [smallint] NULL,
	[BackupTypeDescription] [nvarchar](60) NULL,
	[FirstLSN] [numeric](25, 0) NULL,
	[LastLSN] [numeric](25, 0) NULL,
	[DatabaseBackupLSN] [numeric](25, 0) NULL,
	[DifferentialBaseLSN] [numeric](25, 0) NULL,
	[BackupStartDate] [datetime] NULL,
	[BackupFinishDate] [datetime] NULL,
	[backup_file_name] [varchar](1500) NULL,
	[backup_file_loc] [varchar](3000) NULL,
	[status] int default ((0)))

insert into #backup_files_headeronly 
select main_id,[type_id],
DatabaseName, BackupType, BackupTypeDescription, 
FirstLSN, LastLSN, DatabaseBackupLSN, DifferentialBaseLSN, BackupStartDate, BackupFinishDate,  backup_file_name, backup_file_loc, 0
from (
select
row_number() over(partition by DatabaseBackupLSN order by BackupStartDate desc) main_id, 
row_number() over(partition by backuptypedescription order by BackupStartDate desc) [type_id], 
* 
from (
select  
DatabaseName, BackupType, BackupTypeDescription, 
FirstLSN, LastLSN, case backupType when 1 then CheckpointLSN else DatabaseBackupLSN end DatabaseBackupLSN, DifferentialBaseLSN, BackupStartDate, BackupFinishDate, backup_file_name, backup_file_loc
from [dbo].[PDC_TO_SDC_HeaderOnly]
where DatabaseName = @db_name
and BackupTypeDescription in ('Database','database differential')
union all
select 
DatabaseName, BackupType, BackupTypeDescription, 
FirstLSN, LastLSN, case backupType when 1 then CheckpointLSN else DatabaseBackupLSN end DatabaseBackupLSN, DifferentialBaseLSN, BackupStartDate, BackupFinishDate, backup_file_name, backup_file_loc
from [dbo].[backup_files_headeronly]
where DatabaseName = @db_name
and BackupTypeDescription = 'Transaction Log')a
where BackupStartDate < @before_date
and DatabaseBackupLSN in (
							select top 1 DatabaseBackupLSN  
							from [dbo].[backup_files_headeronly] 
							where DatabaseName = @db_name
							and BackupTypeDescription = 'Transaction Log' 
							and BackupStartDate < @before_date
							order by BackupStartDate desc))b
order by main_id


select @last_diff_finish_date = BackupFinishDate from #backup_files_headeronly
where typeid in (select min(typeid) from #backup_files_headeronly where BackupType = 5)
and BackupType = 5

select @last_full_finish_date = BackupFinishDate from #backup_files_headeronly
where typeid in (select min(typeid) from #backup_files_headeronly where BackupType = 1)
and BackupType = 1

select top 1 @log_count = log_count, @LSN_match = LSN_match
from (
select main_id,typeid, id, DatabaseName, BackupType, BackupTypeDescription, FirstLSN, LastLSN, BackupStartDate, DatabaseBackupLSN, backup_file_name, backup_file_loc, count(*) over() log_count, sum(is_LSN_Match) over() LSN_match
from (
select a.main_id,a.typeid, a.id,a.DatabaseName, a.BackupType, a.BackupTypeDescription, a.FirstLSN, a.LastLSN, a.BackupStartDate, a.DatabaseBackupLSN, 
case when b.FirstLSN = a.LastLSN or b.id is null then 1 else 0 end is_LSN_match, a.backup_file_name, a.backup_file_loc
from 
 (select row_number() over(order by BackupStartDate) id, DatabaseName, BackupType, BackupTypeDescription, FirstLSN, LastLSN, BackupStartDate, BackupFinishDate, DatabaseBackupLSN, backup_file_name, backup_file_loc,main_id,typeid
from #backup_files_headeronly
where BackupStartDate > case when @last_diff_finish_date is null then @last_full_finish_date else @last_diff_finish_date end
and DatabaseName = @db_name)a
left outer join
 (select row_number() over(order by BackupStartDate) id, DatabaseName, BackupType, BackupTypeDescription, FirstLSN, LastLSN, BackupStartDate, BackupFinishDate, DatabaseBackupLSN, backup_file_name, backup_file_loc
from #backup_files_headeronly
where BackupStartDate > case when @last_diff_finish_date is null then @last_full_finish_date else @last_diff_finish_date end
and DatabaseName = @db_name)b
on a.id = b.id - 1)a)b

if @log_count = @LSN_match 
begin
	insert into #backup_files_headeronly 
	select main_id,[typeid],
	DatabaseName, BackupType, BackupTypeDescription, 
	FirstLSN, LastLSN, DatabaseBackupLSN, DifferentialBaseLSN, BackupStartDate, BackupFinishDate,  backup_file_name, backup_file_loc, 1
	from #backup_files_headeronly
	where typeid in (select max(typeid) from #backup_files_headeronly where BackupType = 1)
	and BackupType = 1

	insert into #backup_files_headeronly 
	select main_id,[typeid],
	DatabaseName, BackupType, BackupTypeDescription, 
	FirstLSN, LastLSN, DatabaseBackupLSN, DifferentialBaseLSN, BackupStartDate, BackupFinishDate,  backup_file_name, backup_file_loc, 1
	from #backup_files_headeronly
	where typeid in (select min(typeid) from #backup_files_headeronly where BackupType = 5)
	and BackupType = 5

-- is_LSN_match
	insert into #backup_files_headeronly 
	select main_id,[typeid],
	DatabaseName, BackupType, BackupTypeDescription, 
	FirstLSN, LastLSN, DatabaseBackupLSN, NULL, BackupStartDate, NULL,  backup_file_name, backup_file_loc, 1
	from (
	select main_id,typeid, id, DatabaseName, BackupType, BackupTypeDescription, FirstLSN, LastLSN, BackupStartDate, DatabaseBackupLSN, backup_file_name, backup_file_loc, count(*) over() log_count, sum(is_LSN_Match) over() LSN_match
	from (
	select a.main_id,a.typeid, a.id,a.DatabaseName, a.BackupType, a.BackupTypeDescription, a.FirstLSN, a.LastLSN, a.BackupStartDate, a.DatabaseBackupLSN, 
	case when b.FirstLSN = a.LastLSN or b.id is null then 1 else 0 end is_LSN_match, a.backup_file_name, a.backup_file_loc
	from 
	 (select row_number() over(order by BackupStartDate) id, DatabaseName, BackupType, BackupTypeDescription, FirstLSN, LastLSN, BackupStartDate, BackupFinishDate, DatabaseBackupLSN, backup_file_name, backup_file_loc,main_id,typeid
	from #backup_files_headeronly
	where BackupStartDate > case when @last_diff_finish_date is null then @last_full_finish_date else @last_diff_finish_date end
	and DatabaseName = @db_name)a
	left outer join
	 (select row_number() over(order by BackupStartDate) id, DatabaseName, BackupType, BackupTypeDescription, FirstLSN, LastLSN, BackupStartDate, BackupFinishDate, DatabaseBackupLSN, backup_file_name, backup_file_loc
	from #backup_files_headeronly
	where BackupStartDate > case when @last_diff_finish_date is null then @last_full_finish_date else @last_diff_finish_date end
	and DatabaseName = @db_name)b
	on a.id = b.id - 1)a)b
	where log_count = LSN_match
	order by id

	declare bak cursor fast_forward
	for
	select row_number() over(partition by BackupType order by main_id) log_number, BackupType, backup_file_loc+'\'+backup_file_name 
	from #backup_files_headeronly 
	where status = 1
	order by main_id desc

	open bak
	fetch next from bak into @log_number, @backupType, @backup_file_full_path
	while @@FETCH_STATUS = 0
	begin

	set @recovery = case 
	when abs(@log_number - @loop + 1) = @LSN_match and @backupType  = 2 then 1 
	when @log_number - @loop = @LSN_match and @backupType != 2 then 0 
	else 0 end

	exec [dbo].[sp_restore_database_distribution_groups]
	@backupfile					= @backup_file_full_path,
	@filenumber					= 'all', 
	@option_01					= @P_option_01,
	@option_02					= @P_option_02,
	@restore_loc				= @P_restore_loc,
	@option_03					= @P_option_03,
	@restore_loc_data			= @P_restore_loc_data,
	@restore_loc_log			= @P_restore_loc_log,
	@option_04					= @P_option_04,
	@number_of_files_per_type	= @P_number_of_files_per_type,
	@restore_loction_groups		= @P_restore_loction_groups,
	@with_recovery				= @recovery,
	@new_db_name				= @db_new_name,
	@percent					= @P_percent,
	@password					= @P_password,
	@action						= @P_action

	set @loop = @loop + 1
	fetch next from bak into @log_number, @backupType, @backup_file_full_path
	end
	close bak
	deallocate bak

end
else
begin
	print('Transaction log backup files have missmatch sequence, check the LSN for backup files.')
end
set nocount off
end

