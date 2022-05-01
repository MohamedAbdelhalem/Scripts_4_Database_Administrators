USE [msdb]
GO
CREATE TABLE [dbo].[email_detail](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[sent_date] [datetime] NULL,
	[Server_name] [varchar](500) NULL,
	[Server_IP] [varchar](50) NULL,
	[dbname] [varchar](400) NULL,
	[table_name] [varchar](400) NULL,
	[start_time] [varchar](50) NULL,
	[end_time] [varchar](50) NULL,
	[rows_b] [varchar](50) NULL,
	[rows_d] [varchar](50) NULL,
	[rows_a] [varchar](50) NULL,
	[emails] [varchar](3000) NULL,
	[ccemails] [varchar](3000) NULL,
	[message_body] [varchar](4000) NULL,
	[email_subject] [varchar](1000) NULL,
	[send_profile] [varchar](300) NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[email_detail] ADD  DEFAULT (getdate()) FOR [sent_date]
GO
CREATE TABLE [dbo].[receivers_list](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[email] [varchar](1000) NULL,
	[status] [int] NULL
) ON [PRIMARY]
GO
USE [master]
GO
CREATE PROCEDURE [dbo].[sp_email_notification]
(
@s_name			varchar(100), 
@s_ip			varchar(50), 
@db				varchar(350),
@table			varchar(1000),
@start			varchar(30), 
@finish			varchar(30), 
@Before			varchar(100),
@Deleted		varchar(100),
@After			varchar(100),
@emails			varchar(2000),
@ccemails		varchar(2000),
@message		varchar(max),
@subj			varchar(1000),
@profile		varchar(100))
as
begin

--@database varchar(2000) = 'Identityiq  , identityiqPlugin, KAVNEW,  SUSDB '
--@emails varchar(2000) = 'Osama M. Salem ( Contractor ) <osalem@riyadhairports.com>            ,            Mashail S. Al-Juraid <mjuraid@riyadhairports.com>            '
--@ccemails varchar(2000) = 'Malek B. Al-Iswed <miswed@riyadhairports.com>,Halah M. Al-Abdullah <halabdullah@riyadhairports.com>,Mohamed Abdelhalem <mabdelhalem@riyadhairports.com>,Shahid Khan <shahidk@riyadhairports.com>'

declare 
@tab			varchar(max),
@receivers		int, 
@first_name		varchar(500), 
@duration		varchar(20)

select @receivers = count(*) from master.dbo.Separator(@emails,';')

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
from dbo.Separator(@emails,';'))a
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
from dbo.Separator(@emails,';'))a
pivot
(max(email) for id in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16]))pvt)b

if @ccemails like '%@%'
begin
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
from dbo.Separator(@ccemails,';'))a
pivot
(max(ccemail) for id in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16]))pvt)b
end

set @first_name = 'Dear '+case 
	when @receivers > 1 then  reverse(substring(reverse(@first_name),charindex(',',reverse(@first_name)), len(reverse(@first_name))))+
	' and'+reverse(substring(reverse(@first_name),1,charindex(',',reverse(@first_name))-1)) 
	when @receivers = 1 then @first_name end +','

set @duration = master.dbo.duration(datediff(s,@start,@finish))
set @tab = '
  </tr>
  <tr style="border:1px solid black; text-align: center; vertical-align: middle;">
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@s_name+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@s_ip+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@db+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@table+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@start+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@finish+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@duration+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@Before+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@Deleted+'</td>
	<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@After+'</td>
  </tr>
  '
  print(@tab)
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
  <th style="border:1px solid black;">Server Name</th>
  <th style="border:1px solid black;">Server IP</th>
  <th style="border:1px solid black;">Database Name</th>
  <th style="border:1px solid black;">Table Name</th>
  <th style="border:1px solid black;">Deletion Start</th>
  <th style="border:1px solid black;">Deletion Finish</th>
  <th style="border:1px solid black;">Duration</th>
  <th style="border:1px solid black;">Rows Before</th>
  <th style="border:1px solid black;">Deleted Rows</th>
  <th style="border:1px solid black;">Rows After</th>'+'
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

print(@body)

exec msdb..sp_send_dbmail 
@profile_name = @profile, 
@recipients = @emails, 
--@copy_recipients = @ccemails,
@subject = @subj, 
@body =  @body, 
@body_format = 'HTML'

end
GO
USE [msdb]
GO
Create Procedure [dbo].[sp_big_table_data_cleaning]
(
@db_name varchar(300) = '[ApplicationLogs]',
@table_name varchar(500) = '[dbo].[ADT_LOG]', 
@unique_column varchar(300) = '[AL_ID]', 
@where varchar(400) = '[AL_START_TS] <  DATEADD(MONTH, -3, CAST(getdate() AS date))',
@bulk int = 10000,
@top varchar(50) = 'all')
as
begin
set nocount on

declare @table table (id int primary key, recid varchar(255))
declare 
@Subject			varchar(200) = 'Bank Albilad-Production Log Clean-Up Report on Server ('+ CONVERT(VARCHAR(50), SERVERPROPERTY('servername')) + ')',
@dynamic_sql		varchar(max),
@from_unique_column numeric, 
@to_unique_column	numeric,
@AL_ID_from			numeric, 
@AL_ID_to			numeric,
@AL_START_TS_from	datetime, 
@AL_START_TS_to		datetime,
@ErrorMessage		nvarchar(4000),  
@ErrorSeverity		int,
@ErrorState			int,
@body				varchar(max),
@server_name		varchar(400),
@server_ip			varchar(50),
@start_time			datetime, 
@end_time			datetime, 
@rows_b				varchar(50),
@rows_d				varchar(50),
@rows_a				varchar(50),
@emails				varchar(3000)

select @emails = 
[1]
+isnull(';'+[2],'')+isnull(';'+[3],'')+isnull(';'+[4],'')+isnull(';'+[5],'')
+isnull(';'+[6],'')+isnull(';'+[7],'')+isnull(';'+[8],'')+isnull(';'+[9],'')+isnull(';'+[10],'')
from (
select row_number() over(order by id) id, email 
from receivers_list 
where status = 1
--and email like '%fawzy%'
)a
PIVOT (
max(email) for id in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10]))p

CREATE TABLE #summary (
[id] [int] NOT NULL,
[unique_id] [int] NULL,
[from_id] [bigint] NULL,
[to_id] [bigint] NULL,
[from_unique_column] [varchar](500) NULL,
[to_unique_column] [varchar](500) NULL,
PRIMARY KEY CLUSTERED ([id]))

CREATE TABLE #summary2 (
[id] [int] identity(1,1) NOT NULL, 
[rows] [int], 
[AL_START_TS] datetime, 
[AL_ID_from] numeric, 
[AL_ID_to] numeric,
PRIMARY KEY CLUSTERED ([id]))

select @start_time = convert(varchar(50), getdate(), 120)
select @rows_b = master.dbo.format(count(*),-1) from [ApplicationLogs].dbo.ADT_LOG with (nolock)

set @dynamic_sql = '
select '+case when @top = 'all' then '' else 'TOP ('+@top+')' end +' row_number() over(order by '+@unique_column+') id, '+@unique_column+'
from '+@db_name+'.'+@table_name+' WITH (NOLOCK)
where '+@where+'
order by '+@unique_column+'
OPTION (MAXDOP 4)'

print(@dynamic_sql)
insert into @table 
exec (@dynamic_sql)

insert into #summary 
select row_number() over(order by unique_id desc) id, unique_id, min(id), max(id), min(recid), max(recid)
from (
select count(*) over() - patch_id - count(*) over(order by id) unique_id, * 
from (
select id % @bulk patch_id, id, recid
from @table)a
where patch_id in (0,1)
union all
select -1, 0, id, recid
from (
select count(*) over() - patch_id - count(*) over(order by id) unique_id, * 
from (
select id % @bulk patch_id, id, recid
from @table)a)b
where id in (select max(id) 
				from (
					select count(*) over() - patch_id - count(*) over(order by id) unique_id, patch_id, id, recid 
						from (
							select id % @bulk patch_id, id, recid 
								from @table)a)b))c
group by unique_id
order by unique_id desc

declare sum_i cursor fast_forward
for
select [from_unique_column], [to_unique_column] 
from #summary 
order by id

open sum_i
fetch next from sum_i into @from_unique_column, @to_unique_column
while @@fetch_status = 0
begin

insert into #summary2 ([rows], [AL_START_TS])
select count(*), convert(varchar(10), AL_START_TS, 120) 
from [ApplicationLogs].[dbo].[ADT_LOG]
where AL_ID between @from_unique_column and @to_unique_column
group by convert(varchar(10), AL_START_TS, 120)
order by convert(varchar(10), AL_START_TS, 120)

UPDATE #summary2 
SET AL_ID_from = @from_unique_column, 
	AL_ID_to = @to_unique_column 
where AL_ID_from is null

fetch next from sum_i into @from_unique_column, @to_unique_column
end
close sum_i
deallocate sum_i

declare sum_ii cursor fast_forward
for
select AL_START_TS, dateadd(s,-1,AL_START_TS+1), AL_ID_from, AL_ID_to 
from #summary2 
where AL_START_TS <  DATEADD(MONTH, -3, CAST(getdate() AS date))
order by id

open sum_ii
fetch next from sum_ii into @AL_START_TS_from, @AL_START_TS_to, @AL_ID_from, @AL_ID_to
while @@fetch_status = 0
begin

BEGIN TRY

Delete from [ApplicationLogs].[dbo].ADT_LOG 
where AL_START_TS between @AL_START_TS_from and @AL_START_TS_to
and AL_ID between @AL_ID_from AND @AL_ID_to 

END TRY
BEGIN CATCH
  
SELECT  @ErrorMessage = ERROR_MESSAGE(),  
        @ErrorSeverity = ERROR_SEVERITY(),  
        @ErrorState = ERROR_STATE() 
  
RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)  
set @body = '.....The ERROR_MESSASGE is '+@ErrorMessage

EXECUTE msdb.dbo.sp_notify_operator  
@profile_name ='SQLAlerts',
@name=N'DBAlerts',
@subject=N'Issue Clean ADT_LOG from ApplicationLogs DB',
@body=@body

END CATCH

fetch next from sum_ii into @AL_START_TS_from, @AL_START_TS_to, @AL_ID_from, @AL_ID_to
end
close sum_ii
deallocate sum_ii

select @rows_d = master.dbo.format(sum([rows]),-1) from #summary2
select @rows_a = master.dbo.format(count(*),-1)    from [ApplicationLogs].dbo.ADT_LOG with (nolock)
select @end_time = convert(varchar(50), getdate(), 120)

select 
@body = 'Kindly be infromed that the cleaning up was finished successfully and please find in the below table the detailed information:',
@server_name = cast(SERVERPROPERTY('servername') as varchar(400)),
@server_ip = isnull(cast(CONNECTIONPROPERTY('local_net_address') as varchar(50)),'Local Net')

insert into email_detail
(server_name, server_ip, dbname,table_name,start_time, end_time, rows_b,rows_d,rows_a,emails,ccemails,message_body,email_subject,send_profile)
select 
@server_name, 
@server_ip, 
@db_name,
@table_name,
@start_time, 
@end_time, 
@rows_b,
@rows_d,
@rows_a,
@emails,
'N/A',
@body,
@subject,
'SQLAlerts'

exec master.[dbo].[sp_email_notification]
@s_name			= @server_name, 
@s_ip			= @server_ip, 
@db				= @db_name,
@table			= @table_name,
@start			= @start_time, 
@finish			= @end_time, 
@Before			= @rows_b,
@Deleted		= @rows_d,
@After			= @rows_a,
@emails			= @emails,
@ccemails		= 'N/A',
@message		= @body,
@subj			= @subject,
@profile		= 'SQLAlerts'

set nocount off
end


