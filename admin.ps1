#to get all instance in the machain 
dir 'HKLM:\Software\Microsoft\Microsoft SQL Server\' | Where-Object {$_.property -like "*(default)*" -and $_.Name -like "*MSSQL*"}
