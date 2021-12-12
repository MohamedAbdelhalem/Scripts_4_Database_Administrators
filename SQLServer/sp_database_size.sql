USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_database_size]    Script Date: 5/16/2019 3:31:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER Procedure [dbo].[sp_database_size]@datafile_type=2
(@Db_name varchar(max) = 'Default', @datafile_type int = 0, @order_by int = 3, @is_asc int = 0)
as
begin
declare @table table (row_id int,database_name varchar(150), file_id int, type_desc varchar(50), logical_name varchar(100), physical_name varchar(200), file_size varchar(50), growth varchar(50), max_size varchar(50), used_space varchar(50), free_space varchar(50), full_path varchar(1000), order_column float)
declare @sql varchar(max)
set @sql = '
use [?]
select 
row_id, ''?'' database_name, file_id,type_desc,isnull(logical_name,recovery_model_desc),file_name,file_size,growth,max_size,used_space,free_space,Physical_path,order_by
from(
select row_number() over(order by d.file_id) row_id, 
d.file_id, type_desc, name logical_name, 
reverse(substring(reverse(physical_name),1,charindex(''\'',reverse(physical_name))-1)) file_name, 
master.dbo.numbersize((grp.file_size/1024)*8,''m'') file_size, 
master.dbo.numbersize(growth*8,''k'') growth, 
case max_size when -1 then ''unlimited'' collate SQL_Latin1_General_CP1_CI_AS else master.dbo.numbersize(cast(max_size as float)/128.0,''m'') end max_size,
master.dbo.numbersize(grp.used_space,''m'') used_space,
master.dbo.numbersize(grp.free_space,''m'') free_space,
reverse(substring(reverse(physical_name),charindex(''\'',reverse(physical_name))+1, len(physical_name))) Physical_path, 
cast(grp2.'+case @order_by when 1 then 'file_size' when 2 then 'used_space' when 3 then 'free_space' end+' as float) order_by, db.recovery_model_desc
from sys.database_files d right outer join (
select file_id,
sum(size) file_size, 
sum(cast(FILEPROPERTY(name,''spaceused'') as float)/128.0) used_space,
sum((size/128.0) - cast(FILEPROPERTY(name,''spaceused'') as float)/128.0) free_space
from sys.database_files
where type '+case @datafile_type when 0 then '> -1' when 1 then '= 0' when 2 then '= 1' end +'
Group By file_id with ROLLUP) grp
on d.file_id = grp.file_id
cross apply (
select '+case @order_by when 1 then 'file_size' when 2 then 'used_space' when 3 then 'free_space' end+'
from (
select file_id,
sum(size) file_size, 
sum(cast(FILEPROPERTY(name,''spaceused'') as float)/128.0) used_space,
sum((size/128.0) - cast(FILEPROPERTY(name,''spaceused'') as float)/128.0) free_space
from sys.database_files
where type '+case @datafile_type when 0 then '> -1' when 1 then '= 0' when 2 then '= 1' end +'
Group By file_id with ROLLUP)g
where file_id is null)grp2
cross apply (select recovery_model_desc from sys.databases where database_id = db_id()) db)t
'
print(@SQL)

if @Db_name = 'Default'
begin
insert into @table 
exec sp_msforeachdb @sql
end
else
begin
if (select count(*) from master.dbo.separator(@Db_name+',',',')) > 1
begin
declare @name varchar(150)
declare i cursor fast_forward
for
select ltrim(rtrim(value))
from master.dbo.separator(@Db_name,',')
open i
fetch next from i into @name
while @@FETCH_STATUS = 0
begin
set @sql = '
use ['+@name+']
select 
row_id,database_name,file_id,type_desc,isnull(logical_name,recovery_model_desc),file_name,file_size,growth,max_size,used_space,free_space,Physical_path,order_by
from(
select row_number() over(order by database_name) row_id, 
database_name, d.file_id, type_desc, name logical_name, 
reverse(substring(reverse(physical_name),1,charindex(''\'',reverse(physical_name))-1)) file_name, 
master.dbo.numbersize((grp.file_size/1024)*8,''m'') file_size, 
master.dbo.numbersize(growth*8,''k'') growth, 
case max_size when -1 then ''unlimited'' collate SQL_Latin1_General_CP1_CI_AS else master.dbo.numbersize(cast(max_size as float)/128.0,''m'') end max_size,
master.dbo.numbersize(grp.used_space,''m'') used_space,
master.dbo.numbersize(grp.free_space,''m'') free_space,
reverse(substring(reverse(physical_name),charindex(''\'',reverse(physical_name))+1, len(physical_name))) Physical_path, 
cast(grp2.'+case @order_by when 1 then 'file_size' when 2 then 'used_space' when 3 then 'free_space' end+' as float) order_by, db.recovery_model_desc
from sys.database_files d right outer join (
select '+''''+@name+''''+' Database_Name, file_id,
sum(size) file_size, 
sum(cast(FILEPROPERTY(name,''spaceused'') as float)/128.0) used_space,
sum((size/128.0) - cast(FILEPROPERTY(name,''spaceused'') as float)/128.0) free_space
from sys.database_files
where type '+case @datafile_type when 0 then '> -1' when 1 then '= 0' when 2 then '= 1' end +'
Group By file_id with ROLLUP) grp
on d.file_id = grp.file_id
cross apply (
select '+case @order_by when 1 then 'file_size' when 2 then 'used_space' when 3 then 'free_space' end+'
from (
select '+''''+@name+''''+' Database_Name, file_id,
sum(size) file_size, 
sum(cast(FILEPROPERTY(name,''spaceused'') as float)/128.0) used_space,
sum((size/128.0) - cast(FILEPROPERTY(name,''spaceused'') as float)/128.0) free_space
from sys.database_files
where type '+case @datafile_type when 0 then '> -1' when 1 then '= 0' when 2 then '= 1' end +'
Group By file_id with ROLLUP)g
where file_id is null)grp2
cross apply (select recovery_model_desc from sys.databases where database_id = db_id()) db)t
'
insert into @table 
exec (@sql)
fetch next from i into @name
end
close i
deallocate i
end
else
begin

set @sql = '
use ['+@name+']
select 
row_id,database_name,file_id,type_desc,isnull(logical_name,recovery_model_desc),file_name,file_size,growth,max_size,used_space,free_space,Physical_path,order_by
from(
select row_number() over(order by database_name) row_id, 
database_name, d.file_id, type_desc, name logical_name, 
reverse(substring(reverse(physical_name),1,charindex(''\'',reverse(physical_name))-1)) file_name, 
master.dbo.numbersize((grp.file_size/1024)*8,''m'') file_size, 
master.dbo.numbersize(growth*8,''k'') growth, 
case max_size when -1 then ''unlimited'' collate SQL_Latin1_General_CP1_CI_AS else master.dbo.numbersize(cast(max_size as float)/128.0,''m'') end max_size,
master.dbo.numbersize(grp.used_space,''m'') used_space,
master.dbo.numbersize(grp.free_space,''m'') free_space,
reverse(substring(reverse(physical_name),charindex(''\'',reverse(physical_name))+1, len(physical_name))) Physical_path, 
cast(grp2.'+case @order_by when 1 then 'file_size' when 2 then 'used_space' when 3 then 'free_space' end+' as float) order_by, db.recovery_model_desc
from sys.database_files d right outer join (
select '+''''+@name+''''+' Database_Name, file_id,
sum(size) file_size, 
sum(cast(FILEPROPERTY(name,''spaceused'') as float)/128.0) used_space,
sum((size/128.0) - cast(FILEPROPERTY(name,''spaceused'') as float)/128.0) free_space
from sys.database_files
where type '+case @datafile_type when 0 then '> -1' when 1 then '= 0' when 2 then '= 1' end +'
Group By file_id with ROLLUP) grp
on d.file_id = grp.file_id
cross apply (
select '+case @order_by when 1 then 'file_size' when 2 then 'used_space' when 3 then 'free_space' end+'
from (
select '+''''+@name+''''+' Database_Name, file_id,
sum(size) file_size, 
sum(cast(FILEPROPERTY(name,''spaceused'') as float)/128.0) used_space,
sum((size/128.0) - cast(FILEPROPERTY(name,''spaceused'') as float)/128.0) free_space
from sys.database_files
where type '+case @datafile_type when 0 then '> -1' when 1 then '= 0' when 2 then '= 1' end +'
Group By file_id with ROLLUP)g
where file_id is null)grp2
cross apply (select recovery_model_desc from sys.databases where database_id = db_id()) db)t
'
insert into @table 
exec (@sql)

end
end
if @is_asc = 0
begin
select 
isnull(database_name,'') database_name, isnull(file_id,100) file_id, isnull(type_desc,'') type_desc, 
isnull(logical_name,'') logical_name, isnull(physical_name,'') physical_name, isnull(file_size,'') file_size, 
isnull(growth,'') growth, isnull(max_size,'') max_size, isnull(used_space,'') used_space, isnull(free_space,'') free_space, isnull(full_path,'') full_path--, isnull(Shrink_Script,'') Shrink_Script
from (
select 
database_name, file_id, type_desc, logical_name, physical_name, file_size, growth, max_size , used_space, free_space, full_path,
case type_desc when 'LOG' then 'USE ['+database_name+']
go 
DBCC Shrinkfile (['+ logical_name +'], '+case substring(used_space, charindex(' ',used_space)+1, len(used_space)) 
when 'KB' then cast(round(cast(substring(used_space, 1, charindex(' ',used_space)-1) as float) + 1024,0)/1024 as varchar)
when 'MB' then cast(round(cast(substring(used_space, 1, charindex(' ',used_space)-1) as float) + 100,0)  as varchar)
when 'GB' then cast(round(cast(substring(used_space, 1, charindex(' ',used_space)-1) as float) + 0.5,0)*1024  as varchar)
end +')
go
'end Shrink_Script, order_column, row_id
from @table)a
order by order_column desc, file_id
end
else
begin
select 
isnull(database_name,'') database_name, isnull(file_id,100) file_id, isnull(type_desc,'') type_desc, 
isnull(logical_name,'') logical_name, isnull(physical_name,'') physical_name, isnull(file_size,'') file_size, 
isnull(growth,'') growth, isnull(max_size,'') max_size, isnull(used_space,'') used_space, isnull(free_space,'') free_space, isnull(full_path,'') full_path, 
isnull(Shrink_Script,'') Shrink_Script
from (
select 
database_name, file_id, type_desc, logical_name, physical_name, file_size, growth, max_size , used_space, free_space, full_path,
case type_desc when 'LOG' then 'USE ['+database_name+']
go 
DBCC Shrinkfile (['+ logical_name +'], '+case substring(used_space, charindex(' ',used_space)+1, len(used_space)) 
when 'KB' then cast(round(cast(substring(used_space, 1, charindex(' ',used_space)-1) as float) + 1024,0)/1024 as varchar)
when 'MB' then cast(round(cast(substring(used_space, 1, charindex(' ',used_space)-1) as float) + 100,0)  as varchar)
when 'GB' then cast(round(cast(substring(used_space, 1, charindex(' ',used_space)-1) as float) + 0.5,0)*1024  as varchar)
end +')
go
'end Shrink_Script, order_column, row_id
from @table)a
order by order_column, file_id
end
end
