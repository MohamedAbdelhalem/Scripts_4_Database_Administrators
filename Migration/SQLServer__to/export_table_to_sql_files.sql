use [master]
GO
CREATE TABLE [dbo].[table_insert_log](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[from_id] [bigint] NULL,
	[table_name] [varchar](500) NULL,
	[dump_file_name] [varchar](2000) NULL,
	[date_time] [datetime] NULL,
	[status] [bit]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[table_insert_log] ADD  DEFAULT (getdate()) FOR [date_time]
ALTER TABLE [dbo].[table_insert_log] ADD  DEFAULT ((1)) FOR [status]
GO

CREATE Procedure [dbo].[sp_export_dump_files](
@db_name				varchar(300), 
@dump_files_location	varchar(1000),
@table_name				varchar(500),
@new_name				varchar(500),
@migrated_to			varchar(100),
@columns				varchar(3000),
@bulk					bigint,
@top					varchar(50) = 'all',
@id_f					bigint,
@id_t					bigint)
as
begin
declare 
@from_unique_column varchar(300), @to_unique_column varchar(300), 
@from_id bigint, @to_id bigint, 
@bcp_sql varchar(4000), 
@unique_column varchar(300)

set nocount on
declare @dynamic_sql varchar(max)
declare @table table (id int primary key, recid varchar(255))

CREATE TABLE #table_summary(
[id] [int] NOT NULL,
[unique_id] [int] NULL,
[from_id] [bigint] NULL,
[to_id] [bigint] NULL,
[from_unique_column] [varchar](500) NULL,
[to_unique_column] [varchar](500) NULL,
PRIMARY KEY CLUSTERED  ([id] ASC))

set @dynamic_sql = '
select '+case when @top = 'all' then '' else 'TOP ('+@top+')' end +' row_number() over(order by '+@unique_column+') id, '+@unique_column+'
from '+@db_name+'.'+@table_name+'
order by '+@unique_column

print (@dynamic_sql)
insert into @table 
exec (@dynamic_sql)

insert into #table_summary 
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

declare exp_cur cursor fast_forward
for
select 
from_id, to_id, from_unique_column, to_unique_column 
from #table_summary 
where id between @id_f and @id_t
order by id 

set nocount on
open exp_cur
fetch next from exp_cur into @from_id, @to_id, @from_unique_column, @to_unique_column
while @@FETCH_STATUS = 0
begin

set @bcp_sql = 'bcp "exec [dbo].[sp_dump_table] @table = '+''''+@table_name+''''+', @new_name = '+''''+@new_name+''''+', @columns = '+''''+@columns+''''+', @where_records_condition = ''where [recid] between '+''''+''''+@from_unique_column+''''+''''+' and '+''''+''''+@to_unique_column+''''+''''+' order by [recid]'',@with_computed = 0, @header = 0, @bulk = '+cast(@bulk+5 as varchar(50))+'" queryout "'+@dump_files_location+'\'+@table_name+'_from_'+cast(@from_id as varchar(50))+'_to_'+cast(@to_id as varchar(50))+'.sql"  -d '+@db_name+' -T -n -c'
print @bcp_sql
exec xp_cmdshell @bcp_sql

fetch next from exp_cur into @from_id, @to_id, @from_unique_column, @to_unique_column
end
close exp_cur
deallocate exp_cur
set nocount off

end
