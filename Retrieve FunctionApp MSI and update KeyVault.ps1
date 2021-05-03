﻿Retrieve FunctionApp MSI and update KeyVault

12 March 2021
09:13

# Variables are set up as Pipeline variables not Library variables
#
## Script is used in Pipelines below (please add to list if used in a new pipeline
# Transactional Automation Azure Functions Release
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

Write-Host "Managed ID retreived now setting KeyVault Permissions"

Set-AzKeyVaultAccessPolicy -VaultName $keyvault -ObjectId $objectId -PermissionsToSecrets Get,List -BypassObjectIdValidation

Write-Host "Permissions set for new Function App ID"