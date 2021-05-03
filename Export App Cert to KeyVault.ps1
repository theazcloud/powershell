# If the commands fail first check you have the Powershell Az Modules installed
 # Run Get-Module - if Az.* modules are not returned remove the # from the four lines below 
 # select them then right mouse click and run selection
 # $proxyString = ""
 # $proxyUri = new-object System.Uri($proxyString)
 # [System.Net.WebRequest]::DefaultWebProxy = new-object System.Net.WebProxy ($proxyUri, $true)
 # Install-Module Az -AllowClobber
 # Once installed check Get-Module again

 ########## MODIFY VARIABLES BELOW BEFORE RUNNING SCRIPT #################

 #### The solution name is the abbrviation of the certificate name eg p01 ####

 $SolutionName = ""

######### Resource Group containing the certificate #####################

 $SolutionNameRg = ""

############## Subscription containing certificate #######################

 $Subscription = ""

 $pfxpath = ""

#########################################################################

###################### Connect to Azure #################################

Connect-AzAccount

#########################################################################

####################### Static Variables ################################

$ResourceGroupName = $SolutionNameRg+"-rg"

$CertNameApi = $SolutionName+"-api-crt"

$ApiPfxname = $CertNameApi.Replace("-crt" ,"")

$vaultName = $SolutionName+"-key"

$Usercontext = Get-AzContext

$Usercontext.Account.Id

$loginid = $Usercontext.Account.Id

$SubscriptionId = $Subscription

$context = $Subscription

Set-AzContext -SubscriptionId $context


## Get the KeyVault Resource Url and KeyVault Secret Name were the certificate is stored API ##


 $ascApiResource = Get-AzResource -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.CertificateRegistration/certificateOrders/$CertNameApi"

 $ApiCertProps = Get-Member -InputObject $ascApiResource.Properties.certificates[0] -MemberType NoteProperty

 $ApiCertificateName = $ApiCertProps[0].Name

 $ApiKeyVaultId = $ascApiResource.Properties.certificates[0].$ApiCertificateName.KeyVaultId

 $ApiKeyVaultSecretName = $ascApiResource.Properties.certificates[0].$ApiCertificateName.KeyVaultSecretName

###########################################################################################

## Split the resource URL of KeyVault and get KeyVaultName and KeyVaultResourceGroupName Api ###

 $ApiKeyVaultIdParts = $ApiKeyVaultId.Split("/")

 $ApiKeyVaultName = $ApiKeyVaultIdParts[$ApiKeyVaultIdParts.Length - 1]

 $ApiKeyVaultResourceGroupName = $ApiKeyVaultIdParts[$ApiKeyVaultIdParts.Length - 5]

 ##########################################################################################

 
 ## --- !! NOTE !! ----

 ## Only users who can set the access policy and has the the right RBAC permissions can set the access policy on KeyVault, if the command fails contact the owner of the KeyVault

 Set-AzKeyVaultAccessPolicy -ResourceGroupName $ApiKeyVaultResourceGroupName -VaultName $ApiKeyVaultName -UserPrincipalName $loginId -PermissionsToSecrets get

 Write-Host "Get Secret Access to account $loginId has been granted from the KeyVault, please check and remove the policy after exporting the certificate"

 

 ########### Getting the secret from the KeyVault for the Api Certificate #################

 $ApiSecret = Get-AzKeyVaultSecret -VaultName $ApiKeyVaultName -Name $ApiKeyVaultSecretName

 $ApiSecretValueText = '';
$ApiSsPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiSecret.SecretValue)
try {
    $ApiSecretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ApiSsPtr)
} finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ApiSsPtr)
}

$ApiPfxCertObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @([Convert]::FromBase64String($ApiSecretValueText),"",[System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)

$ApiPfxPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 50 | % {[char]$_})

$importAppPFX = ConvertTo-SecureString -String $ApiPfxPassword -AsPlainText –Force

$pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12

$clearBytes = $ApiPfxCertObject.Export($pkcs12ContentType,$ApiPfxPassword)

$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)

$Certsecret = ConvertTo-SecureString -String $fileContentEncoded -AsPlainText –Force

$secretContentType = 'application/x-pkcs12'


Export-PfxCertificate -Cert $ApiPfxCertObject -FilePath "$pfxpath\$ApiPfxname.pfx" -Password $importAppPFX


$pfxlocation = "$pfxpath\$ApiPfxname.pfx"


Import-AzKeyVaultCertificate -VaultName $vaultName -Name $CertNameApi -FilePath $pfxlocation -Password $importAppPFX
