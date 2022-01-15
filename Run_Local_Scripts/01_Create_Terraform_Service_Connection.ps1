#####################################################################################################################################################
##                                                                                                                                                 ##
## This script creates the AD App Registrations to be used as Service Connections in Azure DevOps Structure in the Tenant the process can take     ##
##                                                                                                                                                 ##
#####################################################################################################################################################

##################### Input Variables #################################################

$env = @('dev')
$projectshortname = "csa"  # Update this variable with your short name for the project


#######################################################################################

$checkAadmodule = get-module AzureAd

if(-not $checkAadmodule){

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


$checkAzmodule = get-module Az

if(-not $checkAzmodule){

        Write-Host 'Azure Powershell Module needs to be installed'

        Install-MOdule Az

        Write-Host 'Azure PowerShell Mobule installed'


        Write-Host 'Azure Powershell Module needs to be imported'

        Import-MOdule AzureAD

        Write-Host 'Azure Module impoerted, we are good to go'

        }
else{

    Write-Host 'Azure Module detected, happy days!'

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

$Tenant = Get-AzTenant

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


$Secrets = Get-AzureADApplicationPasswordCredential -ObjectId $SC.ObjectId -ErrorAction SilentlyContinue

if(-not $Secrets){

        Write-Host "No secrets all good to go"
        }
else{


        foreach($Key in $secrets){

        Remove-AzureADApplicationPasswordCredential -KeyId $key.KeyId -ObjectId $SC.ObjectId

        }

}

Remove-Variable Secrets

$startDate = Get-Date
$endDate = $startDate.AddYears(1)
$aadApisecret = New-AzureADApplicationPasswordCredential -ObjectId $SC.ObjectId -CustomKeyIdentifier "Terraform Connection secret" -StartDate $startDate -EndDate $endDate




$env:ARM_CLIENT_ID=$(${SC}.AppId)
$env:ARM_SUBSCRIPTION_ID=$(${Sub}.Id)
$env:ARM_TENANT_ID=$(${Tenant}.Id)
$env:ARM_CLIENT_SECRET=$(${aadApisecret}.Value)

gci env:ARM_*


#gci env:ARM_* | Remove-Item








