USE [master]
GO
CREATE TABLE [dbo].[Database_create](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[database_name] [varchar](500) NULL,
	[flag] [int] NULL,
	[create_date] [datetime] NULL,
	[server_name] [varchar](500) NULL,
	[login_name] [varchar](500) NULL,
	[instance_type] [varchar](100) NULL,
	[availability_group] [varchar](200) NULL
) ON [PRIMARY]
GO

CREATE trigger [audit_database_creation]
on all server
for create_database
as
begin
set nocount on
insert into Database_create (database_name, flag, create_date, server_name, login_name, instance_type, availability_group)
select 
EVENTDATA().value('(/EVENT_INSTANCE/DatabaseName)[1]','nvarchar(max)'),
0, getdate(),
EVENTDATA().value('(/EVENT_INSTANCE/ServerName)[1]','nvarchar(max)'),
EVENTDATA().value('(/EVENT_INSTANCE/LoginName)[1]','nvarchar(max)'),
(select role_desc 
from sys.dm_hadr_availability_replica_states
where is_local = 1),
(select group_name 
from sys.dm_hadr_availability_replica_cluster_nodes
where replica_server_name = (select name from sys.servers where server_id = 0))

set nocount off
end
GO

ENABLE TRIGGER [audit_database_creation] ON ALL SERVER
GO

CREATE Procedure [dbo].[sp_add_database_AOAG]    
(@db_name varchar(500), @server_name varchar(500), @aGroup_name varchar(500))    
as    
begin    
declare @sql varchar(max)    
    
set @sql ='    
ALTER AVAILABILITY GROUP ['+@aGroup_name+']    
MODIFY REPLICA ON N'+''''+@server_name+''''+' WITH (SEEDING_MODE = MANUAL)'    
--print (@sql)    
exec (@sql)    
    
set @sql ='    
ALTER AVAILABILITY GROUP ['+@aGroup_name+']    
ADD DATABASE ['+@db_name+']'    
--print (@sql)    
exec (@sql)    
      
end 
GO

CREATE Procedure [dbo].[sp_backup_database]    
(@backup_file_name varchar(2000) output, @db_name varchar(500), @path varchar(500))    
as    
begin    
declare @table table (output_text varchar(max))    
Declare @date varchar(100), @sql varchar(max)    
    
set @date = replace(replace(replace(convert(varchar(30), getdate(), 120),'-','_'),':','_'),' ','__')    
set @sql = '    
BACKUP DATABASE ['+@db_name+']     
TO DISK = N'+''''+@path+'\'+@db_name+'_Full_'+@date+'.bak'' WITH NOFORMAT, NOINIT,      
NAME = N'+''''+@db_name+'-Full Database Backup'', SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 1'    
--print(@sql)    
exec(@sql)    
    
set @sql = '    
BACKUP LOG ['+@db_name+']     
TO DISK = N'+''''+@path+'\'+@db_name+'_Full_'+@date+'.bak'' WITH NOFORMAT, NOINIT,      
NAME = N'+''''+@db_name+'-Log Database Backup'', SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 1'    
--print(@sql)    
exec(@sql)    
    
set @backup_file_name = @path+'\'+@db_name+'_Full_'+@date+'.bak'    
end    

GO

CREATE Procedure [dbo].[sp_change_db_recovery]  
(@db_name varchar(500))  
as  
begin  
declare @sql varchar(max)  
set @sql = 'ALTER DATABASE ['+@db_name+'] SET RECOVERY FULL WITH NO_WAIT'   
exec(@sql)
end  

GO

CREATE Procedure [dbo].[sp_restore_database_AOAG]      
(      
@backupfile    varchar(max),       
@filenumber    varchar(5) = 'all',       
@restore_loc_sameLoc bit = 1,      
@restore_loc   varchar(500) = 'default',      
@restore_loc_data  varchar(500) = 'default',      
@restore_loc_log  varchar(500) = 'default',      
@with_recovery   bit = 1,        
@new_db_name   varchar(500) = 'default',      
@percent    int = 5,      
@password    varchar(100) = 'default')      
as      
begin       
declare @restor_loc_table  table (output_text varchar(max))      
declare @restor_loc_table_data table (output_text varchar(max))      
declare @restor_loc_table_log table (output_text varchar(max))      
declare @xp_cmdshell varchar(500),       
@files_exist int,       
@files_exist_data int,       
@files_exist_log int,       
@file_type varchar(5)      
declare       
@sql     varchar(max),       
@file_move    varchar(max),       
@file_move_data   varchar(max),       
@file_move_log   varchar(max),       
@file     int,       
@version    int,      
@logicalname   varchar(500),       
@originalpath   varchar(max),       
@physicalname   varchar(500),      
@ext     varchar(10),      
@unique_id    varchar(10),      
@Position    int,       
@DatabaseName   varchar(500),       
@BackupType    int,      
@lastfile    int      
      
declare @headeronly table (      
BackupName    nvarchar(512),      
BackupDescription  nvarchar(255),      
BackupType    smallint,      
ExpirationDate    datetime,      
Compressed    int,      
Position     smallint,      
DeviceType     tinyint,      
UserName     nvarchar(128),      
ServerName     nvarchar(128),      
DatabaseName    nvarchar(512),      
DatabaseVersion   int,      
DatabaseCreationDate  datetime,      
BackupSize     numeric(20,0),      
FirstLSN     numeric(25,0),      
LastLSN     numeric(25,0),      
CheckpointLSN    numeric(25,0),      
DatabaseBackupLSN   numeric(25,0),      
BackupStartDate   datetime,      
BackupFinishDate   datetime,      
SortOrder     smallint,      
CodePage     smallint,      
UnicodeLocaleId   int,      
UnicodeComparisonStyle  int,      
CompatibilityLevel   tinyint,      
SoftwareVendorId   int,      
SoftwareVersionMajor  int,      
SoftwareVersionMinor  int,      
SoftwareVersionBuild  int,      
MachineName    nvarchar(128),      
Flags      int,      
BindingID     uniqueidentifier,      
RecoveryForkID   uniqueidentifier,      
Collation     nvarchar(128),      
FamilyGUID     uniqueidentifier,      
HasBulkLoggedData   bit,      
IsSnapshot    bit,      
IsReadOnly    bit,      
IsSingleUser    bit,      
HasBackupChecksums  bit,      
IsDamaged     bit,      
BeginsLogChain    bit,      
HasIncompleteMetaData  bit,      
IsForceOffline    bit,      
IsCopyOnly     bit,      
FirstRecoveryForkID  uniqueidentifier,      
ForkPointLSN    numeric(25,0),      
RecoveryModel    nvarchar(60),      
DifferentialBaseLSN  numeric(25,0),      
DifferentialBaseGUID  uniqueidentifier,      
BackupTypeDescription  nvarchar(60),      
BackupSetGUID    uniqueidentifier,      
CompressedBackupSize  bigint,      
containment    tinyint,      
KeyAlgorithm    nvarchar(32)  default NULL,      
EncryptorThumbprint  varbinary(20)  default NULL,      
EncryptorType    nvarchar(32))      
      
declare @filelistonly table (      
LogicalName    varchar(1000),      
PhysicalName   varchar(max),      
Type     varchar(5),      
col01 varchar(max),col02 varchar(max),col03 varchar(max),col04 varchar(max),      
col05 varchar(max),col06 varchar(max),col07 varchar(max),col08 varchar(max),      
col09 varchar(max),col10 varchar(max),col11 varchar(max),col12 varchar(max),      
col13 varchar(max),col14 varchar(max),col15 varchar(max),col16 varchar(max),      
col17 varchar(max),col18 varchar(max),col19 varchar(max))      
      
set nocount on      
if @password = 'default'      
begin      
set @sql = 'restore filelistonly from disk = '+''''+@backupfile+''''      
end      
else      
begin      
set @sql = 'restore filelistonly from disk = '+''''+@backupfile+''''+' with file = 1, mediapassword = '+''''+@password+''''      
end      
      
--restore filelistonly from disk = 'm:\backup_database\Backup_database_migration\wslogdb70_110_Full_2021_06_27__16_38_37.bak'      
      
--print(@sql)      
insert into @filelistonly       
exec(@sql)      
      
if @password = 'default'      
begin      
set @sql = 'restore headeronly from disk = '+''''+@backupfile+''''      
end      
else      
begin      
set @sql = 'restore headeronly from disk = '+''''+@backupfile+''''+' with file = 1, mediapassword = '+''''+@password+''''      
end      
      
select @version = case       
when @@version like '%SQL Server 2008%' then 10       
when @@version like '%SQL Server 2012%' then 11       
when @@version like '%SQL Server 2014%' then 12       
when @@version like '%SQL Server 2016%' then 13       
when @@version like '%SQL Server 2017%' then 14       
when @@version like '%SQL Server 2019%' then 15       
end      
      
if @version = 10      
begin      
insert into @headeronly (      
BackupName,BackupDescription,BackupType,ExpirationDate,Compressed,Position,DeviceType,UserName,ServerName,      
DatabaseName,DatabaseVersion,DatabaseCreationDate,BackupSize,FirstLSN,LastLSN,CheckpointLSN,DatabaseBackupLSN,      
BackupStartDate,BackupFinishDate,SortOrder,CodePage,UnicodeLocaleId,UnicodeComparisonStyle,CompatibilityLevel,      
SoftwareVendorId,SoftwareVersionMajor,SoftwareVersionMinor,SoftwareVersionBuild,MachineName,Flags,BindingID,      
RecoveryForkID,Collation,FamilyGUID,HasBulkLoggedData,IsSnapshot,IsReadOnly,IsSingleUser,HasBackupChecksums,      
IsDamaged,BeginsLogChain,HasIncompleteMetaData,IsForceOffline,IsCopyOnly,FirstRecoveryForkID,ForkPointLSN,      
RecoveryModel,DifferentialBaseLSN,DifferentialBaseGUID,BackupTypeDescription,BackupSetGUID,CompressedBackupSize)      
exec(@sql)      
end      
else if @version = 11      
begin      
insert into @headeronly (      
BackupName,BackupDescription,BackupType,ExpirationDate,Compressed,Position,DeviceType,UserName,ServerName,      
DatabaseName,DatabaseVersion,DatabaseCreationDate,BackupSize,FirstLSN,LastLSN,CheckpointLSN,DatabaseBackupLSN,      
BackupStartDate,BackupFinishDate,SortOrder,CodePage,UnicodeLocaleId,UnicodeComparisonStyle,CompatibilityLevel,      
SoftwareVendorId,SoftwareVersionMajor,SoftwareVersionMinor,SoftwareVersionBuild,MachineName,Flags,BindingID,      
RecoveryForkID,Collation,FamilyGUID,HasBulkLoggedData,IsSnapshot,IsReadOnly,IsSingleUser,HasBackupChecksums,      
IsDamaged,BeginsLogChain,HasIncompleteMetaData,IsForceOffline,IsCopyOnly,FirstRecoveryForkID,ForkPointLSN,      
RecoveryModel,DifferentialBaseLSN,DifferentialBaseGUID,BackupTypeDescription,BackupSetGUID,CompressedBackupSize,containment)      
exec(@sql)      
end      
else if @version > 11      
begin      
insert into @headeronly       
exec(@sql)      
end      
      
--select * from @headeronly      
--select * from @filelistonly      
--print(@sql)      
      
select @lastfile = max(Position) from @headeronly      
      
if @restore_loc_sameLoc = 1      
begin      
 set @xp_cmdshell = 'xp_cmdshell ''dir cd "'+@restore_loc+'"'+''''      
 insert into @restor_loc_table      
 exec (@xp_cmdshell)      
end      
else      
begin      
 set @xp_cmdshell = 'xp_cmdshell ''dir cd "'+@restore_loc_data+'"'+''''      
 insert into @restor_loc_table_data      
 exec (@xp_cmdshell)      
 set @xp_cmdshell = 'xp_cmdshell ''dir cd "'+@restore_loc_log+'"'+''''      
 insert into @restor_loc_table_log      
 exec (@xp_cmdshell)      
end       
      
if (@restore_loc_sameLoc = 1)      
begin      
  select @files_exist = count(*)      
  from (      
  select substring(output_text, charindex(' ',output_text)+1,len(output_text)) restore_loc_files      
  from (      
  select ltrim(rtrim(substring(output_text, charindex('M   ',output_text)+1,len(output_text)))) output_text      
  from @restor_loc_table      
  where output_text like '%M   %'      
  and output_text not like '%<DIR>%'      
  and (output_text like '%.mdf%'      
  or output_text like '%.ndf%'      
  or output_text like '%.ldf%'))a)b      
  inner join (select reverse(substring(reverse(PhysicalName),1,charindex('\',reverse(physicalname))-1)) filelist from @filelistonly) fl      
  on b.restore_loc_files = fl.filelist      
end      
else      
begin      
  select @files_exist_data = count(*)      
  from (      
  select substring(output_text, charindex(' ',output_text)+1,len(output_text)) restore_loc_files      
  from (      
  select ltrim(rtrim(substring(output_text, charindex('M   ',output_text)+1,len(output_text)))) output_text      
  from @restor_loc_table_data      
  where output_text like '%M   %'      
  and output_text not like '%<DIR>%'      
  and (output_text like '%.mdf%'      
  or output_text like '%.ndf%'      
  or output_text like '%.ldf%'))a)b      
  inner join (select reverse(substring(reverse(PhysicalName),1,charindex('\',reverse(physicalname))-1)) filelist from @filelistonly) fl      
  on b.restore_loc_files = fl.filelist      
      
  select @files_exist_log = count(*)      
  from (      
  select substring(output_text, charindex(' ',output_text)+1,len(output_text)) restore_loc_files      
  from (      
  select ltrim(rtrim(substring(output_text, charindex('M   ',output_text)+1,len(output_text)))) output_text      
  from @restor_loc_table_log      
  where output_text like '%M   %'      
  and output_text not like '%<DIR>%'      
  and (output_text like '%.mdf%'      
  or output_text like '%.ndf%'      
  or output_text like '%.ldf%'))a)b      
  inner join (select reverse(substring(reverse(PhysicalName),1,charindex('\',reverse(physicalname))-1)) filelist from @filelistonly) fl      
  on b.restore_loc_files = fl.filelist      
end      
            
declare backupfiles_cursor cursor fast_forward   
for      
select Position, DatabaseName, BackupType      
from @headeronly      
where Position between       
case when @filenumber = 'all' then 0 else @filenumber end      
and      
case when @filenumber = 'all' then @lastfile else @filenumber end      
order by BackupType  
    
declare dbfiles_cursor cursor fast_forward for      
select       
LogicalName, originalPath,       
case when PhysicalName like '%.%' then       
  substring(PhysicalName, 1, charindex('.',PhysicalName)-1) else PhysicalName end PhysicalName,      
case when PhysicalName like '%.%' then       
  reverse(substring(reverse(PhysicalName), 1, charindex('.',reverse(PhysicalName)))) else 'no_ext' end ext,      
  type      
from (      
select LogicalName, type,      
reverse(substring(reverse(PhysicalName), charindex('\',reverse(PhysicalName)),len(PhysicalName))) OriginalPath,       
reverse(substring(reverse(PhysicalName), 1, charindex('\',reverse(PhysicalName))-1)) PhysicalName      
from @filelistonly)a      
      
set @unique_id = ltrim(rtrim(cast(left(replace(replace(replace(replace(replace(replace(replace(newid(),'A',''),'B',''),'C',''),'D',''),'E',''),'F',''),'-',''),5) as char)))      
      
open dbfiles_cursor      
fetch next from dbfiles_cursor into @logicalname, @originalpath, @physicalname, @ext, @file_type      
while @@fetch_status = 0      
begin      
      
if @restore_loc_sameLoc = 1      
begin      
      
if @restore_loc = @originalpath      
begin      
set @file_move = isnull(@file_move+',','')+'      
MOVE N'+''''+@logicalname+''''+' TO N'+''''+@originalpath+@physicalname+'__'+@unique_id+case @ext when 'no_ext' then '' else @ext end+''''      
end      
else if @files_exist > 0      
begin      
set @file_move = isnull(@file_move+',','')+'      
MOVE N'+''''+@logicalname+''''+' TO N'+''''+@restore_loc+@physicalname+'__'+@unique_id+case @ext when 'no_ext' then '' else @ext end+''''      
end      
else      
begin      
set @file_move = isnull(@file_move+',','')+'      
MOVE N'+''''+@logicalname+''''+' TO N'+''''+@restore_loc+@physicalname+case @ext when 'no_ext' then '' else @ext end+''''      
end      
end      
---------------------------------------------------------      
else      
begin      
      
if @file_type = 'D'      
begin      
if @restore_loc_data = @originalpath      
begin      
set @file_move_data = isnull(@file_move_data+',','')+'      
MOVE N'+''''+@logicalname+''''+' TO N'+''''+@originalpath+@physicalname+'__'+@unique_id+case @ext when 'no_ext' then '' else @ext end+''''      
end      
else if @files_exist_data > 0      
begin      
set @file_move_data = isnull(@file_move_data+',','')+'      
MOVE N'+''''+@logicalname+''''+' TO N'+''''+@restore_loc_data+@physicalname+'__'+@unique_id+case @ext when 'no_ext' then '' else @ext end+''''      
end      
else      
begin      
set @file_move_data = isnull(@file_move_data+',','')+'      
MOVE N'+''''+@logicalname+''''+' TO N'+''''+@restore_loc_data+@physicalname+case @ext when 'no_ext' then '' else @ext end+''''      
end      
end      
else if @file_type = 'L'      
begin      
if @restore_loc_log = @originalpath      
begin      
set @file_move_log = isnull(@file_move_log+',','')+'      
MOVE N'+''''+@logicalname+''''+' TO N'+''''+@originalpath+@physicalname+'__'+@unique_id+case @ext when 'no_ext' then '' else @ext end+''''      
end      
else if @files_exist_log > 0      
begin      
set @file_move_log = isnull(@file_move_log+',','')+'      
MOVE N'+''''+@logicalname+''''+' TO N'+''''+@restore_loc_log+@physicalname+'__'+@unique_id+case @ext when 'no_ext' then '' else @ext end+''''      
end      
else      
begin      
set @file_move_log = isnull(@file_move_log+',','')+'      
MOVE N'+''''+@logicalname+''''+' TO N'+''''+@restore_loc_log+@physicalname+case @ext when 'no_ext' then '' else @ext end+''''      
end      
end      
end      
      
fetch next from dbfiles_cursor into @logicalname, @originalpath, @physicalname, @ext, @file_type      
end      
close dbfiles_cursor       
deallocate dbfiles_cursor       
      
open backupfiles_cursor       
fetch next from backupfiles_cursor into @Position, @DatabaseName, @BackupType      
while @@fetch_status = 0      
begin      
      
if @password = 'default' and @restore_loc_sameLoc = 1      
begin      
set @sql = '      
RESTORE '+      
case @BackupType when 1 then 'DATABASE' when 2 then 'LOG' end+' '+      
case when @new_db_name = 'default' then '['+@DatabaseName+']' else '['+@new_db_name+']' end      
+'      
FROM DISK = N'+''''+@backupfile+''''+'      
WITH FILE = '+cast(@Position as varchar)+','+      
case when @BackupType ! = 2 then @file_move+',' else '' end+'      
'+case       
when @filenumber  = 'all' and @lastfile = @position then       
case when @with_recovery = 1 then 'RECOVERY' else 'NORECOVERY' end      
when @filenumber != 'all' then       
case when @with_recovery = 1 then 'RECOVERY' else 'NORECOVERY' end      
else 'NORECOVERY' end+', NOUNLOAD, STATS = '+cast(@percent as varchar)      
end      
if @password = 'default' and @restore_loc_sameLoc = 0      
begin      
    
set @sql = '      
RESTORE '+      
case @BackupType when 1 then 'DATABASE' when 2 then 'LOG' end+' '+      
case when @new_db_name = 'default' then '['+@DatabaseName+']' else '['+@new_db_name+']' end      
+'      
FROM DISK = N'+''''+@backupfile+''''+'      
WITH FILE = '+cast(@Position as varchar)+','+      
case when @BackupType ! = 2 then @file_move_data+','+@file_move_log+',' else '' end+'      
'+case       
when @filenumber  = 'all' and @lastfile = @position then       
case when @with_recovery = 1 then 'RECOVERY' else 'NORECOVERY' end      
when @filenumber != 'all' then       
case when @with_recovery = 1 then 'RECOVERY' else 'NORECOVERY' end      
else 'NORECOVERY' end+', NOUNLOAD, STATS = '+cast(@percent as varchar)      
end      
else if @password != 'default' and @restore_loc_sameLoc = 1      
begin      
set @sql = '      
RESTORE '+      
case @BackupType when 1 then 'DATABASE' when 2 then 'LOG' end+' '+      
case when @new_db_name = 'default' then '['+@DatabaseName+']' else '['+@new_db_name+']' end      
+'      
FROM DISK = N'+''''+@backupfile+''''+'      
WITH FILE = '+cast(@Position as varchar)+','+      
case when @BackupType ! = 2 then @file_move+',' else '' end+'      
'+case       
when @filenumber  = 'all' and @lastfile = @position then       
case when @with_recovery = 1 then 'RECOVERY' else 'NORECOVERY' end      
when @filenumber != 'all' then       
case when @with_recovery = 1 then 'RECOVERY' else 'NORECOVERY' end      
else 'NORECOVERY' end+', NOUNLOAD, MEDIAPASSWORD= '+''''+@password+''''+', STATS = '+cast(@percent as varchar)      
end      
      
--print(@sql)      
exec(@sql)      
      
fetch next from backupfiles_cursor into @Position, @DatabaseName, @BackupType      
end      
close backupfiles_cursor       
deallocate backupfiles_cursor       
set nocount off      
end   
GO


CREATE Procedure [dbo].[sp_add_databases_AOAG]    
as    
declare     
@database_name varchar(500),     
@server_name varchar(500),     
@instance_type varchar(500),    
@backup_file varchar(1500),    
@server varchar(500),    
@server_no varchar(5),    
@restore_backup_file varchar(1500),    
@agroup varchar(200),  
@recovery_model int  
    
declare add_db cursor fast_forward    
for    
select [database_name], [server_name], [instance_type], [availability_group], recovery_model  
from [dbo].[Database_create] dbc inner join sys.databases db  
on dbc.[database_name] = db.name  
where flag = 0    
  
begin    
    
open add_db    
fetch next from add_db into @database_name, @server_name, @instance_type, @agroup, @recovery_model  
while @@FETCH_STATUS = 0    
begin    
  
if @recovery_model != 1  
begin  
exec [dbo].[sp_change_db_recovery] @database_name   
end  
   
exec [dbo].[sp_backup_database]     
@backup_file_name = @backup_file output,    
@db_name = @database_name,     
@path = 'F:\sync_backups'    
    
set @server = substring(@server_name, 1, charindex('\', @server_name)-1)     
set @server_no = right(@server,1)    
set @restore_backup_file = '\\10.10.132.10'+@server_no+substring(@backup_file,3,len(@backup_file))    
    
if @server_no = 1    
begin    
exec [AZ-WE-SQL002\AZ_SP_DB].[master].[dbo].[sp_restore_database_AOAG]    
@backupfile = @restore_backup_file,    
@filenumber = 'all',    
@restore_loc_sameLoc = 0,    
@restore_loc_Data = 'F:\DATAFiles_AZ_SP_DB\',    
@restore_loc_Log = 'G:\LOGFiles_AZ_SP_DB\',    
@with_recovery = 0,    
@percent = 1    
end    
else    
begin    
exec [AZ-WE-SQL001\AZ_SP_DB].[master].[dbo].[sp_restore_database_AOAG]    
@backupfile = @restore_backup_file,    
@filenumber = 'all',    
@restore_loc_sameLoc = 0,    
@restore_loc_Data = 'F:\DATAFiles_AZ_SP_DB\',    
@restore_loc_Log = 'G:\LOGFiles_AZ_SP_DB\',    
@with_recovery = 0,    
@percent = 1    
end    

exec sp_add_database_AOAG    
@database_name,    
@server_name,    
@agroup    
    
update Database_create    
set flag = 1    
where database_name = @database_name    
and flag = 0    
    
fetch next from add_db into @database_name, @server_name, @instance_type, @agroup, @recovery_model  
end    
close add_db    
deallocate add_db    
    
end  
GO

