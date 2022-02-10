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
from '+@db_name+'.'+@table_name+' WITH (NOLOCK)
order by '+@unique_column+'
OPTION (MAXDOP 4)'

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
GO

CREATE Procedure sp_import_dump_files
(@server_ip varchar(100), @db_name varchar(300), @files_location varchar(1000))
as
begin
declare @xp_cmdshell varchar(1000)
declare 
@dump varchar(1000),
@table_name varchar(500),
@sql varchar(max), 
@from_id bigint, 
@id int

declare @table table (output_text varchar(max))
declare @export_files table (id int identity(1,1), table_name varchar(500), dump_file_name varchar(2000), from_id bigint, size float)

set nocount on
set @xp_cmdshell = 'xp_cmdshell ''dir cd '+@files_location+''''
insert into @table
exec (@xp_cmdshell)

insert into @export_files
select table_name, dump_file_name, cast(substring(from_id, 1, charindex('_',from_id)-1) as bigint) from_id, size
from (
select 
output_text dump_file_name, 
reverse(substring(reverse(output_text), charindex(reverse('_from_'),reverse(output_text))+6, len(reverse(output_text)))) table_name, 
substring(output_text, charindex('_from_',output_text)+6, len(output_text)) from_id, 
replace(rtrim(ltrim(substring(output_text_all, 1, charindex(' ',output_text_all)-1))),',','') size
from (
select substring(output_text, charindex(' ',output_text)+1, len(output_text)) output_text, output_text output_text_all
from (
select ltrim(rtrim(substring(output_text, charindex('M ', output_text)+1, len(output_text)))) output_text
from @table
where output_text like '%M %'
and output_text not like '%<DIR>%')a)b)c
order by from_id

declare i cursor fast_forward
for
select ef.id, ef.table_name, ef.dump_file_name, ef.from_id
from @export_files ef left outer join master.dbo.table_insert_log tio
on ef.table_name = tio.table_name
and ef.from_id = tio.from_id
where size > 0
order by id 

open i
fetch next from i into @id, @table_name, @dump, @from_id
while @@FETCH_STATUS = 0
begin
	begin try
		set @sql = 'xp_cmdshell ''sqlcmd -S '+@server_ip+' -E -d '+@db_name+' -i '+@files_location+'\'+@dump+''''
		print(@sql)
		exec(@sql)
		insert into master.dbo.table_insert_log (from_id,table_name,dump_file_name,[status]) values (@from_id, @table_name, @dump, 1)
	end try
	begin catch
		print(@files_location+'\'+@dump+' does not transfer.')
		insert into master.dbo.table_insert_log (from_id,table_name,dump_file_name,[status]) values (@from_id, @table_name, @dump, 0)
	end catch
fetch next from i into @id, @table_name, @dump, @from_id
end
close i
deallocate i
set nocount off
end
GO

exec [dbo].[sp_export_dump_files]
@db_name = 'ProdDEV', 
@dump_files_location = 'T:\Export',
@table_name = 'sales.salesorderdetailes',
@new_name = 'dbo.salesorderdetailes',
@migrated_to = 'MS SQL SERVER',
@columns = 'RECID,XMLRECORD',
@bulk = 10000,
@id_f = 1,
@id_t = 100

GO

exec [dbo].[sp_import_dump_files]
@server_ip = '10.10.5.65', 
@db_name = 'PROD', 
@files_location = 'T:\Export'

