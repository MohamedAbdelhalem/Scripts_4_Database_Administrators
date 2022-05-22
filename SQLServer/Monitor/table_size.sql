declare @all char(1) = '*'
declare @tables varchar(max) = 'FBNK_ACCT_ENT_LWORK_DAY'
declare 
@values	varchar(max), 
@loop	int = 0

	if exists (select name from tempdb.sys.tables where name like '#table___%')
	begin
		drop table #table
	end
	create table #table (objectid bigint)

if @all = '*'
begin
	insert into #table
	select object_id 
	from sys.tables 
end
else
begin
	insert into #table
	select object_id 
	from sys.tables where object_id in (select object_id(ltrim(rtrim(value))) from master.[dbo].[Separator](@tables,','))
end

select --top 200
t.name, '['+schema_name(schema_id)+'].['+t.name+']' table_name, master.dbo.format(max(rows),-1) rows, case when g.name is null then ps.type_desc else 'FILEGROUP' end fg_type, 
isnull(g.name,ps.name) scheme_filegroup,
master.dbo.numbersize(sum(total_pages) * 8, 'kb') total_pages,
master.dbo.numbersize(sum(used_pages) * 8, 'kb') used_pages,
master.dbo.numbersize((sum(total_pages) - sum(used_pages)) * 8, 'kb') unused_pages,
master.dbo.numbersize(sum(data_pages) * 8, 'kb') data_pages,
master.dbo.numbersize((sum(total_pages) - sum(data_pages) - (sum(total_pages) - sum(used_pages))) * 8.0, 'kb') index_pages
from sys.partitions p inner join sys.allocation_units a
on (a.type in (1,3) and a.container_id = p.hobt_id)
or (a.type = 2 and a.container_id = p.partition_id)
inner join sys.tables t
on p.object_id = t.object_id
inner join sys.indexes i
on i.object_id = p.object_id
and i.index_id = p.index_id
left join sys.filegroups g
on i.data_space_id = g.data_space_id
left join sys.partition_schemes ps
on i.data_space_id = ps.data_space_id
where p.object_id in (select objectid from #table)
--and g.name = 'DATAFG'
group by schema_id, t.name, g.name, ps.name, ps.type_desc
order by sum(total_pages) desc
option (querytraceon 8649)

drop table #table

