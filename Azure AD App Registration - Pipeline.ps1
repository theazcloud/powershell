
[CmdletBinding()]

param ( 

        $AzPsEnvironment,
        $AzPsSolution,
        $AzPsAppHomePageUrl,
        $AzPsinitialAppRole,
        $AzPsTenantId,
        $AzDevAppRoleIdAdm

      )

##################### Input Variables ##############################
$tenantID =  $AzPsTenantId
$environment = $AzPsEnvironment
$appsuffix = "APP"
$apisuffix = "API"
$solution = $AzPsSolution
$appHomePageUrl = $AzPsAppHomePageUrl
$initialAppRole = $AzPsinitialAppRole
$DevAppRoleId = $AzDevAppRoleIdAdm
#####################################################################


#################### Static Variables ##############################
$appName = "$solution $appsuffix ($environment)"
$apiName = "$solution $apisuffix ($environment)"
$g = [guid]::NewGuid()
$apiURI = "api://$g"
$appreplyUrls = @($appHomePageUrl)
#####################################################################


##################### Connect Azure AD #############################

Write-Host "Installing AzureAD"

Install-Module AzureAD -Force -Scope CurrentUser

Write-Host "Azure AD Installed"

Write-Host "Importing Azure AD Module"

Import-Module AzureAD

Write-Host "Azure AD Module imported"

####################################################################

$context = Get-AzContext
$aadToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.windows.net").AccessToken

$context
##################### Connecting to Azure AD #######################

Write-Host "connecting to Azure AD"

Connect-AzureAD -AadAccessToken $aadToken -AccountId $context.Account -TenantId $tenantID

Write-Host "connected to AzureAD"

####### Check for App Registrations and create if not exist #########

Write-Host "Checking if App Registration $appName exists"


if(!($myApp = Get-AzureADApplication -Filter "DisplayName eq '$($appName)'" -ErrorAction SilentlyContinue))
{
    $myApp = New-AzureADApplication -DisplayName $appName -Homepage $appHomePageUrl -ReplyUrls $appReplyURLs 
}


if(!($myApi= Get-AzureADApplication -Filter "DisplayName eq '$($apiName)'" -ErrorAction SilentlyContinue))
{
    $myApi = New-AzureADApplication -DisplayName $apiName -IdentifierUris $apiURI 
}


Write-Host "App Regsitration $appName exists or has now been created"

Write-Host "App Regsitration $apiName exists or has now been created"

#######################################################################

Write-Host "Creating variables for creation of new role"

############## Create variables for creation of role ################## 

$newApp = Get-AzADApplication -DisplayName $appName

$newApp
#######################################################################

Write-Host "Keep the same role Id across TST, UAT and PRD"

######### Keeping the same role ID across TST, UAT and PRD ############

$appRoles = $DevAppRoleId

if (!$appRoles){

    Write-Host "App role filter did not work so script will fail "
}

$appRoleId = $DevAppRoleId

Write-Host "The app Id to be used $appRoleId"

#########################################################################

Write-Host "Function to create Application role using $appRoleId"

############ Function to Create the initial application role ############


Function CreateAppRole([string] $Name, [string] $Description)
{
    $appRole = New-Object Microsoft.Open.AzureAD.Model.AppRole
    $appRole.AllowedMemberTypes = New-Object System.Collections.Generic.List[string]
    $appRole.AllowedMemberTypes.Add("User");
    $appRole.DisplayName = $Name
    $appRole.Id = $appRoleId
    $appRole.IsEnabled = $true
    $appRole.Description = $Description
    $appRole.Value = $Name;
    return $appRole
}

########################################################################


####### Create Initial Application Role for APP App Registration #######

$app = Get-AzureADApplication -ObjectId $newApp.ObjectId
$appRoles = $app.AppRoles
Write-Host "App Roles before addition of new role.."
Write-Host $appRoles

$newUserRole = CreateAppRole -Name $initialAppRole -Description "Application Administrator Role"
$appRoles.Add($newUserRole)

Write-Host "App role $newUserRole created"

#######################################################################


############ Update App registration with Initial role ################

Set-AzureADApplication -ObjectId $app.ObjectId -AppRoles $appRoles

#######################################################################