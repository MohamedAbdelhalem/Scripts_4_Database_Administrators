use master
go
CREATE PROCEDURE [dbo].[transfer_difference_data](
@linkedserver nvarchar(50) = '10.38.5.65',
@db_name nvarchar(500) = 'T24PROD_UAT',
@collate nvarchar(100) = 'Arabic_100_CI_AS')

as
begin
declare 
@table_name nvarchar(500),
@sql nvarchar(max),
@columns_bin nvarchar(max),
@columns_xml nvarchar(max),
@columns_sel nvarchar(max),
@primary_key nvarchar(500)

create table #diff_tables (table_name varchar(500), has_data_diff tinyint)
select table_name, has_data_diff
from (
select az.name, az.table_name, case when (az.rows = uat.rows) or (az.rows > uat.rows) then 1 else 0 end has_data_diff
from  (
select t.name, '['+schema_name(schema_id)+'].['+t.name+']' table_name, max(p_az.rows) rows 
from [T24PROD_UAT].sys.partitions p_az inner join [T24PROD_UAT].sys.tables t
on p_az.object_id = t.object_id
group by schema_id, t.name) az
inner join (select t.name, '['+schema_name(schema_id)+'].['+t.name+']' table_name, max(p_uat.rows)rows 
from [10.38.5.65].[T24PROD_UAT].sys.partitions p_uat inner join [10.38.5.65].[T24PROD_UAT].sys.tables t
on p_uat.object_id = t.object_id
group by schema_id, t.name) uat
on uat.name = az.name collate Arabic_100_CI_AS)a inner join [10.38.5.65].[master].[dbo].[required table_records] rem on a.name = rem.tablename
order by name

declare i cursor fast_forward
for
select table_name
from #diff_tables
where has_data_diff = 0
order by table_name

open i
fetch next from i into @table_name
while @@FETCH_STATUS = 0
begin

select @primary_key = 
isnull( '['+[1]+']','')+isnull(',['+[2]+']','')+isnull(',['+[3]+']','')+isnull(',['+[4]+']','')+
isnull(',['+[5]+']','')+isnull(',['+[6]+']','')+isnull(',['+[7]+']','')+isnull(',['+[8]+']','')
from (
select top 100 percent constraint_name, column_name, ordinal_position
from [information_schema].[key_column_usage] kc 
inner join [sys].[key_constraints] kcon
on kc.constraint_name = kcon.name
where '['+constraint_schema+'].['+table_name+']' = @table_name
and type = 'PK'
order by ordinal_position)a
pivot
(max(column_name) for ordinal_position in ([1],[2],[3],[4],[5],[6],[7],[8]))pvt

select @columns_bin =
isnull(    [1],'')+ isnull(','+[2],'')+ isnull(','+[3],'')+ isnull(','+[4],'')+ isnull(','+[5],'')+ isnull(','+[6],'')+ isnull(','+[7],'')+ isnull(','+[8],'')+
isnull(','+[9],'')+ isnull(','+[10],'')+isnull(','+[11],'')+isnull(','+[12],'')+isnull(','+[13],'')+isnull(','+[14],'')+isnull(','+[5],'')+ isnull(','+[16],'')+
isnull(','+[17],'')+isnull(','+[18],'')+isnull(','+[19],'')+isnull(','+[20],'')+isnull(','+[21],'')+isnull(','+[22],'')+isnull(','+[23],'')+isnull(','+[24],'')+
isnull(','+[25],'')+isnull(','+[26],'')+isnull(','+[27],'')+isnull(','+[28],'')+isnull(','+[29],'')+isnull(','+[30],'')+isnull(','+[31],'')+isnull(','+[32],'')
from (
select row_number() over(partition by table_name order by table_name) id, table_name, case 
when tp.name  = 'XML' and c.is_computed = 0 then 'CONVERT(VARBINARY(MAX),['+c.name+'],2) ['+c.name+']' 
when tp.name != 'XML' and c.is_computed = 0 then '['+c.name+']' 
end column_def
from #diff_tables t inner join sys.columns c
on object_id(t.table_name) = c.object_id
inner join sys.types tp
on c.user_type_id = tp.user_type_id
where table_name = @table_name)a
pivot (
max(column_def) for id in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],
[17],[18],[19],[20],[21],[22],[23],[24],[25],[26],[27],[28],[29],[30],[31],[32]))s

select @columns_xml =
isnull(    [1],'')+ isnull(','+[2],'')+ isnull(','+[3],'')+ isnull(','+[4],'')+ isnull(','+[5],'')+ isnull(','+[6],'')+ isnull(','+[7],'')+ isnull(','+[8],'')+
isnull(','+[9],'')+ isnull(','+[10],'')+isnull(','+[11],'')+isnull(','+[12],'')+isnull(','+[13],'')+isnull(','+[14],'')+isnull(','+[5],'')+ isnull(','+[16],'')+
isnull(','+[17],'')+isnull(','+[18],'')+isnull(','+[19],'')+isnull(','+[20],'')+isnull(','+[21],'')+isnull(','+[22],'')+isnull(','+[23],'')+isnull(','+[24],'')+
isnull(','+[25],'')+isnull(','+[26],'')+isnull(','+[27],'')+isnull(','+[28],'')+isnull(','+[29],'')+isnull(','+[30],'')+isnull(','+[31],'')+isnull(','+[32],'')
from (
select row_number() over(partition by table_name order by table_name) id, table_name, case 
when tp.name  = 'XML' and c.is_computed = 0 then 'CONVERT(XML,['+c.name+'],2) ['+c.name+']' 
when tp.name != 'XML' and c.is_computed = 0 then '['+c.name+']' 
end column_def
from #diff_tables t inner join sys.columns c
on object_id(t.table_name) = c.object_id
inner join sys.types tp
on c.user_type_id = tp.user_type_id
where table_name = @table_name)a
pivot (
max(column_def) for id in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],
[17],[18],[19],[20],[21],[22],[23],[24],[25],[26],[27],[28],[29],[30],[31],[32]))s

select @columns_sel =
isnull(    [1],'')+ isnull(','+[2],'')+ isnull(','+[3],'')+ isnull(','+[4],'')+ isnull(','+[5],'')+ isnull(','+[6],'')+ isnull(','+[7],'')+ isnull(','+[8],'')+
isnull(','+[9],'')+ isnull(','+[10],'')+isnull(','+[11],'')+isnull(','+[12],'')+isnull(','+[13],'')+isnull(','+[14],'')+isnull(','+[5],'')+ isnull(','+[16],'')+
isnull(','+[17],'')+isnull(','+[18],'')+isnull(','+[19],'')+isnull(','+[20],'')+isnull(','+[21],'')+isnull(','+[22],'')+isnull(','+[23],'')+isnull(','+[24],'')+
isnull(','+[25],'')+isnull(','+[26],'')+isnull(','+[27],'')+isnull(','+[28],'')+isnull(','+[29],'')+isnull(','+[30],'')+isnull(','+[31],'')+isnull(','+[32],'')
from (
select row_number() over(partition by table_name order by table_name) id, table_name, case 
when c.is_computed = 0 then '['+c.name+']' 
end column_sel
from #diff_tables t inner join sys.columns c
on object_id(t.table_name) = c.object_id
inner join sys.types tp
on c.user_type_id = tp.user_type_id
where table_name = @table_name)a
pivot (
max(column_sel) for id in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],
[17],[18],[19],[20],[21],[22],[23],[24],[25],[26],[27],[28],[29],[30],[31],[32]))s

set @sql = '
insert into ['+@db_name+'].'+@table_name+'
('+@columns_sel+')
select '+@columns_xml+' 
from (
SELECT *
FROM OPENQUERY(['+@linkedserver+'], ''SELECT '+@columns_bin+' 
FROM ['+@db_name+'].'+@table_name+''')) AS xual 
where xual.'+@primary_key+' in (
SELECT uat.'+@primary_key+'
FROM ['+@db_name+'].'+@table_name+' az right outer join (
SELECT *
FROM OPENQUERY(['+@linkedserver+'], ''SELECT '+@primary_key+'
FROM ['+@db_name+'].'+@table_name+''')
) AS uat 
on az.'+@primary_key+' = uat.'+@primary_key+' collate '+@collate+'
where az.'+@primary_key+' is null)'

print(@table_name)
print(@sql)
exec(@sql)
fetch next from i into @table_name
end
close i
deallocate i 

end
