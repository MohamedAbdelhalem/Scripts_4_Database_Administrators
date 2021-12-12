CREATE procedure [dbo].[Export_AzureConsumptionUsageDetails_failed_files]
(@path varchar(1000), @file_name varchar(1000))
as
begin
declare @table1 table (output_text varchar(max))
declare @table2 table (size int, [file_name] varchar(500))
declare @table3 table (id int identity(1,1), date_from datetime, date_to datetime)
declare @xp_cmdshell varchar(500)
set @xp_cmdshell = 'xp_cmdshell ''dir cd "'+@path+'"'''
insert into @table1 exec (@xp_cmdshell)

insert into @table2
select size, [file_name] 
from (
select cast(replace(substring(output_text, 1, charindex(' ', output_text)-1),',','') as int) size, substring(output_text, charindex(' ', output_text)+1, len(output_text)) file_name
from (
select rtrim(ltrim(substring(output_text, charindex('M  ',output_text)+1,len(output_text)))) output_text
from @table1
where output_text like '%M  %'
and output_text not like '%<DIR>%')a)b

declare @date_from varchar(10), @days int, @loop int
declare i cursor fast_forward
for
select from_date, datediff(day, from_date, to_date) + 1
from (
select 
replace(substring(dates, 1, charindex('_to_', dates)-1),'_','-') from_date,
replace(substring(dates, charindex('_to_', dates)+4, len(dates)),'_','-') to_date
from (
select left(substring(file_name, charindex('_',file_name)+1, len(file_name)),len(substring(file_name, charindex('_',file_name)+1, len(file_name)))-4) dates
from @table2 where size = 0)a)b

open i
fetch next from i into @date_from, @days
while @@FETCH_STATUS = 0
begin

set @loop = 0
while @loop < @days
begin 
insert into @table3 values (dateadd(day, @loop, @date_from),dateadd(day, @loop, @date_from))
set @loop = @loop + 1
end

fetch next from i into @date_from, @days
end
close i 
deallocate i

select 
'Get-AzureRmConsumptionUsageDetail -StartDate '+convert(varchar(10),date_from,120)+' -EndDate '+convert(varchar(10),date_to,120)+' | Select-Object AccountName,BillingPeriodName,ConsumedService,Currency,DepartmentName,Id,InstanceId,InstanceLocation,InstanceName,IsEstimated,PretaxCost,Product,SubscriptionGuid,SubscriptionName,UsageEnd,UsageQuantity,UsageStart | Export-Csv -Path "'+@path+'\'+@file_name+'_'+replace(convert(varchar(10),date_from,120),'-','_')+'_to_'+replace(convert(varchar(10),date_to,120),'-','_')+'.csv"'
from @table3

end


