use master
go

Create function dbo.instance_name (@purpose char(1))
returns varchar(300)
as
begin
declare @instance varchar(300)
select 
@instance = 
case 
when charindex('\',name) > 0 
then case @purpose 
		when 's' then 'MSSQL$'+substring(name, charindex('\',name)+1,len(name))+':'
		else substring(name, charindex('\',name)+1,len(name))
		end
else case @purpose 
		when 'n' then 'MSSQLSERVER'
		when 's' then 'SQLServer:'
		when 'o' then ''
		end
end 
from sys.servers
where server_id = 0

return @instance
end


select cast(cast(hit_ratio as float) / cast(hit_ratio_base as float) as decimal(10,3)) Buffer_Cache_Hit_Ratio
from (
select object_name, counter_name, cntr_value hit_ratio
from sys.dm_os_performance_counters 
where counter_name = 'Buffer cache hit ratio'
and object_name = master.dbo.instance_name('s')+'Buffer Manager')a
cross apply (
select object_name, counter_name, cntr_value hit_ratio_base
from sys.dm_os_performance_counters
where counter_name = 'Buffer cache hit ratio base'
and object_name = master.dbo.instance_name('s')+'Buffer Manager')b

