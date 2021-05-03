__KeyVault_Update_DevOps_Service_Connection_MUI_and_Storage_DEV_Local

01 May 2021
12:19

######################################################################################################################################
#                                                                                                                                    #  
#  Remember to run script in Administrator: Windows Powershell ISE                                                                   #                                                                                                                              #
#                                                                                                                                    #
#  This script updates the Local and main KeyVault policies to provide the permissions for the  Release Pipeline Service Connections # 
#  so the other powershell tasks can run in the pipeline.                                                                            #
#                                                                                                                                    #
#  The User Managed Identity is provided the permission to Read and List the certificates which is required in the Application       # 
#  Gateway HTTP Listener configuration task                                                                                          #   
#                                                                                                                                    #
#  The details of the Storage account are retreived and secrets are created in KeyVault which are then used by any functions         #
#  created to carry out storage actions                                                                                              #
#                                                                                                                                    #
###################################################################################################################################### 

#################################### Update three variables below before running script ###############################################
######################################################################################################################################
#                                                                                                                                    #
############ Solution name is also the middle part of the resource group name and is consistent through all the scripts ##############
$solutionName = "aprildemo"                                                                                                         
#                                                                                                                                    #                                                                                                                           #
######################## The three character abbreviation used in the ARM template deploying the local keyvault ###################### 
$localKeyVaultAbbrv = "apd"
#                                                                                                                                    #
##################################### The abbrviation used in the ARM template deploying the keyvault ################################ 
$AzSolutionAbbrv = "aprild"
#                                                                                                                                    #
############################## All manual variables updated the script can now be run ################################################
########################### Running as Administrator will then connect to Azure with your Admin account ##############################
#                                                                                                                                    #
Connect-AzAccount
Connect-AzureAD
#                                                                                                                                    #
######################################## The three letter environment prefix DEV #####################################################
$env = "dev"                                                                                                                  
#                                                                                                                                    #
######################## The three character subscription prefix n01 for DEV and TST then p01 for UAT and PRD ########################
$prefix = "n01"
#         
######################################################################################################################################

############# Setting the Complete Environment Prefix for all the variables using pipeline naming convention #########################
$AzEnvPrefix = $prefix+$env+"uk"
######################################################################################################################################
############################ Pipeline Naming convention to for faster pipeline to local script conversion ############################
$AzPsMuiName = "demouk-shared-mui"
$AzPsMuiRG = "demouk-shared-rg"
$AzPsServConnName = "demoag001 DevOPs Non-PRD UK "+$solutionName+" ("+$env.ToUpper()+")"
$AzCLILocalKeyVault = $AzEnvPrefix+"-"+$localKeyVaultAbbrv+"-local-kv"
$AzCLIKeyVaultName = $AzEnvPrefix+"-"+$AzSolutionAbbrv+"-kv"
$AzCLIResourceGroupName = $AzEnvPrefix+"-"+$solutionName+"-rg"
$AzPsStorageAccount = $AzEnvPrefix+$solutionName

######################################################################################################################################
################################### Variable pattern used in script both pipeline and local ##########################################
$ServConnName = $AzPsServConnName
$LocalKeyVault = $AzCLILocalKeyVault
$Keyvault = $AzCLIKeyVaultName
$MuiRg = $AzPsMuiRG
$MuiName = $AzPsMuiName
$resourcegroupname = $AzCLIResourceGroupName
$StorageAccount = $AzPsStorageAccount
######################################################################################################################################
#### Local scripts have the module check as running the script the first time will install the modules and they remain installed ####
$AADModuleCheck = Get-Module AzureAD -ErrorAction SilentlyContinue
$MSIModuleCheck = Get-Module Az.ManagedServiceIdentity -ErrorAction SilentlyContinue

if(!$AADModuleCheck){
Write-Host "Installing PowerShell Azure AD Module"
Install-Module AzureAD -Confirm:$False -Force
Import-Module AzureAD
}

if(!$MSIModuleCheck){
Write-Host "Installing PowerShell Managed Service Idendtity Module"
Install-Module Az.ManagedServiceIdentity -Confirm:$False -Force
Import-Module Az.ManagedServiceIdentity
}
#####################################################################################################################################
#####################################################################################################################################
###################### Start of Local KeyVault block ############################
Write-Host "Retrieve Service Connection Application ID"
$AzureDevOpsServicePrincipal = Get-AzADServicePrincipal -DisplayName $ServConnName
$AzureDevOpsServicePrincipal
$AppId = $AzureDevOpsServicePrincipal.Id
$AppId
$LocalKeyVault
######### Sets Policy for Service Connection ############
Write-Host "Service Connection Application ID retreived now setting KeyVault Permissions"
Set-AzKeyVaultAccessPolicy -VaultName $LocalKeyVault -ObjectId $AppId -PermissionsToSecrets 'all' -PermissionsToCertificates 'all'
Write-Host "Permissions set for Service Connection Application ID"

##################### End of Local KeyVault block ##############################

###################### Start of Main KeyVault block ############################

$Keyvault
########## Sets Policy for Service Connection ###########
Set-AzKeyVaultAccessPolicy -VaultName $Keyvault -ObjectId $AppId -PermissionsToSecrets 'all' -PermissionsToCertificates 'all' -BypassObjectIdValidation
Write-Host "Permissions set for Service Connection Application ID"

########## Sets Policy for Managed User Identity ########
Write-Host "Retrieve Managed User Identity Object ID"
$ManagedUserIdentity = Get-AzUserAssignedIdentity -ResourceGroupName $MuiRg -Name $MuiName
$ManagedUserIdentity
$MuiId = $ManagedUserIdentity.PrincipalId
$MuiId

Write-Host "Managed User Identity Object ID retreived now setting KeyVault Permissions"
Set-AzKeyVaultAccessPolicy -VaultName $Keyvault -ObjectId $MuiId -PermissionsToSecrets Get,List -PermissionsToCertificates Get,List,GetIssuers,ListIssuers -BypassObjectIdValidation
Write-Host "Permissions set for Managed User Identity Object ID"

## Retrieves Storage Account details and creates secrets in KeyVault ##

Write-Host "Retrieving storage account Key"
$storageaccount_key = Get-azStorageaccountKey -Name $StorageAccount -resourcegroupname $ResourceGroupName | Where-Object {$_.KeyName -eq "key1"}
$storage_key = $storageaccount_key.Value

## Creates Storage Connection String ##

Write-Host "Storage Connection String"
$storageConnectionStringURI = "DefaultEndpointsProtocol=https;AccountName=$StorageAccount;AccountKey=$storage_key;EndpointSuffix=core.windows.net"

## Converts the strings into Secure Strings required to create KeyVault secrets

Write-Host "Secure string for KeyVault Secret"
$ConnectionString = ConvertTo-SecureString $storageConnectionStringURI -AsPlainText -Force
$StorageKey = ConvertTo-SecureString $storage_key -AsPlainText -Force

# Creates or updates secrets in KeyVault for Functions in FunctionApp or Api App #

Write-Host "Setting values for Storage secrets in KeyVault"
Set-AzKeyVaultSecret -VaultName $KeyVault -Name 'StorageConnectionString' -SecretValue $ConnectionString
Set-AzKeyVaultSecret -VaultName $KeyVault -Name 'StorageAccountKey' -SecretValue $StorageKey
##################### End of Main KeyVault block ##############################
##################### Configuration Permissions DNS and App Registrations #####
$Pipeline_App_Registrations = Get-AzKeyVaultSecret -VaultName 'demoukkv' -Name 'Pipeline-App-Registrations-ID' -AsPlainText
$Pipeline_demoag001Tech_DNS = Get-AzKeyVaultSecret -VaultName 'demoukkv' -Name 'Pipeline-demoTech-DNS-ID' -AsPlainText
$Pipeline_demoag001_Apps_DNS = Get-AzKeyVaultSecret -VaultName 'demoukkv' -Name 'Pipeline-demo-Apps-DNS-ID' -AsPlainText
$Pipeline_Wildcard_Cert_Reader = Get-AzKeyVaultSecret -VaultName 'demoukkv' -Name 'Pipeline-Wildcard-Cert-Reader-ID' -AsPlainText


Add-AzureADGroupMember -ObjectId $Pipeline_App_Registrations -RefObjectId $AppId -ErrorAction SilentlyContinue
Add-AzureADGroupMember -ObjectId $Pipeline_demoTech_DNS -RefObjectId $AppId -ErrorAction SilentlyContinue
Add-AzureADGroupMember -ObjectId $Pipeline_demo_Apps_DNS -RefObjectId $AppId -ErrorAction SilentlyContinue
Add-AzureADGroupMember -ObjectId $Pipeline_Wildcard_Cert_Reader -RefObjectId $AppId -ErrorAction SilentlyContinue
