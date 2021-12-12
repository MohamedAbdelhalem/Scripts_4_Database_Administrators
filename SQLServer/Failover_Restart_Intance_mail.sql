USE [master]
GO
/****** Object:  StoredProcedure [dbo].[Failover_Restart_Intance_mail]    Script Date: 12/12/2021 3:46:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Failover_Restart_Intance_mail]
as
begin

declare 
@email_subject varchar(max),
@email_body varchar(max),
@email_body_simple  varchar(max)

declare @result table (node_id int identity(1,1), Node_Name varchar(150), Node_IP varchar(50), Cluster_Name varchar(150), 
Cluster_IP varchar(50), Instance_Name varchar(150), Port varchar(10), Status_Description varchar(50), Is_Current_Owner int)
declare @table table (output_text varchar(max))
declare @letter varchar(5) = (select distinct top 1 left(physical_name,1) from sys.master_files)
declare @sql nvarchar(max) = 'xp_cmdshell ''powershell.exe -Command " & {Get-ClusterNetworkInterface | format-table -Property Node,Address}"'''
insert into @table
exec (@sql)

insert into @result
select nodename, a.Node_IP,
case 
when charindex('\',s.name) = 0 then s.name 
else substring(s.name, 1, charindex('\',s.name)-1)
end Cluster_name, t.IP_Address,
case 
when charindex('\',s.name) = 0 then 'MSSQLSERVER' 
else substring(s.name, charindex('\',s.name)+1, len(s.name))
end Instance_name, t.Port,
status_description, is_current_owner 
from sys.dm_os_cluster_nodes n cross apply sys.servers s
cross apply (select ip_address, port from sys.dm_tcp_listener_states where listener_id = 1) t
inner join (select substring(output_text,1, charindex(' ',output_text)-1) Node_Name, substring(output_text,charindex(' ',output_text)+1,len(output_text)) Node_IP  
from @table where output_text is not null and output_text not like '--%' and output_text not like 'Node%Address')a
on n.NodeName = a.Node_Name
and [dbo].[Separator_Single](t.ip_address,'.',1) = [dbo].[Separator_Single](a.Node_IP,'.',1)
and [dbo].[Separator_Single](t.ip_address,'.',2) = [dbo].[Separator_Single](a.Node_IP,'.',2)
where s.server_id = 0
order by nodename

declare 
@node_id varchar(10),
@node_name varchar(300),
@node_ip varchar(300),
@rowspan varchar(300),
@cluster_name varchar(300),
@cluster_ip varchar(300),
@instance_name varchar(300),
@port varchar(300),
@status varchar(300),
@owner varchar(300),
@rows varchar(max)

declare i cursor fast_forward
for
select Node_id, Node_Name, Node_IP,
case cluster_Name_id when 1 then 'rowspan='+cast(counter as varchar(10)) else null end rowspan, 
case cluster_Name_id when 1 then Cluster_Name else null end Cluster_Name , 
case cluster_IP_id when 1 then Cluster_IP else null end Cluster_IP, 
case Instance_name_id when 1 then Instance_Name else null end Instance_Name, 
case Port_id when 1 then Port else null end Port, 
Status_Description, 
Is_Current_Owner
from (
select top 100 percent Node_id, Node_Name, Node_IP, (select count(*) from @result) counter,
row_number() over(partition by cluster_Name order by node_id desc) - 1 cluster_Name_id, Cluster_Name,
row_number() over(partition by cluster_IP order by node_id desc) - 1 cluster_IP_id, Cluster_IP,
row_number() over(partition by Instance_name order by node_id desc) - 1 Instance_name_id, Instance_name,
row_number() over(partition by Port order by node_id desc) - 1 Port_id, Port,
Status_Description,
Is_Current_Owner
from @result
order by node_id)a
order by node_id

open i
fetch next from i into @node_id,@node_name,@node_ip,@rowspan,@cluster_name,@cluster_ip,@instance_name,@port,@status,@owner
while @@FETCH_STATUS = 0
begin
set @rows = isnull(@rows,'')+'
<tr style="border:1px solid black; text-align: center; vertical-align: middle;">'+'
	'+isnull('<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@node_id+'</td>','')+'
	'+isnull('<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@node_name+'</td>','')+'
	'+isnull('<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@node_ip+'</td>','')+'
	'+isnull('<td style="border:1px solid black; text-align: center; vertical-align: middle;" '+isnull(@rowspan,'')+'>'+@cluster_name+'</td>','')+'
	'+isnull('<td style="border:1px solid black; text-align: center; vertical-align: middle;" '+isnull(@rowspan,'')+'>'+@cluster_ip+'</td>','')+'
	'+isnull('<td style="border:1px solid black; text-align: center; vertical-align: middle;" '+isnull(@rowspan,'')+'>'+@instance_name+'</td>','')+'
	'+isnull('<td style="border:1px solid black; text-align: center; vertical-align: middle;" '+isnull(@rowspan,'')+'>'+@port+'</td>','')+'
	'+isnull('<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@status+'</td>','')+'
	'+isnull('<td style="border:1px solid black; text-align: center; vertical-align: middle;">'+@owner+'</td>','')+'
</tr>'
fetch next from i into @node_id,@node_name,@node_ip,@rowspan,@cluster_name,@cluster_ip,@instance_name,@port,@status,@owner
end
close i
deallocate i

select top 1 @cluster_name = Cluster_Name, @cluster_ip = Cluster_IP 
from @result

set @email_subject = 'Cluster Instance '+@cluster_name+' ('+@cluster_ip+') Restarted'
set @email_body = '<!DOCTYPE html>
<html>
<head>
</head>
<body>
<pre style=
"font-family:Segoe UI;
 font-size: 15px;">
Dears,
Kindly be informed that instance <u><b>'+@cluster_name+' ('+@cluster_ip+')</b></u> was down and just come back again now.

</pre>

<table style="border:1px solid black;border-collapse:collapse;table-layout: fixed;width: 200%">
  <tr bgcolor="BLUE">
  <th style="border:1px solid black;">Node Id</th>
  <th style="border:1px solid black;">Server Name</th>
  <th style="border:1px solid black;">Server IP</th>
  <th style="border:1px solid black;">SQL Cluster Name</th>
  <th style="border:1px solid black;">SQL Cluster IP</th>
  <th style="border:1px solid black;">Instance Name</th>
  <th style="border:1px solid black;">Port</th>
  <th style="border:1px solid black;">Status</th>
  <th style="border:1px solid black;">Is_Current_Owner</th>
  </tr>
  '+@rows+'
  </table>
<pre style=
"font-family:Segoe UI;
 font-size: 15px;">

Thanks and best regards...
Riyadh Airports Database mail
E  : dbmail@riyadhairports.com 
</pre>

</body>
</html>
'
exec msdb..sp_send_dbmail 
@profile_name = 'DBmailProfile', 
--@recipients = 'mabdelhalem@rac.sa', 
--@recipients = 'mabdelhalem@rac.sa;halabdullah@rac.sa', 
@recipients = 'mabdelhalem@rac.sa;halabdullah@rac.sa;shahidk@rac.sa', 
@subject = @email_subject, 
@body =  @email_body, 
@body_format = 'HTML'

end
