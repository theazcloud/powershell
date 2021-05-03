##################### Input Variables ##############################
$tenantID = ""
$environment = ""
$appsuffix = ""
$solution = ""

#####################################################################


#################### Static Variables ##############################
$appName = "$solution $appsuffix ($environment)"
$g = [guid]::NewGuid()
$apiURI = "api://$g"

#####################################################################

###################### Connect Azure AD #############################

Write-Host "connecting to Azure AD"

Connect-AzureAD 

Write-Host "connected to AzureAD"

####################################################################


####### Check for App Registrations and create if not exist #########

Write-Host "Checking if App Registration $appName exists"


if(!($myFuncApp = Get-AzureADApplication -Filter "DisplayName eq '$($funcappName)'" -ErrorAction SilentlyContinue))
{
    $myApp = New-AzureADApplication -DisplayName $funcappName 

}
Write-Host "App Regsitration $appName exists or has now been created"


#######################################################################
