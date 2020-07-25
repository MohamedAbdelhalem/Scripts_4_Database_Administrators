USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_restore_database]    Script Date: 7/25/2020 11:20:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[sp_restore_database]
(
@backupfile			varchar(max), 
@filenumber			varchar(5) = 'all', 
@restore_loc			varchar(500)  = 'default',
@with_recovery			bit = 1,  
@new_db_name			varchar(500) = 'default',
@percent			int = 5,
@password			varchar(100) = 'default')
as
begin 
declare @restor_loc_table table (output_text varchar(max))
declare @xp_cmdshell varchar(500), @files_exist int
declare 
@sql					varchar(max), 
@file_move				varchar(max), 
@file					int, 
@version				int,
@logicalname			varchar(500), 
@originalpath			varchar(max), 
@physicalname			varchar(500),
@ext					varchar(10),
@unique_id				varchar(10),
@Position				int, 
@DatabaseName			varchar(500), 
@BackupType				int,
@BackupTypeDescription  varchar(100),
@lastfile				int

declare @headeronly table (
BackupName				nvarchar(512),
BackupDescription		nvarchar(255),
BackupType				smallint,
ExpirationDate 			datetime,
Compressed				int,
Position 				smallint,
DeviceType 				tinyint,
UserName 				nvarchar(128),
ServerName 				nvarchar(128),
DatabaseName 			nvarchar(512),
DatabaseVersion 		int,
DatabaseCreationDate 	datetime,
BackupSize 				numeric(20,0),
FirstLSN 				numeric(25,0),
LastLSN 				numeric(25,0),
CheckpointLSN 			numeric(25,0),
DatabaseBackupLSN 		numeric(25,0),
BackupStartDate 		datetime,
BackupFinishDate 		datetime,
SortOrder 				smallint,
CodePage 				smallint,
UnicodeLocaleId 		int,
UnicodeComparisonStyle 	int,
CompatibilityLevel 		tinyint,
SoftwareVendorId 		int,
SoftwareVersionMajor 	int,
SoftwareVersionMinor 	int,
SoftwareVersionBuild 	int,
MachineName 			nvarchar(128),
Flags 					int,
BindingID 				uniqueidentifier,
RecoveryForkID			uniqueidentifier,
Collation 				nvarchar(128),
FamilyGUID 				uniqueidentifier,
HasBulkLoggedData 		bit,
IsSnapshot				bit,
IsReadOnly				bit,
IsSingleUser 			bit,
HasBackupChecksums		bit,
IsDamaged 				bit,
BeginsLogChain 			bit,
HasIncompleteMetaData 	bit,
IsForceOffline 			bit,
IsCopyOnly 				bit,
FirstRecoveryForkID 	uniqueidentifier,
ForkPointLSN 			numeric(25,0),
RecoveryModel 			nvarchar(60),
DifferentialBaseLSN 	numeric(25,0),
DifferentialBaseGUID 	uniqueidentifier,
BackupTypeDescription 	nvarchar(60),
BackupSetGUID 			uniqueidentifier,
CompressedBackupSize 	bigint,
containment 			tinyint,
KeyAlgorithm 			nvarchar(32)  default NULL,
EncryptorThumbprint 	varbinary(20)  default NULL,
EncryptorType 			nvarchar(32))

declare @filelistonly table (
LogicalName				varchar(1000),
PhysicalName			varchar(max),
Type					varchar(5),
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

--print(@sql)

select @lastfile = max(Position) from @headeronly

set @xp_cmdshell = 'xp_cmdshell ''dir cd "'+@restore_loc+'"'+''''
insert into @restor_loc_table
exec (@xp_cmdshell)

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

declare backupfiles_cursor cursor fast_forward for
select Position, DatabaseName, BackupType, BackupTypeDescription
from @headeronly 
where Position between 
case when @filenumber = 'all' then 0 else @filenumber end
and
case when @filenumber = 'all' then @lastfile else @filenumber end

declare dbfiles_cursor cursor fast_forward for
select 
LogicalName, originalPath, 
substring(PhysicalName, 1, charindex('.',PhysicalName)-1) PhysicalName,
substring(PhysicalName, charindex('.',PhysicalName),len(PhysicalName)) ext
from (
select LogicalName,
reverse(substring(reverse(PhysicalName), charindex('\',reverse(PhysicalName)),len(PhysicalName))) OriginalPath, 
reverse(substring(reverse(PhysicalName), 1, charindex('\',reverse(PhysicalName))-1)) PhysicalName
from @filelistonly)a

set @unique_id = ltrim(rtrim(cast(left(replace(replace(replace(replace(replace(replace(replace(newid(),'A',''),'B',''),'C',''),'D',''),'E',''),'F',''),'-',''),5) as char)))

open dbfiles_cursor
fetch next from dbfiles_cursor into @logicalname, @originalpath, @physicalname, @ext
while @@fetch_status = 0
begin

if @restore_loc = 'default'
begin
set @file_move = isnull(@file_move+',','')+'
MOVE N'+''''+@logicalname+''''+' TO N'+''''+@originalpath+@physicalname+'__'+@unique_id+@ext+''''
end
else
begin
	if @files_exist > 0
	begin
		set @file_move = isnull(@file_move+',','')+'
		MOVE N'+''''+@logicalname+''''+' TO N'+''''+@restore_loc+@physicalname+'__'+@unique_id+@ext+''''
	end
	else
	begin
		set @file_move = isnull(@file_move+',','')+'
		MOVE N'+''''+@logicalname+''''+' TO N'+''''+@restore_loc+@physicalname+@ext+''''
	end
end

fetch next from dbfiles_cursor into @logicalname, @originalpath, @physicalname, @ext
end
close dbfiles_cursor 
deallocate dbfiles_cursor 

open backupfiles_cursor 
fetch next from backupfiles_cursor into @Position, @DatabaseName, @BackupType, @BackupTypeDescription
while @@fetch_status = 0
begin

if @password = 'default'
begin
set @sql = '
RESTORE '+
case @BackupType 
when 1 then @BackupTypeDescription 
when 2 then substring(@BackupTypeDescription, charindex(' ',@BackupTypeDescription)+1, len(@BackupTypeDescription))
when 5 then substring(@BackupTypeDescription, 1, charindex(' ',@BackupTypeDescription)-1)
end+' '+
case when @new_db_name = 'default' then '['+@DatabaseName+']' else '['+@new_db_name+']' end
+'
FROM DISK = N'+''''+@backupfile+''''+'
WITH FILE = '+cast(@Position as varchar)+','+
case when @BackupType = 1 then @file_move+',' else '' end+'
'+case 
when @filenumber  = 'all' and @lastfile = @position then 
case when @with_recovery = 1 then 'RECOVERY' else 'NORECOVERY' end
when @filenumber != 'all' then 
case when @with_recovery = 1 then 'RECOVERY' else 'NORECOVERY' end
else 'NORECOVERY' end+', NOUNLOAD, STATS = '+cast(@percent as varchar)
end
else
begin
set @sql = '
RESTORE '+
case @BackupType 
when 1 then @BackupTypeDescription 
when 2 then substring(@BackupTypeDescription, charindex(' ',@BackupTypeDescription)+1, len(@BackupTypeDescription))
when 5 then substring(@BackupTypeDescription, 1, charindex(' ',@BackupTypeDescription)-1)
end+' '+
case when @new_db_name = 'default' then '['+@DatabaseName+']' else '['+@new_db_name+']' end
+'
FROM DISK = N'+''''+@backupfile+''''+'
WITH FILE = '+cast(@Position as varchar)+','+
case when @BackupType = 1 then @file_move+',' else '' end+'
'+case 
when @filenumber  = 'all' and @lastfile = @position then 
case when @with_recovery = 1 then 'RECOVERY' else 'NORECOVERY' end
when @filenumber != 'all' then 
case when @with_recovery = 1 then 'RECOVERY' else 'NORECOVERY' end
else 'NORECOVERY' end+', NOUNLOAD, MEDIAPASSWORD= '+''''+@password+''''+', STATS = '+cast(@percent as varchar)
end

set @sql = replace(@sql, 'MSSQL14.DBAMI1','MSSQL14.DBAMI3')
print(@sql)
exec(@sql)

fetch next from backupfiles_cursor into @Position, @DatabaseName, @BackupType, @BackupTypeDescription
end
close backupfiles_cursor 
deallocate backupfiles_cursor 
set nocount off
end
