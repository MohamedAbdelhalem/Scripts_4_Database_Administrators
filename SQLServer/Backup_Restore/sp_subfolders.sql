CREATE Procedure sp_subfolders
(@location nvarchar(1000) = '\\nfs.d2fs.company.com\DB_Backup_Arch\2010-2019')
as
begin
declare 
@xp_cmdshell nvarchar(2000), @level int = 0, @dynamic_cursor varchar(max)

CREATE Table #root_folder (output_text nvarchar(max), level_id int, root_folder nvarchar(1000), index inx_level_id (level_id))

set nocount on
set @xp_cmdshell = 'xp_cmdshell '+''''+'dir cd '+@location+''''
declare @root_folder table (output_text nvarchar(max), level_id int, root_folder nvarchar(1000), index inx_level_id (level_id))
insert into #root_folder (output_text)
exec(@xp_cmdshell)

update #root_folder set level_id = 1, root_folder = @location where level_id is null

declare @first_level int, @last_level int, @exit bit = 0

while @exit = 0 
begin
set @level = @level + 1
select @first_level = max(level_id) from #root_folder
set @dynamic_cursor = '
declare @id int, @folder_name nvarchar(1000), @root_folder_name nvarchar(3000), @xp_cmdshell nvarchar(2000)
declare level_s_cursor cursor fast_forward
for
select row_number() over(partition by root_folder order by name) id, name, root_folder
from (
select ltrim(rtrim(substring(output_text, 1, charindex(''>'',output_text)))) [type], ltrim(rtrim(substring(output_text, charindex('' '',output_text), len(output_text)))) [name], level_id, root_folder
from (
select ltrim(rtrim(substring(output_text, charindex(''M '',output_text)+2, len(output_text)))) output_text, '+cast(@level as varchar)+' level_id, root_folder
from #root_folder
where output_text like ''%M %''
and (output_text not like ''%<DIR>%.%'' and output_text not like ''%<DIR>%..%'')
and output_text like ''%<DIR>%''
and level_id > '+cast(@level as varchar)+' - 1)a)b
order by root_folder, id

open level_s_cursor
fetch next from level_s_cursor into @id, @folder_name, @root_folder_name
while @@FETCH_STATUS = 0
begin

set @xp_cmdshell = ''xp_cmdshell '+''''+''''+'dir cd ''+@root_folder_name+''\''+@folder_name+''''''''
insert into #root_folder (output_text)
exec(@xp_cmdshell)

update #root_folder set level_id = '+cast(@level as varchar)+' + 1, root_folder = @root_folder_name+''\''+@folder_name where level_id is null

fetch next from level_s_cursor into @id, @folder_name, @root_folder_name
end
close level_s_cursor
deallocate level_s_cursor'
exec(@dynamic_cursor)
select @last_level = max(level_id) from #root_folder

if @first_level = @last_level
begin
	set @exit = 1
end
end

select [path], level_id
from (
select row_number() over(partition by root_folder order by name) id, root_folder+'\'+name [path], level_id
from (
select ltrim(rtrim(substring(output_text, 1, charindex('>',output_text)))) [type], ltrim(rtrim(substring(output_text, charindex(' ',output_text), len(output_text)))) [name], level_id, root_folder
from (
select ltrim(rtrim(substring(output_text, charindex('M ',output_text)+2, len(output_text)))) output_text, level_id, root_folder
from #root_folder
where output_text like '%M %'
and (output_text not like '%<DIR>%.%' and output_text not like '%<DIR>%..%')
and output_text like '%<DIR>%')a)b)c
order by path

end
