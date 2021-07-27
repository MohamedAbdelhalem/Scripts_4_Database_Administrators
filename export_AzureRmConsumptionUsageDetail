$server = $args[0]
$database = $args[1]
$date_from = $args[2]
$date_to = $args[3]
$fileName = $args[4]
$folder = $args[5]
$file_array = @()
$date_array = @()
$file = ""
$getAzure = ""
$datediff = ([DateTime]$date_to - [DateTime]$date_from).TotalDays + 1

#fill the date array
for ($day = 0; $day -lt $datediff; $day++)
{
$date_array += ([datetime]::parseexact($date_from,'yyyy-MM-dd',$null)).adddays(+$day).tostring("yyyy-MM-dd")
}

#prepare the array of the export commands
for ($files = 0; $files -lt $date_array.count; $files++)
{
$file = $fileName+"_"+$date_array[$files].replace("-","_")+"_to_"+$date_array[$files].replace("-","_")+".csv"
$getAzure = "Get-AzureRmConsumptionUsageDetail -StartDate "+$date_array[$files]+" -EndDate "+$date_array[$files] +"| Select-Object AccountName,BillingPeriodName,ConsumedService,Currency,DepartmentName,Id,InstanceId,InstanceLocation,InstanceName,IsEstimated,PretaxCost,Product,SubscriptionGuid,SubscriptionName,UsageEnd,UsageQuantity,UsageStart | Export-Csv -Path "+$folder+"\"+$file
$file_array += $getAzure
}

#execute all export commands
for ($fnum = 0; $fnum -lt $file_array.count; $fnum++)
{
Invoke-Expression $file_array[$fnum];
}
