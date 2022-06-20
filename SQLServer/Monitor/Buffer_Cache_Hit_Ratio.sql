select round((hit_ratio / hit_ratio_base) * 100.0, 2) Buffer_Cache_Hit_Ratio
from (
select cast(cntr_value as float) hit_ratio
from sys.dm_os_performance_counters
where cast(counter_name as varchar(100)) = 'Buffer cache hit ratio'
and cast(object_name as varchar(100)) like '%Buffer Manager%')a
cross apply (
select cast(cntr_value as float) hit_ratio_base
from sys.dm_os_performance_counters
where cast(counter_name as varchar(100)) = 'Buffer cache hit ratio base'
and cast(object_name as varchar(100)) like '%Buffer Manager%')b


