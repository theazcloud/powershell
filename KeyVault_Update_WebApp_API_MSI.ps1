# Variables are set up as Pipeline variables not Library variables
#
## Script is used in Pipelines below (please add to list if used in a new pipeline
#
[CmdletBinding()]
param (
        $AzCLIResourceGroupName,
        $AzCLIWebAppApiName,
        $AzCLIKeyVaultName
       )
$resourcegroupname = $AzCLIResourceGroupName
$webappapiname = $AzCLIWebAppApiName
$keyvault = $AzCLIKeyVaultName
Install-Module AzureAD -Confirm:$False -Force
Import-Module AzureAD
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
Write-Host "Retrieve Web App API Managed Identity"
$getwebappapiId = get-azwebapp -ResourceGroupName  $resourcegroupname -Name $webappapiname
$objectId = $getwebappapiId.Identity.PrincipalId
Write-Host "Managed ID retreived now setting KeyVault Permissions"
Set-AzKeyVaultAccessPolicy -VaultName $keyvault -ObjectId $objectId -PermissionsToSecrets Get,List -BypassObjectIdValidation
Write-Host "Permissions set for Web App API ID"
