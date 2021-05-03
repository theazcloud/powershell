# Variables are set up as Pipeline variables not Library variables
#
## Script is used in Pipelines below (please add to list if used in a new pipeline
#
[CmdletBinding()]
param (
        $AzCLIResourceGroupName,
        $AzCLIFunctionAppName,
        $AzCLIKeyVaultName
       )
$resourcegroupname = $AzCLIResourceGroupName
$functionappname = $AzCLIFunctionAppName
$keyvault = $AzCLIKeyVaultName
Install-Module AzureAD -Confirm:$False -Force
Import-Module AzureAD
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
Write-Host "Retrieve Function App Managed Identity"
$getfunctionappId = get-azwebapp -ResourceGroupName  $resourcegroupname -Name $functionappname
$objectId = $getfunctionappid.Identity.PrincipalId
$KeyVaultObject = Get-AzKeyVault -VaultName $keyvault
$KeyVaultName = $KeyVaultObject.VaultName
Write-Host "Managed ID retreived now setting KeyVault Permissions"
Set-AzKeyVaultAccessPolicy -VaultName $KeyVaultName -ObjectId $objectId -PermissionsToSecrets Get,List -BypassObjectIdValidation
Write-Host "Permissions set for new Function App ID"
