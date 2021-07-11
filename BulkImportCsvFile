CREATE PROCEDURE [dbo].[BulkImportCsvFile]
(@FullPath_with_File nvarchar(max), @start_with int = 1)
as
begin
--declare @FullPath_with_File nvarchar(max) = 'C:\Azure_Rac_ConsumptionUsageDetails_2019\AzureRmConsumptionUsageDetail_2019_01_01_to_2019_01_03.csv', @start_with int = 1

declare @header table (id int identity(1,1), output_text varchar(max))
declare @table_column table (id int, column_name nvarchar(255))
declare 
@col nvarchar(255),
@columns_names nvarchar(max), 
@drop_temp_table nvarchar(500),
@columns_max_length  nvarchar(max), 
@columns_numeric     nvarchar(max), 
@columns_select_case nvarchar(max), 
@sql nvarchar(max), 
@ParmDefinition nvarchar(500), 
@columns_out_datatypes nvarchar(max), 
@bulk_insert nvarchar(max),
@first_column_name nvarchar(100),
@column_name nvarchar(1000),
@file_name nvarchar(1000), 
@loop int = 1
set nocount on
SET @ParmDefinition = N'@columns_with_datatypes nvarchar(max) OUTPUT';
set @file_name = reverse(substring(reverse(@FullPath_with_File), 5, charindex('\', reverse(@FullPath_with_File))-5))

CREATE TABLE #TempBulkImportCsvFile_____Headers (output_text nvarchar(max))
CREATE TABLE #TempBulkImportCsvFile_____Records (output_text nvarchar(max))

set @sql = '
BULK INSERT #TempBulkImportCsvFile_____Headers FROM '+''''+@FullPath_with_File+''''+'
WITH (
FIELDTERMINATOR = '','',
ROWTERMINATOR = ''\n'',
FIRSTROW = '+cast(@start_with as varchar)+',
LASTROW = '+cast(@start_with as varchar)+')'
exec(@sql)
set @sql = '
BULK INSERT #TempBulkImportCsvFile_____Records FROM '+''''+@FullPath_with_File+''''+'
WITH (
FIELDTERMINATOR = '','',
ROWTERMINATOR = ''\n'',
FIRSTROW = '+cast(@start_with + 1 as varchar) +')'
exec(@sql)

set @sql = null
while @loop < (select max(id) from dbRecovery.dbo.Separator((select top 1 * from #TempBulkImportCsvFile_____Headers), ','))
begin
select @first_column_name = Value
from dbRecovery.dbo.Separator((select top 1 * from #TempBulkImportCsvFile_____Headers), ',')
where id = 1

select @column_name = Value
from dbRecovery.dbo.Separator((select top 1 * from #TempBulkImportCsvFile_____Headers), ',')
where id = @loop

set @sql = isnull(@sql+',','')+' replace(dbRecovery.dbo.Separator_Single(output_text,'','','+cast(@loop as varchar)+'),''"'','''') '+@column_name
set @loop = @loop + 1

end
set @sql = '
select
'+@sql+'
into '+@file_name+'__temp
from #TempBulkImportCsvFile_____Records'

exec(@sql)
insert into @header
select name from sys.columns where object_id = object_id(@file_name+'__temp')

--set @drop_temp_table = 'drop table '+substring(@file_name, 1, charindex('.',@file_name)-1)+'___temp'
--exec sp_executesql @drop_temp_table 

insert into @table_column
select * 
from @header 
order by id

declare col cursor fast_forward
for
select column_name 
from @table_column
order by id

open col
fetch next from col into @col
while @@FETCH_STATUS = 0
begin 

set @columns_select_case = isnull(@columns_select_case+'+'',''+','')+'case 
when ['+@col+'_var] > 0 and ['+@col+'_var] < 4000 and ['+@col+'_max_length] > 0 then ''['+@col+'] nvarchar(''+cast(['+@col+'_max_length] as nvarchar)+'')'' 
when ['+@col+'_var] > 0 and ['+@col+'_var] > 4000 and ['+@col+'_max_length] > 0 then ''['+@col+'] nvarchar(max)'' 
when ['+@col+'_var] > 0 and ['+@col+'_max_length] = 0 then ''['+@col+'] nvarchar(255)'' 
when ['+@col+'_var] = 0 then ''['+@col+'] float'' end
'
set @columns_max_length = isnull(@columns_max_length+',','')+'isnull(max(len(cast(['+@col+'] as nvarchar(max)))),0) ['+@col+'_max_length]
'
set @columns_numeric = isnull(@columns_numeric+',','')+'isnull(sum(case isnumeric(cast(['+@col+'] as nvarchar(max))) when 0 then 1 end),0) ['+@col+'_var]
'
fetch next from col into @col
end
close col
deallocate col

--select @columns_select_case, @columns_max_length, @columns_numeric

set @sql = 'SELECT @columns_with_datatypes = 
'+@columns_select_case+'FROM (
select '+@columns_numeric+'FROM '+@file_name+'__temp num)a 
cross apply (select '+@columns_max_length+'FROM '+@file_name+'__temp) ac'

exec sp_executesql @sql, @ParmDefinition, @columns_with_datatypes = @columns_out_datatypes output
set @sql = 'CREATE TABLE ['+@file_name+'] ('+@columns_out_datatypes+')'
exec (@sql)

set @sql = '
INSERT INTO ['+@file_name+']
SELECT * FROM ['+@file_name+'__temp]
DROP TABLE ['+@file_name+'__temp]'
exec (@sql)

DROP TABLE #TempBulkImportCsvFile_____Headers
DROP TABLE #TempBulkImportCsvFile_____Records

end
