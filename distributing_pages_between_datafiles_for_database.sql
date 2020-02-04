exec master.dbo.sp_database_size @is_asc=0,@datafile_type = 1, @order_by = 1

use FNMPDataWarehouse
go

exec master.dbo.sp_database_size @db_name = 'AdventureWorks2014',@datafile_type = 1, @order_by = 3

use IM
go
dbcc shrinkfile (FNMPDataWarehouse, 1024)
alter database IM modify file (name='IM_2', filegrowth = 1024KB)
alter database IM modify file (name='IM_Index01', filegrowth = 1024KB, maxsize = 'unlimited')
alter database IM modify file (name='IM_Index02', filegrowth = 1024KB)


select schema_name(schema_id)+'.'+t.name table_name, case i.index_id when 0 then 'Heap' when 1 then 'Clustered' end Table_Type, master.dbo.format(max(rows),-1) rows
from sys.partitions p inner join sys.tables t
on p.object_id = t.object_id
left outer join sys.indexes i
on t.object_id = i.object_id
where i.index_id in (0,1)
group by schema_id, t.name, i.index_id
order by max(rows) desc

select master.dbo.Separator_single(current_text,' ',2) curr_object_Type, master.dbo.Separator_single(current_text,' ',3) curr_object_Name, duration,
spid, database_name, text, waittime, lastwaittype, waitresource, blocked, cmd, status, current_text
from ( 
select spid, db_name(p.dbid) database_name, s.text, waittime, lastwaittype, waitresource, blocked, 
substring(s.text, r.statement_start_offset /2, r.statement_end_offset /2) current_text, cmd,convert(varchar(30),dateadd(s,datediff(s,last_batch, getdate()), '2000-01-01'), 108) duration, r.status
from sys.sysprocesses p cross apply sys.dm_exec_sql_text(p.sql_handle)s left outer join sys.dm_exec_requests r
on p.spid = r.session_id
where spid = 137)a

select count(*), db_name(dbid) database_name
from sys.sysprocesses
where dbid > 4
group by dbid
order by count(*) desc

select 
case when index_name is not null then 'ALTER INDEX '+index_name+' ON '+schema_table_name+' REBUILD PARTITION = ALL 
WITH (
SORT_IN_TEMPDB		= ON, 
ONLINE				= '+case ver when 'Enterprise' then 'ON' when 'Developer' then 'ON' else 'OFF' end+', 
MAXDOP				= 1)' 
else 'ALTER TABLE '+schema_table_name+' REBUILD PARTITION = ALL 
WITH (
ONLINE				= '+case ver when 'Enterprise' then 'ON' when 'Developer' then 'ON' else 'OFF' end+', 
MAXDOP				= 1)'  end Rebuild_script,
table_name, index_name, type_desc, master.dbo.format(rows,-1) num_rows
from (
select '['+t.name+']' table_name, '['+i.name+']' index_name, '['+schema_name(schema_id)+'].['+t.name+']' schema_table_name, i.index_id, i.type_desc, rows, 
substring(cast(serverproperty('edition') as varchar(20)) , 1, charindex(' ', cast(serverproperty('edition') as varchar(20)))-1) ver
from sys.partitions p inner join sys.tables t
on p.object_id = t.object_id
left outer join sys.indexes i
on t.object_id = i.object_id
and p.index_id = i.index_id)a
order by rows desc, index_id

select * from sys.partitions where object_id = object_id('dbo.Monthly_B2BCRM_ALL_Orders_Closed')
select * from sys.indexes where object_id = object_id('dbo.Monthly_B2BCRM_ALL_Orders_Closed')

select 
cast(previous_page_file_id as varchar)+':'+cast(previous_page_page_id as varchar) previous_page, 
cast(allocated_page_file_id as varchar)+':'+cast(allocated_page_page_id as varchar) allocated_page, 
cast(next_page_file_id as varchar)+':'+cast(next_page_page_id as varchar) next_page, is_allocated,
is_iam_page is_iam, is_mixed_page_allocation is_mixed, page_type, page_type_desc, page_level,
index_id, allocation_unit_id, allocation_unit_type unit_id, allocation_unit_type_desc, extent_page_id,
case when is_allocated = 1 and page_type = 1 
then 'exec sp_logminer_page_reader_option2 '+''''+cast(allocated_page_file_id as varchar)+':'+cast(allocated_page_page_id as varchar)+''''+',0,'+''''+schema_name(schema_id)+'.'+object_name(dbpa.object_id)+''''+'' else null end read_page
from sys.dm_db_database_page_allocations(db_id(),object_id('dbo._CACHE_FOPP_HFO_REPEATED_TTS_Operation__'),null,null,'detailed') dbpa inner join sys.tables t
on dbpa.object_id = t.object_id



select spid, db_name(p.dbid) database_name, s.text, waittime, lastwaittype, waitresource, blocked, 
substring(s.text, r.statement_start_offset /2, r.statement_end_offset /2) current_text, cmd,convert(varchar(30),dateadd(s,datediff(s,last_batch, getdate()), '2000-01-01'), 108) duration, r.status
from sys.sysprocesses p cross apply sys.dm_exec_sql_text(p.sql_handle)s left outer join sys.dm_exec_requests r
on p.spid = r.session_id
