# Variables are set up as Pipeline variables not Library variables
#
## Script is used in Pipelines below (please add to list if used in a new pipeline
#
[CmdletBinding()]
param (
        $AzPsStorageAccount,
        $AzCLIResourceGroupName,
        $AzCLIKeyVaultName
       )
$StorageAccount = $AzPsStorageAccount
$ResourceGroupName = $AzCLIResourceGroupName
$KeyVaultName = $AzCLIKeyVaultName
Write-Host "Retrieving storage account Key"
$storageaccount_key = Get-azStorageaccountKey -Name $StorageAccount -resourcegroupname $ResourceGroupName | Where-Object {$_.KeyName -eq "key1"}
$storage_key = $storageaccount_key.Value
Write-Host "Storage Connection String"
$storageConnectionStringURI = "DefaultEndpointsProtocol=https;AccountName=$StorageAccount;AccountKey=$storage_key;EndpointSuffix=core.windows.net"
Write-Host "Secure string for KeyVault Secret"
$ConnectionString = ConvertTo-SecureString $storageConnectionStringURI -AsPlainText -Force
$StorageKey = ConvertTo-SecureString $storage_key -AsPlainText -Force
Write-Host "Setting values for Storage secrets in KeyVault"
Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'StorageConnectionString' -SecretValue $ConnectionString
Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'StorageAccountKey' -SecretValue $StorageKey
