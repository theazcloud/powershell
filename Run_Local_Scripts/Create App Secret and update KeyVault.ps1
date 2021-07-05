
      
####################################### Input Variables ##########################################

########################## Add the relevant details below before running script between the " "###
##################################################################################################

########## Enter App Registration Display Name #############

$appName = ""

########## Enter Resource Group name containing KeyVault ########

$ResourceGroupName = ""

############ Enter KeyVault name #####################

$KeyVaultName = ""

############ Enter KeyVault Secret Display Name and Description which the application will use #####

$KeyVaultSecretName = ""


$keyVaultSecretDescription = ""


######################### Now you can save and run the script ######################################

##################### Connect Azure AD #############################

Write-Host "Installing AzureAD"

Install-Module AzureAD -Force -Scope CurrentUser

Write-Host "Azure AD Installed"

Write-Host "Importing Azure AD Module"

Import-Module AzureAD

Write-Host "Azure AD Module imported"

####################################################################


##################### Connect Azure AD #############################

Write-Host "connecting to Azure AD"

Connect-AzureAD 

Write-Host "connected to AzureAD"

####################################################################

#################################################################################################


$myApp = Get-AzureADApplication -Filter "DisplayName eq '$($appName)'"


##################################################################################################


################################# Create App Registration Secret ################################

$startDate = Get-Date
$endDate = $startDate.AddYears(1)
$aadApisecret = New-AzureADApplicationPasswordCredential -ObjectId $myApi.ObjectId -CustomKeyIdentifier "API Connection secret" -StartDate $startDate -EndDate $endDate
$SecureApisecret = ConvertTo-SecureString $aadApisecret -AsPlainText -Force

#################################################################################################

Write-Host "Setting values for Storage secrets in KeyVault"

Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultSecretName -ContentType $keyVaultSecretDescription -SecretValue $SecureApisecret
