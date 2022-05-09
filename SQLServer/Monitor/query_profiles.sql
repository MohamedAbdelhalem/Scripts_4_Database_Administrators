dbcc traceon (7412,-1)
-- or capturing the query_thread_profile extended event
go
SET STATISTICS PROFILE ON
go
select 
session_id, node_id, physical_operator_name,
o.name [object_name],
i.name index_name,
physical_operator_name + QUOTENAME(CAST(COUNT(thread_id) AS VARCHAR(4))) AS physical_operator_name,
master.dbo.Format(sum(row_count),-1) row_count, 
master.dbo.Format(sum(estimate_row_count),-1) estimate_row_count, 
cast(cast(sum(row_count) as float)/cast(sum(estimate_row_count) as float) * 100.0 as decimal(5,2)) percent_complete,
master.dbo.duration((sum(last_row_time)-sum(first_row_time))/1000) duration, 
master.dbo.duration(sum(cpu_time_ms)/1000) cpu_time,
CAST(SUM(elapsed_time_ms) * 100. /(SUM(SUM(elapsed_time_ms)) OVER() + .00001) AS DECIMAL(5,2)) [total_elapsed_time_%],
CAST(SUM(cpu_time_ms) * 100. /(SUM(SUM(cpu_time_ms)) OVER() + .00001) AS DECIMAL(5,2)) [total_cpu_%],
CAST((sum(logical_read_count)		    * 100. / (sum(sum(logical_read_count))		  OVER() + .00001)) AS DECIMAL(5,2)) [total_logical_read_%],
CAST((sum(physical_read_count)		  * 100. / (sum(sum(physical_read_count))		  OVER() + .00001)) AS DECIMAL(5,2)) [total_physical_read_%],
CAST((sum(lob_logical_read_count)	  * 100. / (sum(sum(lob_logical_read_count))	OVER() + .00001)) AS DECIMAL(5,2)) [lob_logical_read_%],
CAST((sum(lob_physical_read_count)	* 100. / (sum(sum(lob_physical_read_count))	OVER() + .00001)) AS DECIMAL(5,2)) [lob_physical_read_%],
CAST((sum(write_page_count)			    * 100. / (sum(sum(write_page_count))		    OVER() + .00001)) AS DECIMAL(5,2)) [total_write_%]
from sys.dm_exec_query_profiles p
left join sys.objects o
on o.object_id = p.object_id
left join sys.indexes i
on i.object_id = p.object_id
and i.index_id = p.index_id
GROUP BY p.node_id, session_id, p.physical_operator_name, o.name, i.name
order by node_id


