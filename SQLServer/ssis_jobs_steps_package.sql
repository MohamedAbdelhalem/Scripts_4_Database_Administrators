select job_name, step_id, step_name, command, subsystem, package, package_name
from (
select job_name, step_id, step_name, command, subsystem, package, reverse(substring(reverse(package),1,charindex('\',reverse(package))-1)) package_name
from (
select j.name job_name, step_id, step_name, command, subsystem, 
substring([dbo].[virtical_array](command,' ',2),5,len([dbo].[virtical_array](command,' ',2))-7) package
from msdb.dbo.sysjobs j inner join msdb.dbo.sysjobsteps js
on j.job_id = js.job_id
where subsystem = 'ssis')a)b
where package_name = 'Corporate'
