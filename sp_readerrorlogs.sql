use master
go
Alter Procedure sp_readerrorlogs(
@text_search varchar(max) = '*',
@date_from datetime = null,
@date_to datetime = null
)
as
begin

declare @errorlogs_path varchar(200), @xp_cmdshell varchar(300), @ErrorLogsCount int, @loop int = 0, @xp_cmdshell_configured_before bit = 0
declare @table table (output_text varchar(max))
declare @errorlogs table (LogDate datetime, ProcessInfo varchar(50), Text nvarchar(max))
select @errorlogs_path = reverse(substring(reverse(errorlogfilename),charindex('\',reverse(errorlogfilename))+1, len(reverse(errorlogfilename))))
from (select cast(serverproperty('errorlogfilename') as varchar(500)) errorlogfilename)a
set @xp_cmdshell = 'xp_cmdshell ''dir cd "'+@errorlogs_path+'"'''

if (select value from sys.configurations where name = 'xp_cmdshell') = 0
exec('exec sp_configure ''xp_cmdshell'',1;reconfigure')
else
set @xp_cmdshell_configured_before = 1

insert into @table 
exec (@xp_cmdshell)

select @ErrorLogsCount = count(*) 
from (select ltrim(substring(output_text, charindex(' ',output_text)+1, len(output_text))) output_text 
from (
select ltrim(substring(output_text, charindex('M  ',output_text)+1, len(output_text))) output_text 
from @table
where output_text like '%M  %'
and output_text not like '%<DIR>%')a)b
where output_text like 'ERRORLOG%'



while @loop < @ErrorLogsCount
begin
insert into @errorlogs
exec sp_readerrorlog @loop
set @loop = @loop + 1
end

if @text_search = '*' and @date_from is null
begin
select * 
  from @errorlogs 
end
else if @text_search = '*' and @date_from is not null
begin
select * 
  from @errorlogs 
 where LogDate between @date_from and @date_to
end
else if @text_search != '*' and @date_from is null
begin
select * 
  from @errorlogs 
 where text like '%'+@text_search+'%'
end
else if @text_search != '*' and @date_from is not null
begin
select * 
  from @errorlogs 
 where text like '%'+@text_search+'%'
 and LogDate between @date_from and @date_to
end

if @xp_cmdshell_configured_before = 0
exec('exec sp_configure ''xp_cmdshell'',0;reconfigure')

end
