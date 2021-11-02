USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_email_notification_adhoc_backup]    Script Date: 11/2/2021 3:19:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_email_notification_adhoc_backup]
(
@database varchar(2000),
@emails varchar(2000),
@ccemails varchar(2000)
)
as
begin

--@database varchar(2000) = 'Identityiq  , identityiqPlugin, KAVNEW,  SUSDB '
--@emails varchar(2000) = 'Osama M. Salem ( Contractor ) <osalem@riyadhairports.com>            ,            Mashail S. Al-Juraid <mjuraid@riyadhairports.com>            '
--@ccemails varchar(2000) = 'Malek B. Al-Iswed <miswed@riyadhairports.com>,Halah M. Al-Abdullah <halabdullah@riyadhairports.com>,Mohamed Abdelhalem <mabdelhalem@riyadhairports.com>,Shahid Khan <shahidk@riyadhairports.com>'

declare @tab varchar(max), @dbno int, @receivers int, @is_cluster int, @first_name varchar(500), @message varchar(500), @cluster_name varchar(100), @cluster_ip varchar(50), @instance_name varchar(100), @port varchar(10), @loop int = 0, @db_name varchar(300)
declare @backup_file varchar(1000), @start_date varchar(30), @finish_date varchar(30), @duration varchar(20), @backup_size varchar(30), @backup_type varchar(20)

select @dbno = count(*) from dbo.Separator(@database,',')
select @receivers = count(*) from dbo.Separator(@emails,',')
if exists (select * from sys.dm_os_cluster_properties)
set @is_cluster = 1
else 
set @is_cluster = 0

select @first_name = substring(first_name, 1, len(first_name)-1)
from (
select 
isnull([1]+', ','')  +isnull([2]+', ','')  +isnull([3]+', ','')  +isnull([4]+', ','')  +
isnull([5]+', ','')  +isnull([6]+', ','')  +isnull([7]+', ','')  +isnull([8]+', ','')  +
isnull([9]+', ','')  +isnull([10]+', ','') +isnull([11]+', ','') +isnull([12]+', ','') +
isnull([13]+', ','') +isnull([14]+', ','') +isnull([15]+', ','') +isnull([16]+', ','') first_name
from (
select id, 
substring(ltrim(rtrim(value)), 1, charindex(' ',ltrim(rtrim(value)))-1) first_name
from dbo.Separator(@emails,','))a
pivot
(max(first_name) for id in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16]))pvt)b

select @emails = substring(emails, 1, len(emails)-1)
from (
select 
isnull([1] +';','')  +isnull([2] +';','')  +isnull([3] +';','')  +isnull([4] +';','')  +
isnull([5] +';','')  +isnull([6] +';','')  +isnull([7] +';','')  +isnull([8] +';','')  +
isnull([9] +';','')  +isnull([10]+';','')  +isnull([11]+';','')  +isnull([12]+';','')  +
isnull([13]+';','')  +isnull([14]+';','')  +isnull([15]+';','')  +isnull([16]+';','')  emails
from (
select id, 
substring(ltrim(rtrim(value)), charindex('<',ltrim(rtrim(value)))+1,  charindex('>',ltrim(rtrim(value))) - charindex('<',ltrim(rtrim(value))) -1) email
from dbo.Separator(@emails,','))a
pivot
(max(email) for id in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16]))pvt)b

select @ccemails = substring(ccemails, 1, len(ccemails)-1) 
from (
select 
isnull([1] +';','')  +isnull([2] +';','')  +isnull([3] +';','')  +isnull([4] +';','')  +
isnull([5] +';','')  +isnull([6] +';','')  +isnull([7] +';','')  +isnull([8] +';','')  +
isnull([9] +';','')  +isnull([10]+';','')  +isnull([11]+';','')  +isnull([12]+';','')  +
isnull([13]+';','')  +isnull([14]+';','')  +isnull([15]+';','')  +isnull([16]+';','')  ccemails
from (
select id,
substring(ltrim(rtrim(value)), charindex('<',ltrim(rtrim(value)))+1,  charindex('>',ltrim(rtrim(value))) - charindex('<',ltrim(rtrim(value))) -1) ccemail
from dbo.Separator(@ccemails,','))a
pivot
(max(ccemail) for id in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16]))pvt)b

set @first_name = 'Dear '+case 
when @receivers > 1 then  reverse(substring(reverse(@first_name),charindex(',',reverse(@first_name)), len(reverse(@first_name))))+
' and'+reverse(substring(reverse(@first_name),1,charindex(',',reverse(@first_name))-1)) 
when @receivers = 1 then @first_name end +','
set @message = 'Kindly be informed that the below database'+case when @dbno > 1 then 's have ' else ' has ' end +'backed up as you requested.'

declare @table table (output_text varchar(max))
declare @std nvarchar(max) = 'xp_cmdshell ''powershell.exe -Command " & {Get-NetIPAddress -AddressFamily IPV4 | Select-Object IPAddress}"'''
if not exists (select * from sys.dm_os_cluster_properties)
insert into @table
exec (@std)

--select @dbno, @first_name, @emails, @ccemails, @message

select 
@cluster_name  = case when charindex('\',s.name) = 0 then s.name else substring(s.name, 1, charindex('\',s.name)-1) end, 
@cluster_ip    = case when @is_cluster = 1 then t.IP_Address else (select output_text from @table where output_text like '10.%') end,
@instance_name = case when charindex('\',s.name) = 0 then 'MSSQLSERVER' else substring(s.name, charindex('\',s.name)+1, len(s.name))end, @port = t.Port
from sys.servers s
cross apply (select ip_address, port from sys.dm_tcp_listener_states where listener_id = 1) t
where s.server_id = 0

while @loop < @dbno
begin

select @db_name = ltrim(rtrim(value))
from dbo.Separator(@database,',')
where id = @loop + 1

select top 1 
@backup_file = bmf.physical_device_name, 
@start_date = convert(varchar(30),backup_start_date,120), 
@finish_date = convert(varchar(30),backup_finish_date,120), 
@duration = convert(varchar(20), dateadd(s,datediff(s,backup_start_date,backup_finish_date),'2000-01-01'),108),
@backup_type = case type when 'D' then 'full' when 'L' then 'Log' when 'I' then 'Differential' end, 
@backup_size = master.dbo.numberSize(backup_size,'b')
from msdb.dbo.backupmediafamily bmf inner join msdb.dbo.backupset bs 
on bmf.media_set_id = bs.media_set_id
where bs.media_set_id in (
select media_set_id
from msdb.dbo.backupset
where backup_finish_date in (
select max(backup_finish_date) backup_finish_date
from msdb.dbo.backupset
where [database_name] in (@db_name)
group by [database_name]))

if @loop = 0
begin
set @tab = '
  </tr>
  <tr style="border:1px solid black; text-align: center; vertical-align: middle;">
	<td style="border:1px solid black; text-align: center; vertical-align: middle;" rowspan='+cast(@dbno as varchar)+'>'+@cluster_name+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;" rowspan='+cast(@dbno as varchar)+'>'+@cluster_ip+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;" rowspan='+cast(@dbno as varchar)+'>'+@instance_name+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;" rowspan='+cast(@dbno as varchar)+'>'+@port+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+cast(@loop + 1 as varchar)+'</td>	
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@db_name+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@start_date+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@finish_date+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@duration+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@backup_file+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@backup_size+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@backup_type+'</td>
  </tr>
  '
end
else
begin
	set @tab = @tab +  '<tr style="border:1px solid black; text-align: center; vertical-align: middle;">
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+cast(@loop + 1 as varchar)+'</td>	
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@db_name+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@start_date+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@finish_date+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@duration+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@backup_file+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@backup_size+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@backup_type+'</td>
  </tr>
  '
end
set @loop = @loop + 1
end

declare @body varchar(max) = 
'<!DOCTYPE html>
<html>
<head>
</head>
<body>
<pre style=
"font-family:Segoe UI;
 font-size: 15px;">'+'
'+@first_name+'

'+@message+'
'+'</pre>
<table style="border:1px solid BLUE;border-collapse:collapse;width: 70%">
  <tr bgcolor="YELLOW">
  <th style="border:1px solid black;">'+case when @is_cluster = 1 then 'SQL Cluster Name' else 'Server Name' end+'</th>
  <th style="border:1px solid black;">'+case when @is_cluster = 1 then 'SQL Cluster IP' else 'IP Address' end+'</th>
  <th style="border:1px solid black;">Instance Name</th>
  <th style="border:1px solid black;">Port</th>
  <th style="border:1px solid black;">NO#</th>
  <th style="border:1px solid black;">Database Name</th>
  <th style="border:1px solid black;">Backup Start Date</th>
  <th style="border:1px solid black;">Backup Finish Date</th>
  <th style="border:1px solid black;">Duration</th>
  <th style="border:1px solid black;">Backup File</th>
  <th style="border:1px solid black;">Backup Size</th>
  <th style="border:1px solid black;">Backup Type</th>'+'
  '+'
  '+@tab+'
'+'</table>
<pre style=
"font-family:Segoe UI;
 font-size: 15px;">
Thanks,
Database Team.
</pre>

</body>
</html>'

--print(@body)

exec msdb..sp_send_dbmail 
@profile_name = 'DBmailProfile', 
@recipients = @emails, 
@copy_recipients = @ccemails,
@subject = 'Adhoc Database Backup Request Confirmation', 
@body =  @body, 
@body_format = 'HTML'

end
