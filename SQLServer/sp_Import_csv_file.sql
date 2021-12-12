USE [master]
GO
exec [dbo].[Import_csv_file] @FullPath_with_File = 'D:\excel\Twitter.csv'

GO
CREATE PROCEDURE [dbo].[Import_csv_file]
(@FullPath_with_File nvarchar(max))
as
begin

declare @path nvarchar(500), @file_name nvarchar(500)
set @path = reverse(substring(reverse(@FullPath_with_File),charindex('\',reverse(@FullPath_with_File)), len(reverse(@FullPath_with_File))))
set @file_name = reverse(substring(reverse(@FullPath_with_File),1,charindex('\',reverse(@FullPath_with_File))-1))

declare @header table (id int identity(1,1), output_text varchar(max))
declare @table_column table (id int, column_name nvarchar(255))
declare 
@col nvarchar(255),
@columns_names nvarchar(max), 
@drop_temp_table nvarchar(500),
@columns_max_length  nvarchar(max), 
@columns_numeric     nvarchar(max), 
@columns_select_case nvarchar(max), 
@sql nvarchar(max), @ParmDefinition nvarchar(500), 
@columns_out_datatypes nvarchar(max), 
@bulk_insert nvarchar(max)
SET @ParmDefinition = N'@columns_with_datatypes nvarchar(max) OUTPUT';
set nocount on

set @columns_names = 'select top 1 *
into '+substring(@file_name, 1, charindex('.',@file_name)-1)+'___temp
from openrowset
(''MSDASQL''
 ,''Driver={Microsoft Access Text Driver (*.txt, *.csv)}''
 ,''select * from '+@path+@file_name+''')'
exec sp_executesql @columns_names
--print (@columns_names)

insert into @header
select name from sys.columns where object_id = object_id(substring(@file_name, 1, charindex('.',@file_name)-1)+'___temp')

set @drop_temp_table = 'drop table '+substring(@file_name, 1, charindex('.',@file_name)-1)+'___temp'

exec sp_executesql @drop_temp_table 

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
select '+@columns_numeric+'FROM OPENROWSET
(''MSDASQL''
 ,''Driver={Microsoft Access Text Driver (*.txt, *.csv)}''
 ,''SELECT * FROM '+@path+@file_name+''') num)a 
cross apply (select '+@columns_max_length+'FROM OPENROWSET
(''MSDASQL''
 ,''Driver={Microsoft Access Text Driver (*.txt, *.csv)}''
 ,''SELECT * FROM '+@path+@file_name+''')) ac'

exec sp_executesql @sql, @ParmDefinition, @columns_with_datatypes = @columns_out_datatypes output
--select @columns_out_datatypes
set @sql = 'CREATE TABLE ['+substring(@file_name, 1, charindex('.',@file_name)-1)+'] ('+@columns_out_datatypes+')'
exec (@sql)
--print (@sql)

set @bulk_insert = 'insert into [dbo].['+substring(@file_name, 1, charindex('.',@file_name)-1)+']
select *
from openrowset
(''MSDASQL''
 ,''Driver={Microsoft Access Text Driver (*.txt, *.csv)}''
 ,''select * from '+@path+@file_name+''')'

exec(@bulk_insert)
--print(@bulk_insert)
set nocount off

end

