set transaction isolation level read uncommitted
select * from (
select top 10 percent
t.name Table_Name, isnull(i.name, 'HEAP') Index_Name, master.dbo.format(ap.rows,-1) Rows,
master.dbo.numbersize(ap.total_pages*8,'K') total_pages,
master.dbo.numbersize(ap.used_pages*8,'K') used_pages,
master.dbo.numbersize(ap.data_pages*8,'K') data_pages
from (
select p.partition_id, p.object_id, p.index_id, p.rows, 
sum(a.total_pages) total_pages, sum(a.used_pages) used_pages, sum(a.data_pages) data_pages
from sys.partitions p inner join sys.allocation_units a
on (a.type in (1,3) and a.container_id = p.hobt_id
or a.type = 2 and a.container_id = p.partition_id)
group by p.partition_id, p.object_id, p.index_id, p.rows) ap
inner join sys.tables t
on ap.object_id = t.object_id
inner join sys.indexes i
on  ap.index_id = i.index_id
and t.object_id = i.object_id
order by ap.total_pages desc)a
where Table_Name like '%WILD%'


use tempdb
go
set transaction isolation level read uncommitted

select 
t.name Table_Name, master.dbo.format(max(rows),-1) Rows,
master.dbo.numbersize(sum(ap.total_pages)*8,'K') total_pages,
master.dbo.numbersize(sum(ap.used_pages)*8,'K') used_pages,
master.dbo.numbersize(sum(ap.data_pages)*8,'K') data_pages
from (
select p.partition_id, p.object_id, p.index_id, p.rows, 
sum(a.total_pages) total_pages, sum(a.used_pages) used_pages, sum(a.data_pages) data_pages
from sys.partitions p inner join sys.allocation_units a
on (a.type in (1,3) and a.container_id = p.hobt_id
or a.type = 2 and a.container_id = p.partition_id)
group by p.partition_id, p.object_id, p.index_id, p.rows) ap
inner join sys.tables t
on ap.object_id = t.object_id
inner join sys.indexes i
on  ap.index_id = i.index_id
and t.object_id = i.object_id
group by t.name 
order by sum(ap.total_pages) desc

exec master.dbo.sp_database_size 'tempdb'
select * from sys.dm_db_file_space_usage
