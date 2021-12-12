exec master.dbo.sp_database_size @is_asc=0,@datafile_type = 1, @order_by = 1
exec master.dbo.sp_database_size @db_name = 'AdventureWorks2014',@datafile_type = 1, @order_by = 3

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


select (select cast(pct as varchar)+'%' pct from (
select 
round(cast(100 as float)/cast((select count(distinct isnull(i.name,'')+t.name) from sys.indexes i inner join sys.tables t on i.object_id = t.object_id) as float) *id,2) pct, 
table_name, index_name 
from (
select top 100 percent row_number() over(order by sum(rows) desc) id, sum(rows) rows, '['+schema_name(t.schema_id)+'].['+t.name+']' table_name, '['+i.name+']' index_name
from sys.indexes i inner join sys.tables t
on i.object_id = t.object_id
inner join sys.partitions p
on p.object_id = t.object_id
and p.index_id = i.index_id
group by t.schema_id, t.name, i.name
order by sum(rows) desc)a)b where index_name = [session].curr_object_Name) pct, [session].*
from (
select master.dbo.Separator_single(current_text,' ',2) curr_object_Type, master.dbo.Separator_single(current_text,' ',3) curr_object_Name, duration,
spid, database_name, text, waittime, lastwaittype, waitresource, blocked, cmd, status, current_text
from ( 
select spid, db_name(p.dbid) database_name, s.text, waittime, lastwaittype, waitresource, blocked, 
substring(s.text, r.statement_start_offset /2, r.statement_end_offset /2) current_text, cmd,convert(varchar(30),dateadd(s,datediff(s,last_batch, getdate()), '2000-01-01'), 108) duration, r.status
from sys.sysprocesses p cross apply sys.dm_exec_sql_text(p.sql_handle)s left outer join sys.dm_exec_requests r
on p.spid = r.session_id
where spid = 302)a) [session]

select table_name, index_name, schema_table_name, type_desc, ver, master.dbo.format(rows,-1) r_o_w_s 
from (
select table_name, index_name, schema_table_name, type_desc, ver, sum(rows) rows 
from (
select '['+t.name+']' table_name, '['+i.name+']' index_name, '['+schema_name(schema_id)+'].['+t.name+']' schema_table_name, i.type_desc, rows, 
substring(cast(serverproperty('edition') as varchar(20)) , 1, charindex(' ', cast(serverproperty('edition') as varchar(20)))-1) ver
from sys.partitions p inner join sys.tables t with (nolock)
on p.object_id = t.object_id
left outer join sys.indexes i
on t.object_id = i.object_id
and p.index_id = i.index_id)a
group by table_name, index_name, schema_table_name, type_desc, ver)b
order by rows desc


#######################################################################################################
declare @table table (id int, drive varchar(10))
insert into @table values (1,'w'),(2,'v'),(3,'u'),(4,'t')

select replace(replace(sql_add_file,'#',cast(t.id as varchar(50))),'@', drive)
from (
select row_number() over (order by sql_add_file) id, sql_add_file
from (
select 'alter database ['+
db_name(database_id)+'] add file (name='+''''+name+'_#'+''''+', filename='+''''+'@'+substring(physical_name,2,len(physical_name)-5)+'_#.ndf'+''''+', size='+
cast(size*8 as varchar(20))+'kb, filegrowth='+cast(growth*8 as varchar(20))+'kb, maxsize = unlimited)' sql_add_file
from sys.master_files
where database_id in (18)
and file_id = 1
union
select 'alter database ['+
db_name(database_id)+'] add file (name='+''''+name+'_#'++''''+', filename='+''''+'@'+substring(physical_name,2,len(physical_name)-5)+'_#.ndf'+''''+', size='+
cast(size*8 as varchar(20))+'kb, filegrowth='+cast(growth*8 as varchar(20))+'kb, maxsize = unlimited)'
from sys.master_files
where database_id in (18)
and file_id = 1
union
select 'alter database ['+
db_name(database_id)+'] add file (name='+''''+name+'_#'++''''+', filename='+''''+'@'+substring(physical_name,2,len(physical_name)-5)+'_#.ndf'+''''+', size='+
cast(size*8 as varchar(20))+'kb, filegrowth='+cast(growth*8 as varchar(20))+'kb, maxsize = unlimited)'
from sys.master_files
where database_id in (18)
and file_id = 1
union
select 'alter database ['+
db_name(database_id)+'] add file (name='+''''+name+'_#'++''''+', filename='+''''+'@'+substring(physical_name,2,len(physical_name)-5)+'_#.ndf'+''''+', size='+
cast(size*8 as varchar(20))+'kb, filegrowth='+cast(growth*8 as varchar(20))+'kb, maxsize = unlimited)'
from sys.master_files
where database_id in (18)
and file_id = 1)a)b cross apply @table t
#######################################################################################################

use [database name]
go
select 
isnull(a.database_id,'') database_id, 
isnull(a.database_name,'') database_name, 
master.dbo.numberSize(b.size,'k') size, 
isnull(file_growth,'') file_growth,
master.dbo.numberSize(b.used,'k') used,
master.dbo.numberSize(b.free,'k') free,
isnull(a.name,'') logical_name, isnull(a.physical_name,'') physical_name
from (
select 
sum(cast(size as float)*8) size, 
sum(cast(FILEPROPERTY(name, 'spaceused') as float)) used,
sum((cast(size as float)*8) - (cast(FILEPROPERTY(name, 'spaceused') as float))) free,
name, grouping(name) g
from sys.master_files
where database_id = db_id()
and file_id != 2
group by name with rollup)b left outer join (
select database_id,
db_name(database_id) database_name, 
master.dbo.numberSize(growth*8,'k') file_growth,
name, physical_name
from sys.master_files
where database_id = db_id()
and file_id != 2)a
on b.name = a.name
