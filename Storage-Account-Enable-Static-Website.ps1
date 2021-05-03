Template-Websites-Enable-Static-Website

09 April 2021
14:53

# Variables are set up as Pipeline variables not Library variables
#
## Script is used in Pipelines below (please add to list if used in a new pipeline
#

[CmdletBinding()]
param (
        $AzCLIStorageAccountName
       )
$StorageAccountName = $AzCLIStorageAccountName
Write-Host "Enabling Static Website on Storage Account $StorageAccountName"
az storage blob service-properties update --account-name $StorageAccountName --static-website --404-document 404.html --index-document index.html
