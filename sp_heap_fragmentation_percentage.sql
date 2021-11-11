/*
PFS page is tracking the LOB pages and heap tables free space, so i am choosing to using those pfs pages to get all pages with 
the full utilization allocation pages and compare them with the sys.dm_db_database_page_allocations table-values build-in function 
to match the belonged pages of the heap table to calculate the used space of the table.

note. this is why there are contentions in Tempdb because the PFS pages, because PFS pages are used for tracking the heap tables and of course 99.0%
of the #tables are heap.
*/

CREATE Procedure sp_heap_fragmentation_percentage
(@pfss int = 6, @Heap_Table varchar(100))
as
begin
declare @pfs table (id int identity(1,1), ParentObject varchar(100), object varchar(100), Field varchar(100), VALUE varchar(100))
declare @mapping_tab table (id int identity(1,1), file_id int, page_id int primary key, free_space varchar(100), page_status varchar(100))
declare @mp int, @pages varchar(100), @free_space varchar(100), @page_status varchar(100)
declare @loop int = 0, @min_page int, @max_page int, @file_id int, @sql varchar(500), @pfs_page varchar(20)

while @loop < @pfss + 1
begin
select @pfs_page = iif(@loop = 0, 1, 8088 * @loop)
set @sql = 'dbcc page (0,1,'+@pfs_page+',3) with tableresults'
insert into @pfs (ParentObject, object, Field, VALUE)
exec (@sql)
set @loop = @loop + 1
end

declare pages cursor fast_forward
for
select multi_pages, field, 
ltrim(rtrim(reverse(substring(reverse([VALUE]), 1, charindex('D',reverse([VALUE]))-1)))) free_space,
ltrim(rtrim(substring([VALUE], 1, charindex('D',[VALUE])))) page_status
from (
select id, 
case when Field like '%- (%' then 1 else 0 end multi_pages, 
ltrim(rtrim(replace(replace(replace(Field,'-',','),')',''),'(',''))) Field,
ltrim(rtrim(substring([VALUE], 1, charindex('FULL',[VALUE])+len('FULL')))) [VALUE]
from @pfs 
where object like 'PFS: Page Alloc Status%')a
order by id

open pages
fetch next from pages into @mp, @pages,@free_space, @page_status
while @@fetch_status = 0
begin
if @mp = 0
begin
insert into @mapping_tab values (
ltrim(rtrim([dbRecovery].[dbo].[Separator_Single](replace(@pages,',',''),':',1))), 
ltrim(rtrim([dbRecovery].dbo.Separator_Single(replace(@pages,',',''),':',2))), 
@free_space, @page_status)
end
else
begin
set @loop = 0
select 
@file_id = max([dbRecovery].[dbo].[Separator_Single](ltrim(rtrim(value)),':',1)),
@min_page = min([dbRecovery].[dbo].[Separator_Single](ltrim(rtrim(value)),':',2)),
@max_page = max([dbRecovery].[dbo].[Separator_Single](ltrim(rtrim(value)),':',2))
from [dbRecovery].[dbo].[Separator](@pages,',')

while @loop < @max_page - @min_page + 1
begin
insert into @mapping_tab values (
@file_id, 
@min_page + @loop, 
@free_space, @page_status)
set @loop = @loop + 1
end
end

fetch next from pages into @mp, @pages, @free_space, @page_status
end
close pages
deallocate pages

select * into #mapping_tab from @mapping_tab
create nonclustered index idex_page_id_mapping_tab on #mapping_tab (page_id) include (id, free_space, page_status)

select index_id, 
case when index_id = 0 then 'heap' when index_id = 1 then 'clustered' when index_id > 1 then 'nonclustered' end [type], pct_full, 
case when index_id = 0 then 100 - pct_full else 0 end pct_framgent
from (
select index_id, case when index_id = 0 then round(cast(sum(used) as float) / cast(total as float) * 100.0, 2) else 0 end pct_full
from (
select page_id, index_id, cast(replace(free_space,'_PCT_FULL','') as int) used, count(*) over() * 100 total
from #mapping_tab t inner join sys.dm_db_database_page_allocations(db_id(),object_id(@Heap_Table),null,null,'detailed') p
on t.page_id = p.allocated_page_page_id
and t.file_id = p.allocated_page_file_id)a
group by index_id, total)b

select index_id, allocation_unit_type_desc, page_level, page_type_desc, page_id, allocated_page_page_id, free_space, page_free_space_percent, is_allocated, t.page_status
from #mapping_tab t inner join sys.dm_db_database_page_allocations(db_id(),object_id(@Heap_Table),null,null,'detailed') p
on t.page_id = p.allocated_page_page_id

drop table #mapping_tab

end
