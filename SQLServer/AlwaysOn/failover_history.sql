declare @readerrorlog_0 table (logdate datetime, procee varchar(100), log_text varchar(max))
insert into @readerrorlog_0 
exec sp_readerrorlog 0
--or
create table readerrorlog_0 (logdate datetime, procee varchar(100), log_text varchar(max))
insert into readerrorlog_0 
exec sp_readerrorlog 0


--select * into readerrorlog_0 from @table
create nonclustered index query_convered on readerrorlog_0 (logdate, procee) include (log_text)

select logdate, procee, AG_Name, Status_from, Status_to
from (
select logdate, procee, AG_Name, substring(AG_Status, 1 , charindex(' ', AG_Status)-1) Status_from, substring(AG_Status, charindex(' to ', AG_Status)+4,len(AG_Status)) Status_to
from (
select logdate, procee,
replace(ltrim(rtrim(substring(log_text,charindex(' availability group ', log_text)+len(' availability group '), charindex(' has changed from ', log_text) - charindex(' availability group ', log_text)-len(' availability group ')))),'''','') AG_Name,
replace(ltrim(rtrim(substring(log_text,charindex(' has changed from ', log_text)+len(' has changed from '), charindex('. ', log_text) - charindex(' has changed from ', log_text)-len(' has changed from ')))),'''','') AG_Status
from readerrorlog_0
where log_text like 'The state of the local availability replica in availability group%')a)b
where status_to in ('PRIMARY_NORMAL','SECONDARY_NORMAL') 


select min(logdate), max(logdate) 
from readerrorlog_0 
where log_text = 'Unable to access availability database ''RetinaDatabase'' because the database replica is not in the PRIMARY or SECONDARY role. Connections to an availability database is permitted only when the database replica is in the PRIMARY or SECONDARY role. Try the operation again later.'
order by logdate desc

select * from readerrorlog_0
--where logdate between '2021-11-25 17:45:42.790' and '2021-11-30'
where procee not in ('Logon','Backup')
--and log_text != 'Unable to access availability database ''RetinaDatabase'' because the database replica is not in the PRIMARY or SECONDARY role. Connections to an availability database is permitted only when the database replica is in the PRIMARY or SECONDARY role. Try the operation again later.'
--and log_text != 'Error: 983, Severity: 14, State: 1.'
and log_text like '%RetinaDatabase%'
