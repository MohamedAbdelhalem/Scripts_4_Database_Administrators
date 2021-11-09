CREATE procedure [dbo].[sp_download_file]
(@id varchar(max), @file_name varchar(300), @extention varchar(50), @path varchar(max))
as
begin

declare 
@file varbinary(max),
@objectToken int,
@newPath varchar(max)

select @file = PDF_Column
from [Table_name]
where referenceID = @id

set @newPath = @path+'\'+@file_name+@extention
exec sp_OACreate 'ADODB.Stream', @objectToken output
exec sp_OASetProperty @objectToken, 'Type', 1
exec sp_OAMethod @objectToken, 'Open'
exec sp_OAMethod @objectToken, 'Write', NULL, @file
exec sp_OAMethod @objectToken, 'SaveToFile', NULL, @newPath, 2
exec sp_OAMethod @objectToken, 'Close'
exec sp_OADestroy @objectToken

end
