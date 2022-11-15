select top 1000 
* from (
select --top 10
database_name, 
case type 
when 'L' then 'Log'
when 'I' then 'Differential'
when 'D' then 'Full'
when 'F' then 'File or filegroup'
when 'G' then 'Differential file'
when 'P' then 'Partial'
when 'Q' then 'Differential partial'
else 'Others' end backup_type, 
backup_start_date, backup_finish_date, 
master.dbo.duration('s', datediff(s,backup_start_date,backup_finish_date)) backup_duration, 
is_damaged, is_force_offline,
server_name,
user_name, recovery_model, master.dbo.numbersize(backup_size,'byte') backup_size, 
master.dbo.numbersize(compressed_backup_size,'byte') backup_compressed_size , 
physical_device_name, case device_type 
when 2 then 'Disk' 
when 4 then 'Tape' 
when 7 then 'Virtual device' 
when 9 then 'Azure Storage' 
when 105  then 'A permanent backup device' 
end device_type
from msdb.dbo.backupset bs inner join msdb.dbo.backupmediafamily bmf
on bs.media_set_id = bmf.media_set_id)a
--where db_id(database_name) = db_id('SS_BAB_Dev_new')
--where backup_type = 'full'
where database_name = 'msdb'
and backup_type = 'full'
--and backup_start_date >= '2022-09-30 19:00:00.000'
--and backup_finish_date > convert(varchar(10), getdate(),120)
--order by backup_finish_date desc
order by backup_start_date desc


