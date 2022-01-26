CREATE OR ALTER Procedure [dbo].[sp_big_table_summary]
(
@table_name varchar(500) = 'dbo.[FBNK_FUNDS_TRANSFER#HIS]', 
@unique_column varchar(300) = '[recid]', 
@bulk int = 10000,
@top varchar(50) = 'all')
as
begin
set nocount on
declare @dynamic_sql varchar(max)
declare @table table (id int primary key, recid varchar(255))

set @dynamic_sql = '
select '+case when @top = 'all' then '' else 'TOP ('+@top+')' end +' row_number() over(order by '+@unique_column+') id, '+@unique_column+'
from '+@table_name+' WITH (NOLOCK)
order by '+@unique_column+'
OPTION (MAXDOP 4)'

insert into @table 
exec (@dynamic_sql)

insert into msdb.dbo.[FBNK_FUNDS_TRANSFER#HIS_summary2] 
select row_number() over(order by unique_id desc) id, unique_id, min(id), max(id), min(recid), max(recid)
from (
select count(*) over() - patch_id - count(*) over(order by id) unique_id, * 
from (
select id % @bulk patch_id, id, recid
from @table)a
where patch_id in (0,1)
union all
select -1, 0, id, recid
from (
select count(*) over() - patch_id - count(*) over(order by id) unique_id, * 
from (
select id % @bulk patch_id, id, recid
from @table)a)b
where id in (select max(id) 
				from (
					select count(*) over() - patch_id - count(*) over(order by id) unique_id, patch_id, id, recid 
						from (
							select id % @bulk patch_id, id, recid 
								from @table)a)b))c
group by unique_id
order by unique_id desc

set nocount off
end
