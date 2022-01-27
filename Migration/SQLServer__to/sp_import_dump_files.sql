--create first a table to log and to avoid insert the dump files twice
CREATE TABLE [dbo].[table_insert_log](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[from_id] [bigint] NULL,
	[dump_file_name] [varchar](2000) NULL,
	[date_time] [datetime] NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[table_insert_log] ADD  DEFAULT (getdate()) FOR [date_time]
GO

CREATE Procedure sp_import_dump_files
(@server_ip varchar(100), @db_name varchar(300), @files_localtion varchar(1000))
as
begin
declare @xp_cmdshell varchar(1000)
declare @table table (output_text varchar(max))
declare @export_files table (id int identity(1,1), dump_file_name varchar(2000), from_id bigint)
set nocount on
set @xp_cmdshell = 'xp_cmdshell ''dir cd '+@files_localtion+'''
insert into @table
exec (@xp_cmdshell)

insert into @export_files
select output_Text dump_file_name, cast(substring(from_id, 1, charindex('_',from_id)-1) as bigint) from_id
from (
select output_text, substring(output_text, charindex('_from_',output_text)+6, len(output_text)) from_id
from (
select substring(output_text, charindex(' ',output_text)+1, len(output_text)) output_text
from (
select ltrim(rtrim(substring(output_text, charindex('M ', output_text)+1, len(output_text)))) output_text
from @table
where output_text like '%M %'
and output_text not like '%<DIR>%')a)b)c
order by from_id

declare @dump varchar(1000), @sql varchar(max), @from_id bigint, @count_of_files int, @id int
declare i cursor fast_forward
for
select id, dump_file_name, from_id, count(*) over()
from @export_files
where from_id not in (select from_id from msdb.dbo.table_insert_log)
order by id 

open i
fetch next from i into @id, @dump, @from_id, @count_of_files
while @@FETCH_STATUS = 0
begin
if @id != @count_of_files
begin
	set @sql = 'xp_cmdshell ''sqlcmd -S '+@server_ip+' -E -d '+@db_name+' -i '+@files_location+'\'+@dump+''''
	print(@sql)
	exec(@sql)
	insert into msdb.dbo.table_insert_log (from_id,dump_file_name) values (@from_id, @dump)
end
fetch next from i into @id, @dump, @from_id, @count_of_files
end
close i
deallocate i
set nocount off
end

GO

select a.id, msdb.dbo.format(a.from_id,-1) fromid, a.dump_file_name, 
a.date_time time_a, b.date_time time_b, convert(varchar(30), dateadd(s,datediff(s, a.date_time, b.date_time),'2000-01-01'),108) duration
from msdb.dbo.table_insert_log a left outer join msdb.dbo.table_insert_log b
on a.id + 1 = b.id
--order by duration desc --check the bulk insert speed
order by a.date_time 

