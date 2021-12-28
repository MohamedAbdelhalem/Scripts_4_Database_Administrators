CREATE Procedure [dbo].[sp_Table_Rows]
(@rows int output, @table varchar(350)='Sales.Customer')
as
begin
select @rows = max(rows)
from sys.partitions
where object_id = object_id(@table)
group by object_id
end
