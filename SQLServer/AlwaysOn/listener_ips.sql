select dns_name, case id when 1 then 'Primary' else 'Secondary' end DC, ltrim(rtrim(replace(replace(replace(substring(value,charindex(': ',value)+2,len(value)),')',''),'(',''),'''',''))) Listener_ips, 
port, ip_configuration_string_from_cluster 
from sys.availability_group_listeners agl cross apply master.[dbo].[Separator](ip_configuration_string_from_cluster,'or')

select 
case when charindex('\',replica_server_name) > 0 then substring(replica_server_name, 1, charindex('\',replica_server_name)-1) else replica_server_name end server_name,
reverse(substring(reverse(endpoint_url),1, charindex(':',reverse(endpoint_url))-1)) mirroring_port, 
endpoint_url 
from sys.availability_replicas


