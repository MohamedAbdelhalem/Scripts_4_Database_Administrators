SET STATISTICS PROFILE ON
--in the session you want to monitor

select 
s.text, p.physical_operator_name, 
master.dbo.format(row_count,-1) row_count, 
master.dbo.format(estimate_row_count,-1) estimate_row_count,
cast(cast(row_count as float)/cast(estimate_row_count as float) * 100.0 as decimal(10,2)) pct,
master.dbo.duration((last_row_time-first_row_time)/1000) duration, 
master.dbo.duration(cpu_time_ms/1000) cpu_time, logical_read_count
from sys.dm_exec_query_profiles p cross apply sys.dm_exec_sql_text(p.sql_handle)s

