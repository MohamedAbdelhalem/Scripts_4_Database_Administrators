USE [master]
GO
CREATE Procedure [dbo].[kill_sessions_before_restore]
(@db_name varchar(400))
as
begin
declare @kill varchar(50)
declare k cursor fast_forward
for
select 'kill '+cast(spid as varchar)
from sys.sysprocesses 
where dbid = db_id(@db_name)

open k
fetch next from k into @kill
while @@FETCH_STATUS = 0
begin
exec(@kill)
fetch next from k into @kill
end
close k
deallocate k
end

