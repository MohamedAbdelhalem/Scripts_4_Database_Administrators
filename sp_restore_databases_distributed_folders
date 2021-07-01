USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_restore_databases_distributed_folders]    Script Date: 7/1/2021 11:43:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[sp_restore_databases_distributed_folders]
(@backup_folder varchar(300), @restore_folder_data varchar(1000), @restore_folder_log varchar(1000))
as
begin
declare @table table (output_text nvarchar(500))
declare @xp_cmdshell nvarchar(max), @backup_file_name nvarchar(1500), @path nvarchar(1000), @full_backup_file_name nvarchar(1000)
set @path = @backup_folder
set @xp_cmdshell = 'xp_cmdshell ''dir cd '+@path+''''
insert into @table
exec (@xp_cmdshell)

declare restore_cursor cursor
for
select ltrim(rtrim(substring(output_text,charindex(' ',output_text)+1, len(output_text)))) output_text
from (
select ltrim(rtrim(substring(output_text,charindex('M ',output_text)+1, len(output_text)))) output_text
from (
select ltrim(rtrim(substring(output_text,charindex(' ',output_text)+1, len(output_text)))) output_text
from @table
where output_text like '%M  %'
and output_text not like '%<DIR>%')a)b

open restore_cursor
fetch next from restore_cursor into @backup_file_name
while @@FETCH_STATUS = 0
begin
set @full_backup_file_name = @path+@backup_file_name
--'Q:\MSSQL14.MSSQLSERVER\MSSQL\DATA\'
exec [dbo].[sp_restore_database_new] 
@backupfile = @full_backup_file_name, 
@restore_loc_data = @restore_folder_data, 
@restore_loc_log = @restore_folder_log, 
@percent = 1 

fetch next from restore_cursor into @backup_file_name
end
close restore_cursor 
deallocate restore_cursor 

end
