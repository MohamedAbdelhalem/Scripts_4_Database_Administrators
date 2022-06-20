select 
counter_name, 
cntr_value PLE_value,
master.dbo.duration('s',cntr_value) Actual_PLE,
master.dbo.virtical_array(ple,',',1) Data_Cache_Size,
--master.dbo.virtical_array(ple,',',2) Expected_PLE_n,
master.dbo.virtical_array(ple,',',3) Expected_PLE_h
from sys.dm_os_performance_counters p cross apply (	select
													master.dbo.numbersize(cast(value_in_use as int),'mb')+','+ 
													cast((cast(value_in_use as float)/1024.0/4.0)*300 as varchar(100))+','+
													master.dbo.duration('s',(cast(value_in_use as float)/1024.0/4.0)*300) ple
													from sys.configurations 
													where name = 'max server memory (mb)') ple
where cast(counter_name as varchar(100)) like 'Page life%'
and cast(object_name as varchar(100)) like '%Buffer Manager%'

