select spid, round(percent_complete,4) percent_complete,
case
when s.text like '%restore database%' and s.text like '%move%' then 'FULL'
when s.text like '%restore database%' and s.text not like '%move%' then 'DIFF'
when s.text like '%restore log%' then 'LOG' end [restore_type], 
dbo.duration(datediff(s, r.start_time, getdate())) duration, 
dbo.duration(
cast((100.0 / round(percent_complete,4)) 
* 
datediff(s, r.start_time, getdate()) as int)
-
datediff(s, r.start_time, getdate())
) time_to_complete,
dbo.duration(estimated_completion_time/1000) estimated_completion_time,
s.text, waittime, lastwaittype, blocked, command, r.status
from sys.sysprocesses p cross apply sys.dm_exec_sql_text(p.sql_handle)s
left outer join sys.dm_exec_requests r
on p.spid = r.session_id
inner join sys.dm_exec_connections c
on p.spid = c.session_id
where command like 'Restore%'


