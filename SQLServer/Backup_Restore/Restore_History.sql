select rh.restore_date, rh.destination_database_name, rh.restore_type, rh.replace, rh.stop_at, rh.stop_at_mark_name, rh.stop_before, bs.backup_start_date, bs.backup_finish_date, bs.backup_size,
bmf.physical_device_name
from restorehistory rh inner join backupset bs
on rh.backup_set_id = bs.backup_set_id
inner join backupmediafamily bmf
on bmf.media_set_id = bs.backup_set_id
where restore_date between '2022-04-08' and getdate()
