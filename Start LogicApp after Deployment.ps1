# Variables are set up as Pipeline variables not Library variables
#
## Script is used in Pipelines below (please add to list if used in a new pipeline
# Transactional Automation Azure Api Release
#

[CmdletBinding()]

param (
        $AzPsLogicAppResourceGroupName,
        $AzPsLogicAppName1,
        $AzPsLogicAppName2

       )

Write-Host "Setting variables"

$logicAppResourceGroupName = $AzPsLogicAppResourceGroupName
$logicApp1 = $AzPsLogicAppName1
$logicApp2 = $AzPsLogicAppName2

Write-Host "Running Function"

#Logic Apps with Recurrence Trigger

Set-AzLogicApp -ResourceGroupName $logicAppResourceGroupName -Name $logicApp1 -State "Enabled" -Force

Set-AzLogicApp -ResourceGroupName $logicAppResourceGroupName -Name $logicApp2 -State "Enabled" -Force
