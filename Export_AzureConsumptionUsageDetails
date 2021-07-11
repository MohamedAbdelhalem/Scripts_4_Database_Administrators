CREATE procedure [dbo].[Export_AzureConsumptionUsageDetails]
(@path varchar(1000), @file_name varchar(1000), @date_from varchar(10), @date_to varchar(10))
as
begin
declare @from varchar(10) = @date_from, @to varchar(10) = @date_to
declare @table table (id int identity(1,1), date_from datetime, date_to datetime)
declare @loop int = 0
while @loop < datediff(day, @from, @to)
begin
insert into @table values (dateadd(day, @loop, @from),dateadd(day, @loop + 1, @from))
set @loop = @loop + 2
end

select 
'Get-AzureRmConsumptionUsageDetail -StartDate '+convert(varchar(10),date_from,120)+' -EndDate '+convert(varchar(10),date_to,120)+' | Select-Object AccountName,BillingPeriodName,ConsumedService,Currency,DepartmentName,Id,InstanceId,InstanceLocation,InstanceName,IsEstimated,PretaxCost,Product,SubscriptionGuid,SubscriptionName,UsageEnd,UsageQuantity,UsageStart | Export-Csv -Path "'+@path+'\'+@file_name+'_'+replace(convert(varchar(10),date_from,120),'-','_')+'_to_'+replace(convert(varchar(10),date_to,120),'-','_')+'.csv"'
from @table
end
