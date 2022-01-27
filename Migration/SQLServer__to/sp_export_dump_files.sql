CREATE Procedure sp_export_dump_files(
@db_name varchar(300), 
@dump_files_location varchar(1000),
@table_name varchar(350),
@new_name varchar(350),
@migrated_to varchar(100),
@where_records_condition varchar(3000),
@columns varchar(3000),
@bulk bigint)
as
begin
declare 
@from_unique_column varchar(300), @to_unique_column varchar(300), 
@from_id bigint, @to_id bigint, 
@bcp_sql varchar(4000) 
declare exp_cur cursor fast_forward
for
select 
from_id, to_id, from_unique_column, to_unique_column 
from msdb.dbo.FBNK_FUNDS_TRANSFER#HIS_summary2
where id between 1001 and 8000
order by id 

set nocount on
open exp_cur
fetch next from exp_cur into @from_id, @to_id, @from_unique_column, @to_unique_column
while @@FETCH_STATUS = 0
begin

set @bcp_sql = 'bcp "exec [dbo].[sp_dump_table] @table = '+''''+@table_name+''''+', @new_name = '+''''+@new_name+''''+', @columns = '+''''+@columns+''''+', @where_records_condition = ''where [recid] between '+''''+''''+@from_unique_column+''''+''''+' and '+''''+''''+@to_unique_column+''''+''''+' order by [recid]'',@with_computed = 0, @header = 0, @bulk = '+cast(@bulk as varchar(50))+'" queryout "'+@dump_files_location+'\'+@table_name+'_from_'+cast(@from_id as varchar(50))+'_to_'+cast(@to_id as varchar(50))+'.sql"  -d '+@db_name+' -T -n -c'
print @bcp_sql
exec xp_cmdshell @bcp_sql

fetch next from exp_cur into @from_id, @to_id, @from_unique_column, @to_unique_column
end
close exp_cur
deallocate exp_cur
set nocount off

end
