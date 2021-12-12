select allocated_page_file_id, cast(sum(page_free_space_percent) as float) / (cast(count(*) as float) * 100.0) * 100.0
from sys.dm_db_database_page_allocations(db_id(), object_id('dbo.LOG'), null,null,'detailed')
where is_allocated = 1
and page_type in (1)
group by allocated_page_file_id
