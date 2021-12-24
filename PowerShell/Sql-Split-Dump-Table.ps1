Function Sql-Split-Dump-Table {
param (
[Parameter(Mandatory)]
[string]$server,
[string]$database,
[string]$table,
[string]$migrated_to,
[string]$directory,
[int]$computed,
[int]$bulk
)
$path=""
$query="exec [dbo].[sp_export_table_data] 
@table='"+$table+"' ,
@header="+$header+" ,
@with_computed="+$computed+", 
@patch="+$patch
$loop = 1 
$prev = 0 
$prog = 1
$pct =0.0 
$rows=0.0

$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "integrated security=SSPI; data source="+$server+"; initial catalog="+$database+";"
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "[sp_Table_Rows]"
$SqlCmd.Connection = $SqlConnection
$SqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
$SqlCmd.Parameters.Add("@rows", 0) | out-null
$SqlCmd.Parameters["@rows"].Direction = [system.Data.ParameterDirection]::Output

$SqlConnection.Open()
$SqlCmd.ExecuteNonQuery()
$rows = $SqlCmd.Parameters["@rows"].Value
$SqlConnection.Close()
$pct = 100.0 / ([decimal]($rows*1.0) / [decimal]($bulk*1.0))
for ($i = 0; $i -lt ([decimal]($rows*1.0) / [decimal]($bulk*1.0)); $i++)
{
    $from=(($i * $bulk) + 1)
    $to= (($i + 1) * $bulk)
    if ($i -eq 0)
    {
        if ($directory.substring($directory.length-1,1) -ne "\")
	    {
		    $directory = $directory+"\"
	    }
        $path = $directory+$table+"-"+$migrated_to.replace(" ","").tolower()+"-"+"table.sql"
        $query="exec [dbo].[sp_export_table_data] @table='"+$table+"',@migrated_to='"+$migrated_to+"',@header=1,@with_computed="+$computed+",@bulk="+$bulk+",@patch=0"
        #$query
        #$path
        Invoke-Sqlcmd -ServerInstance $server -Database $database -Query $query | Out-File $path -Width 10240 | Format-Table -AutoSize -HideTableHeaders
    }
    if ($directory.substring($directory.length-1,1) -ne "\")
	{
		$directory = $directory+"\"
	}
    $path = $directory+$table+"-"+$migrated_to.replace(" ","").tolower()+"-"+$from+"-"+$to+".sql"
    $query="exec [dbo].[sp_export_table_data] @table='"+$table+"',@migrated_to='"+$migrated_to+"',@header=0,@with_computed="+$computed+",@bulk="+$bulk+",@patch="+$i
    #$query
    #$path
    Invoke-Sqlcmd -ServerInstance $server -Database $database -Query $query | Out-File $path -Width 10240 | Format-Table -AutoSize -HideTableHeaders
    $prog = [Math]::Ceiling($pct * $loop)
    if ($prev -ne $prog)
    {
        $prog.ToString()+"%";
    }
    $loop ++
    $prev = $prog
}
}

Sql-Split-Dump-Table -server . -database AdventureWorks2017 -table "Sales.Customer" -migrated_to "postgresql" -directory C:\Data\AdventureWorks2017 -bulk 1000 -computed 0

