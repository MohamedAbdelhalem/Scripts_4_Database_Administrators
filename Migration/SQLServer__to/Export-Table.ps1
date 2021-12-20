Function Export-Table {
param (
[Parameter(Mandatory)]
[string]$server,
[string]$database,
[string]$table,
[string]$directory,
[string]$header,
[int]$patch
)
$path=""
$bulk=1000
$from=(($patch * $bulk) + 1)
$to= (($patch + 1) * $bulk)

$query="exec [dbo].[sp_export_table_data] @table='"+$table+"',@header="+$header+",@patch="+$patch
$query
if ($header -eq "1")
        {
        $path = $directory+$table+"_table.sql"
    }
else
    {
        $path = $directory+$table+"_"+$from+"_"+$to+".sql"
    }
$path
Invoke-Sqlcmd -ServerInstance $server -Database $database -Query  $query | Out-File $path -Width 10240 | Format-Table  -AutoSize -HideTableHeaders
}
