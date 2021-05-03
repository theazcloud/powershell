Restore Azure SQL Database to same server

12 March 2021
09:11


[CmdletBinding()]

param (

       $AzPsDatabase,
       $AzPsDbResourceGroup,
       $AzPsDDbServer,
       $AzPsRecoveryPoint,
       $AzPsRestoredDbName

       )

$MinutesAgo = $AzPsRecoveryPoint
$PointInTime = (Get-Date).AddMinutes(-($MinutesAgo))
$RestorePoint = $PointInTime.ToString('HH-mm-dd-MM-yyyy')

$DatabaseName = $AzPsDatabase
$ResourceGroupName = $AzPsDbResourceGroup
$DatabaseServerName = $AzPsDDbServer
$REstoredDB = $AzPsRestoredDbName+$RestorePoint


Write-Host "Restoring Database"

$Database = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $DatabaseServerName -DatabaseName $DatabaseName
Restore-AzSqlDatabase -FromPointInTimeBackup -PointInTime $PointInTime -ResourceGroupName $Database.ResourceGroupName -ServerName $Database.ServerName -TargetDatabaseName $REstoredDB -ResourceId $Database.ResourceID -Edition "Standard" -ServiceObjectiveName "S0"

Write-Host "Database restored"

Write-Host "Renaming corrupted Database"

Set-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $DatabaseServerName -DatabaseName $DatabaseName -NewName $DatabaseName"corrupted"$RestorePoint

Write-Host "corrupted database renamed"

Write-Host "Renaming restored Database"

Set-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $DatabaseServerName -DatabaseName $REstoredDB -NewName $DatabaseName

Write-Host "database restore complete"
