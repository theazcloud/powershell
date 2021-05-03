# Variables are set up as Pipeline variables not Library variables
#
## Script is used in Pipelines below (please add to list if used in a new pipeline
#

[CmdletBinding()]

param (
        $AzPsServConnName,
        $AzCLIKeyVaultName
       )

$Keyvault = $AzCLIKeyVaultName
$ServConnName = $AzPsServConnName

Install-Module AzureAD -Confirm:$False -Force
Import-Module AzureAD

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

Write-Host "Retrieve Service Connection Application ID"

$AzureDevOpsServicePrincipal = Get-AzADServicePrincipal -DisplayName $ServConnName
$AzureDevOpsServicePrincipal
$AppId = $AzureDevOpsServicePrincipal.Id
$AppId

Write-Host "Service Connection Application ID retreived now setting KeyVault Permissions"

Set-AzKeyVaultAccessPolicy -VaultName $keyvault -ObjectId $AppId -PermissionsToSecrets Get,List,Set,Delete,Backup,Restore -PermissionsToCertificates Get,List,Update,Create,Import -BypassObjectIdValidation

Write-Host "Permissions set for Service Connection Application ID"
