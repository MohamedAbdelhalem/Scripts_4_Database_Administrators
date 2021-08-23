select * 
from (
select table_name, stats_name, --[1], [2], [3], [4], [5], [6], [7], [8], [9]
isnull('['+[1]+']','')+
isnull(' ,['+[2]+']','')+isnull(' ,['+[3]+']','')+isnull(' ,['+[4]+']','')+isnull(' ,['+[5]+']','')+
isnull(' ,['+[6]+']','')+isnull(' ,['+[7]+']','')+isnull(' ,['+[8]+']','')+isnull(' ,['+[9]+']','') columns
from (
select '['+schema_name(t.schema_id)+'].['+t.name+']' table_name, 
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
(max(name) for stats_column_id in ([1], [2], [3], [4], [5], [6], [7], [8], [9]))piv)b
order by table_name, stats_name
