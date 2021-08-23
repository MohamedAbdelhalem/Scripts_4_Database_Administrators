select table_name, stats_name, columns, last_updated, rows, modification_counter
from (
select object_id, stats_id, table_name, stats_name, --[1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15], [16], [17]
isnull(  '['+[1]+']','')+
isnull(' ,['+[2]+']','') +isnull(' ,['+[3]+']','') +isnull(' ,['+[4]+']','') +isnull(' ,['+[5]+']','')+
isnull(' ,['+[6]+']','') +isnull(' ,['+[7]+']','') +isnull(' ,['+[8]+']','') +isnull(' ,['+[9]+']','')+
isnull(' ,['+[10]+']','')+isnull(' ,['+[11]+']','')+isnull(' ,['+[12]+']','')+isnull(' ,['+[13]+']','')+
isnull(' ,['+[14]+']','')+isnull(' ,['+[15]+']','')+isnull(' ,['+[16]+']','')+isnull(' ,['+[17]+']','') columns
from (
select t.object_id, s.stats_id, '['+schema_name(t.schema_id)+'].['+t.name+']' table_name, 
s.name stats_name, stats_column_id, c.name
from sys.stats s inner join sys.stats_columns sc
on s.stats_id = sc.stats_id
and s.object_id = sc.object_id
inner join sys.columns c
on sc.column_id = c.column_id
and sc.object_id = c.object_id
inner join sys.tables t 
on t.object_id = s.object_id)a
pivot
(max(name) for stats_column_id in ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15], [16], [17]))piv)b
cross apply [sys].[dm_db_stats_properties_internal](object_id,stats_id)
where table_name in ('[dbo].[TRANS_PARTIES]','')
and stats_name = 'IX_TRANS_PARTIES_1'

-- To find the exact row set in the stats
select '['+schema_name(t.schema_id)+'].['+t.name+']' table_name, s.name stats_name, c.* 
from sys.stats s inner join sys.tables t
on s.object_id = t.object_id
cross apply (
select 
a.step_number, 
cast(isnull(b.range_high_key,0) as float) + 1 range_high_key_from, a.range_high_key range_high_key_to, 
a.equal_rows, a.average_range_rows 
from [sys].[dm_db_stats_histogram](t.object_id,s.stats_id) a left join [sys].[dm_db_stats_histogram](t.object_id,s.stats_id) b
on a.step_number -1 = b.step_number)c
where t.object_id = object_id('[dbo].[TRANS_PARTIES]')
and s.name = 'IX_TRANS_PARTIES_1'
and 490 between range_high_key_from and range_high_key_to
-----| the value that you just need it to find the range of the estimated number of rows
