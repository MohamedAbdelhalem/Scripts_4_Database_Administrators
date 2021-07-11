CREATE PROCEDURE [dbo].[BulkImportCsvFolder]
(@path varchar(1500))
as
begin
set nocount on
declare @table1 table (output_text varchar(max))
declare @table2 table ([file_name] varchar(500))

declare @count int, @pct float, @loop int = 1, @prev int = 0, @prog int = 1

declare @xp_cmdshell varchar(500), @file_name varchar(1000)
set @xp_cmdshell = 'xp_cmdshell ''dir cd "'+@path+'"'''
insert into @table1 exec (@xp_cmdshell)

insert into @table2
select substring(output_text, charindex(' ', output_text)+1, len(output_text)) file_name
from (
select rtrim(ltrim(substring(output_text, charindex('M  ',output_text)+1,len(output_text)))) output_text
from @table1
where output_text like '%M  %'
and output_text not like '%<DIR>%')a

select @count = count(*) 
from @table2
where reverse(substring(reverse([file_name]),charindex('.',reverse([file_name]))+1, len(reverse([file_name])))) not in (select name from sys.tables) 

set @pct = 100.00 / cast(@count as float)

declare importedFiles_Cursor cursor fast_forward
for
select @path+case when right(@path,1) != '\' then '\' else '' end+[file_name] 
from @table2
where reverse(substring(reverse([file_name]),charindex('.',reverse([file_name]))+1, len(reverse([file_name])))) not in (select name from sys.tables) 
order by [file_name]

open importedFiles_Cursor 
fetch next from importedFiles_Cursor into @file_name
while @@FETCH_STATUS = 0
begin

BEGIN TRY
EXEC BulkImportCsvFile @file_name, 2
SET @prog = Ceiling(@pct * @loop)
IF @prev != @prog
PRINT(@prog)
SET @loop = @loop + 1
SET @prev = @prog

END TRY
BEGIN CATCH
PRINT(@file_name+' has a problem and did''t import successfully.')
END CATCH

fetch next from importedFiles_Cursor into @file_name
end
close importedFiles_Cursor 
deallocate importedFiles_Cursor 

set nocount off
end
