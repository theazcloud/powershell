#####################################################################################################################################################
##                                                                                                                                                 ##
## This script creates the AD App Registrations to be used as Service Connections in Azure DevOps Structure in the Tenant the process can take     ##
##                                                                                                                                                 ##
#####################################################################################################################################################

##################### Input Variables #################################################

$env = @('dev')
$projectshortname = "csa"  # Update this variable with your short name for the project


#######################################################################################

$checkmodule = get-module AzureAd

if(-not $checkmodule){

        Write-Host 'Azure AD Powershell Module needs to be installed'

        Install-MOdule AzureAD

        Write-Host 'Azure AD PowerShell Mobule installed'


        Write-Host 'Azure AD Powershell Module needs to be imported'

        Import-MOdule AzureAD

        Write-Host 'Azure AD Module impoerted, we are good to go'

        }
else{

    Write-Host 'Azure AD Module detected, happy days!'

    }


###################### Connect Azure AD #############################

Write-Host "connecting to Azure AD"

Connect-AzureAD

Write-Host "connected to AzureAD"

Write-Host "connecting to Azure"

Connect-AzAccount

Write-Host "connected to Azure"

$context = Get-AzContext

$Sub = Get-AzSubscription -SubscriptionName $context.SubscriptionName

####################################################################

$SCName = "SC-"+${env}.ToUpper()+"-"+${projectshortname}.ToUpper()

Write-Host "Checking if App Registration $SCName exists"

if(-not($mySC = Get-AzureADApplication -Filter "DisplayName eq '$($SCName)'" -ErrorAction SilentlyContinue))
{

    $appURI = "https://"+$SCName.ToLower()

    $mySC = New-AzureADApplication -DisplayName $SCName -Homepage $appURI -ReplyUrls $appURI
}
Write-Host "App Regsitration $SCName exists or has now been created"


$SC = Get-AzureADApplication -SearchString $SCName

New-AzureADServicePrincipal -AccountEnabled $true -AppId $SC.AppId -AppRoleAssignmentRequired $true -DisplayName $SCName -Tags {WindowsAzureActiveDirectoryIntegratedApp}

Get-AzureADServicePrincipal -SearchString $SCName

$startDate = Get-Date
$endDate = $startDate.AddYears(1)
$aadApisecret = New-AzureADApplicationPasswordCredential -ObjectId $SC.ObjectId -CustomKeyIdentifier "Terraform Connection secret" -StartDate $startDate -EndDate $endDate
$SecureApisecret = ConvertTo-SecureString $aadApisecret -AsPlainText -Force


Write-Host '$env:ARM_CLIENT_ID='${SC.AppId}
Write-Host '$env:ARM_SUBSCRIPTION_ID='${Sub.Id}
Write-Host '$env:ARM_TENANT_ID='${context.TenantId}
Write-Host '$env:ARM_CLIENT_SECRET='${$aadApisecret.Value}

