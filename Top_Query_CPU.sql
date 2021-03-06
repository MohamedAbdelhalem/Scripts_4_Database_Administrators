
select 
master.dbo.numberSize(requested_memory_kb,'kb') requested_memory, 
master.dbo.numberSize(granted_memory_kb,'kb') granted_memory,  
master.dbo.numberSize(required_memory_kb,'kb') required_memory,  
* from sys.dm_exec_query_memory_grants

select * from (
select top 100 p.query_plan, s.text, substring(s.text,statement_start_offset/2+1, statement_end_offset/2) current_text, creation_time, last_execution_time, execution_count, 
total_worker_time*1000 cpu_time ,round(cast((total_worker_time *1000) as float) / (select cast(sum(total_worker_time)*1000 as float) from sys.dm_exec_query_stats) * 100, 2) cpu_time_pct, 
last_worker_time, min_worker_time, max_worker_time, total_logical_writes, max_logical_writes, total_logical_reads, last_logical_reads, min_logical_reads, max_logical_reads, total_rows, last_rows, min_rows, max_rows
--MS SQL Server 2016 version 
--, max_dop, total_grant_kb, last_grant_kb, min_grant_kb, max_grant_kb, max_used_grant_kb, max_ideal_grant_kb  
from sys.dm_exec_query_stats q cross apply sys.dm_exec_sql_text(q.sql_handle)s
cross apply sys.dm_exec_query_plan(q.plan_handle) p
order by cpu_time_pct desc)a
where creation_time > convert(varchar(10),getdate(),120)
--where current_text like '%SIST_ZLOG_SSMS%'
and last_execution_time > '2020-02-29 00:00:00'
and cpu_time > 0
order by cpu_time_pct desc

--order by total_logical_reads desc
