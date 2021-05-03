# Variables are set up as Pipeline variables not Library variables
#
## Script is used in Pipelines below (please add to list if used in a new pipeline
# Transactional Automation Azure Functions Release
#

[CmdletBinding()]

param (
        $AzCLIResourceGroupName,
        $AzPSWebAppName,
        $AzPsWebjobName,
        $AzPswebJobBuildPath
       )


$resourceGroupName = "$AzPsResourceGroupName" #the name of the resource group
$webappName = "$AzPSWebAppName" #the name of the webapp you would like to deploy to)
$webjobName = "$AzPsWebjobName" #the name of the webjob
$path =  "$AzPswebJobBuildPath" #path to the .zip containing the webjob
$scheduleName = "continuous" #Name of the webjob, either 'continuous' or 'triggered'

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

Write-Host "Checking path for build"

if (-not (Test-Path $path)) 
{
    throw [System.IO.FileNotFoundException] "$($path) not found."
}

# Retrieve WebDeploy credentials for uploading a file using Kudu
$publishingProfilesXml = [xml](Get-AzWebAppPublishingProfile -OutputFile test.xml -Format WebDeploy -Name $webappName -ResourceGroupName $resourceGroupName )
$publishingProfileWebDeploy = $publishingProfilesXml.FirstChild.ChildNodes[0]   
$username = $publishingProfileWebDeploy.userName
$password = $publishingProfileWebDeploy.userPWD
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))
$apiBaseUrl = "https://$($webappName).scm.azurewebsites.net/api"

# Upload the deployment zip to Kudu
$files = Get-ChildItem -Path $path -Recurse
Test-Path -Path $files[0]   
$authHeader = " Basic " + $base64AuthInfo
$deployUrl = "$($apiBaseUrl)/$($scheduleName)jobs/$($webjobName)"
  
Write-Host "Uploading " $path  " to " $deployUrl
$ZipHeaders = @{
Authorization = $authHeader
	"Content-Disposition" = "attachment; filename=$($files[0].Name)"
}

$response = Invoke-WebRequest -Uri  $deployUrl -Headers $ZipHeaders -InFile $files[0] -ContentType "application/zip" -Method Put
Write-Host $response