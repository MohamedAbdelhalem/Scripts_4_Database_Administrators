--select * from sys.dm_db_file_space_usage
select db_name(ius.database_id) database_name, object_name(ius.object_id) object_name, idx.name, idx.type_desc, 
ius.user_scans, ius.user_seeks, ius.user_lookups, ius.user_updates, last_user_scan, last_user_seek, last_user_lookup, last_user_update 
from sys.dm_db_index_usage_stats ius inner join sys.indexes idx
on ius.object_id = idx.object_id
and ius.index_id = idx.index_id
where database_id = db_id()
--where database_id > 4
order by database_id, user_seeks desc


--select * from sys.dm_db_xtp_index_stats
