[CmdletBinding()]

param ( 

        $AzPsSolutionName,
        $AzPssolutionabbrv,
        $AzPskvappname,
        $AzPsenvironment,
        $AzPssubsprefix,
        $AzPslocation,
        $AzPsTenantID

      )
      
####################################### Input Variables ##########################################

$SolutionName = $AzPsSolutionName
$solutionabbrv = $AzPssolutionabbrv
$kvappname = $AzPskvappname
$environment = $AzPsenvironment
$subsprefix = $AzPssubsprefix
$location = $AzPslocation
$appTenantId = $AzPsTenantID


##################################################################################################

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

##################### Connect Azure AD #############################

Write-Host "connecting to Azure AD"

Connect-AzureAD -AadAccessToken $aadToken -AccountId $context.Account -TenantId $tenantID

Write-Host "connected to AzureAD"

####################################################################


##################################### Script Variables ###########################################

$appsuffix = "APP"
$apisuffix = "API"
$appName = "$SolutionName $appsuffix ($environment)"
$apiName = "$SolutionName $apisuffix ($environment)"
$dbenv = $subsprefix+$environment.ToLower()+$location
$solutionrgnm = $dbenv+"-"+$solutionabbrv.ToLower()+"-rg"
$KeyVaultName = $dbenv+"-"+$kvappname+"-kv"
$ResourceGroupName = $solutionrgnm

$myApp = Get-AzureADApplication -Filter "DisplayName eq '$($appName)'"

$myApi = Get-AzureADApplication -Filter "DisplayName eq '$($apiName)'"

##################################################################################################

################################# Application User Management ####################################

$AumConfigName = "AumConfig--AumAuthConnString"

$AumConfigDesc = "API to AUM API Authorisation string"

##################################################################################################

######################################### Ad Graph Auth ##########################################

$AdGraphAuthName = "AuthConnectionStrings--AdGraphAuth"

$AdGraphAuthDesc = "API Connection to AdGraph located in API permissions App registration"

##################################################################################################

#################################### Graph API ###################################################

$GraphApiName = "AuthConnectionStrings--GraphApi"

$GraphApiDesc = "API to Graph API located in API permissions App registration"

##################################################################################################

##################################### Pims Data Api ##############################################

$PimsDataAuthName = "AuthConnectionStrings--PimsDataAuth"

$PimsDataAuthDesc = "API to PIMS Data Api authorisation"

##################################################################################################

############################## DB Auth and Connection String #####################################

$DbKeyVault = $SolutionName -replace '\s',''

$DbKeyVaultAuthStr = "AuthConnectionStrings--"+$DbKeyVault+"DbAuth"

$SolutionDBAuthName = "AuthConnectionStrings--"+$DbKeyVault+"DbAuth"

$SolutionDBAuthDesc = "API to Solution Database authentication"

$SolutionDBConnStrName = $DbKeyVault+"DbInfo--ConnectionString"

$SolutionDBConnStrDesc = "Solution Database Connection String"

$DBConnectionString = "Server=tcp:"+$dbenv+"-sqlserver-001.database.windows.net,1433;Database="+$DbKeyVault+";"

##################################################################################################


################################# Create App Registration Secret ################################

$startDate = Get-Date
$endDate = $startDate.AddYears(1)
$aadApisecret = New-AzureADApplicationPasswordCredential -ObjectId $myApi.ObjectId -CustomKeyIdentifier "API Connection secret" -StartDate $startDate -EndDate $endDate

#################################################################################################

############################## Create App Authentication String #################################

$appClientId = $myapi.AppId
$appAuthString = "RunAs=App;AppId="+$appClientId+";TenantId="+$appTenantId+";AppKey="+$aadApisecret.Value
$SecureappAuthString = ConvertTo-SecureString $appAuthString -AsPlainText -Force

#################################################################################################

############################# Create DB Connection String #######################################

$SecureDBConnectionString = ConvertTo-SecureString $DBConnectionString -AsPlainText -Force

############################# Update KeyVault with Values ######################################


Write-Host "Setting values for Storage secrets in KeyVault"

Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $AumConfigName -ContentType $AumConfigDesc -SecretValue $SecureappAuthString

Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $AdGraphAuthName -ContentType $AdGraphAuthDesc -SecretValue $SecureappAuthString

Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $GraphApiName -ContentType $GraphApiDesc -SecretValue $SecureappAuthString

Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $PimsDataAuthName -ContentType $PimsDataAuthDesc -SecretValue $SecureappAuthString

Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $DbKeyVaultAuthStr -ContentType $SolutionDBAuthDesc -SecretValue $SecureappAuthString

Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SolutionDBConnStrName -ContentType $SolutionDBConnStrDesc -SecretValue $SecureDBConnectionString