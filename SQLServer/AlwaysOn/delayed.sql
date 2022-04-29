select ar.replica_server_name, db.name, synchronization_state_desc, synchronization_health_desc, database_state_desc, --suspend_reason_desc, 
master.dbo.numbersize(log_send_queue_size,'kb') log_send_queue_size, 
master.dbo.numbersize(redo_queue_size,'kb') redo_queue_size_not_yet,
master.dbo.duration(datediff(MS,last_sent_time, last_received_time)) latancy, 
master.dbo.duration(datediff(ms,last_redone_time,last_received_time)) delayed, last_redone_time,
last_commit_time, 
last_sent_time, 
last_received_time, 
last_hardened_time
from sys.dm_hadr_database_replica_states rs inner join sys.databases db 
on rs.database_id = db.database_id
inner join sys.availability_replicas ar
on ar.replica_id = rs.replica_id
where is_local = 1

