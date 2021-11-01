USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_Adhoc_backup_database]    Script Date: 11/1/2021 3:02:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[sp_Adhoc_backup_database]
(@databases varchar(max), @path varchar(500))
as
begin
declare @table table (output_text varchar(max))
Declare @db_name varchar(500), @date varchar(100), @sql varchar(max)
declare i cursor fast_forward
for
select name 
from sys.databases 
where name in (select ltrim(rtrim(value)) from master.dbo.Separator(@databases,','))
order by name
open i
fetch next from i into @db_name
while @@FETCH_STATUS = 0
begin
set @date = replace(replace(replace(convert(varchar(30), getdate(), 120),'-','_'),':','_'),' ','__')
set @sql = '
BACKUP DATABASE ['+@db_name+'] 
TO DISK = N'+''''+@path+'\'+@db_name+'_Full_'+@date+'.bak'' WITH NOFORMAT, NOINIT,  
NAME = N'+''''+@db_name+'-Full Database Backup'', SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 1'

exec(@sql)
fetch next from i into @db_name
end
close i
deallocate i

end
