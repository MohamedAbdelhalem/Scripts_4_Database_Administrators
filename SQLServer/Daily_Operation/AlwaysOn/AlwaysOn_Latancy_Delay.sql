select 
ar.replica_server_name, db.name [database_name], synchronization_state_desc, synchronization_health_desc, database_state_desc, 
master.dbo.numbersize(isnull(log_send_queue_size,0),'kb') log_send_queue_size, 
--master.dbo.numbersize(isnull(redo_queu.le_size,0),'kb') redo_queue_size_not_yet,
master.dbo.numbersize(isnull((isnull(log_send_queue_size,0) + isnull(redo_queue_size,0)),0),'kb') total_waiting_logs,
master.dbo.duration('ms', case when isnull(datediff(ms,last_redone_time,getdate()),0)			< 0 then 0 else isnull(datediff(ms,last_redone_time,getdate()),0)			end) last_redone_time,
case when isnull(datediff(s,last_sent_time,getdate()),0) < 60*60*1 then 'No Data Loss' else 'Data Loss' end PRO,
convert(varchar(20), dateadd(s, (cast(substring(master.dbo.numbersize(isnull(redo_queue_size,0) + isnull(log_send_queue_size,0),'kb'),1,charindex(' ',master.dbo.numbersize(isnull(redo_queue_size,0) + isnull(log_send_queue_size,0),'kb'))-1) as float) * 100 * 2), '2000-01-01'), 108) [Time to complete (0.01 GB = 2 sec)],
master.dbo.duration('ms', case when isnull(datediff(ms,last_sent_time,getdate()),0)				< 0 then 0 else isnull(datediff(ms,last_sent_time,getdate()),0)				end) [Data_loss_Time RPO], 
master.dbo.duration('ms', isnull(datediff(ms,last_sent_time,last_received_time),0)) [Network latency]
--master.dbo.duration('ms', case when isnull(datediff(ms,last_sent_time,last_commit_time),0)		< 0 then 0 else isnull(datediff(ms,last_sent_time,last_commit_time),0)		end) [Overall Latency],
--master.dbo.duration('ms', isnull(datediff(ms,last_received_time, last_hardened_time),0)) [IO latency], 
--master.dbo.duration('ms', case when isnull(datediff(ms,last_sent_time,last_hardened_time),0)	< 0 then 0 else isnull(datediff(ms,last_sent_time,last_hardened_time),0)	end) [Acknowledgement Rate],
--master.dbo.duration('ms', case when isnull(datediff(ms,last_hardened_time,getdate()),0)			< 0 then 0 else isnull(datediff(ms,last_redone_time, last_hardened_time),0)			end) [last_hardened_time (LOG IO)]
from sys.dm_hadr_database_replica_states rs inner join sys.databases db 
on rs.database_id = db.database_id
inner join sys.availability_replicas ar
on ar.replica_id = rs.replica_id
where is_local = 1
--and synchronization_state_desc != 'SYNCHRONIZED'
--and  name = 'ePO_D1EPOAPMTPWV2_Events'
order by --[Data_loss_Time RPO] desc, 
total_waiting_logs desc
