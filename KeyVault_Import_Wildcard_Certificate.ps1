KeyVault_Import_Wildcard_Certificate

28 April 2021
19:44

[CmdletBinding()]
param (
        
        $AzPsSolutionAbbrv,
        $AzPsNonProdSubscription,
        $AzPsCertName,
        $AzEnvPrefix
       )
 ########## MODIFY VARIABLES BELOW BEFORE RUNNING SCRIPT #################
 #### The solution name is the abbrviation of the certificate name eg p01 ####
#$SolutionName = $AzPsSolutionName
#### The solution name is the abbrviation of the certificate name eg p01 ####
$CertName = $AzPsCertName
######### Resource Group containing the certificate #####################
#$SolutionNameRg =  $AzPsSolutionNameRg
###### Solution Abbreviation for KeyVault (might be the same as solution name) ######
$SolutionAbbrv = $AzPsSolutionAbbrv
 ############## Subscription containing certificate #######################
 $Subscription = $AzPsNonProdSubscription
 $pfxpath = $Env:AGENT.TEMPDIRECTORY
################# Environment Variables #################################
$envprefix = $AzEnvPrefix
###################### Connect to Azure #################################
#Connect-AzAccount
#########################################################################
#### Note if the location of the Wildcard Certificate is moved the Resource Group Name will need to be Updated
####################### Static Variables ################################
$WildCardRgName = "n01tstuw-shared-rg"
#$ResourceGroupName = $envprefix+"-"+$SolutionNameRg+"-rg"
$SolutionKeyVault = $envprefix+"-"+$SolutionAbbrv+"-kv"
$CertNameWildCard = $CertName
$WildcardPfxName = $CertNameWildCard.Replace("-cert" ,"")
$Usercontext = Get-AzContext
$Usercontext.Account.Id
#$loginid = $Usercontext.Account.Id
$SubscriptionId = $Subscription
$context = $Subscription
Set-AzContext -SubscriptionId $context

## Get the KeyVault Resource Url and KeyVault Secret Name were the certificate is stored API ##

 $ascWildCardResource = Get-AzResource -ResourceId "/subscriptions/$subscriptionId/resourceGroups/$WildCardRgName/providers/Microsoft.CertificateRegistration/certificateOrders/$CertNameWildCard"
 $ascWildCardResource
 $WildCardCertProps = Get-Member -InputObject $ascWildCardResource.Properties.certificates[0] -MemberType NoteProperty
 $WildCardCertificateName = $WildCardCertProps[0].Name
 $WildCardKeyVaultId = $ascWildCardResource.Properties.certificates[0].$WildCardCertificateName.KeyVaultId
 $WildCardKeyVaultSecretName = $ascWildCardResource.Properties.certificates[0].$WildCardCertificateName.KeyVaultSecretName
###########################################################################################
## Split the resource URL of KeyVault and get KeyVaultName and KeyVaultResourceGroupName Api ###
 $WildCardKeyVaultIdParts = $WildCardKeyVaultId.Split("/")
 $WildCardKeyVaultName = $WildCardKeyVaultIdParts[$WildCardKeyVaultIdParts.Length - 1]
 #$WildCardKeyVaultResourceGroupName = $WildCardKeyVaultIdParts[$WildCardKeyVaultIdParts.Length - 5]
 ##########################################################################################
 
 ## --- !! NOTE !! ----
 ## Only users who can set the access policy and has the the right RBAC permissions can set the access policy on KeyVault, if the command fails contact the owner of the KeyVault
 #Set-AzKeyVaultAccessPolicy -ResourceGroupName $WildCardKeyVaultResourceGroupName -VaultName $WildCardKeyVaultName -UserPrincipalName $loginId -PermissionsToSecrets get
 #Write-Host "Get Secret Access to account $loginId has been granted from the KeyVault, please check and remove the policy after exporting the certificate"
 
 ########### Getting the secret from the KeyVault for the Api Certificate #################
 $WildCardSecret = Get-AzKeyVaultSecret -VaultName $WildCardKeyVaultName -Name $WildCardKeyVaultSecretName
 $WildCardSecretKey = ConvertTo-SecureString -String $WildCardSecret -AsPlainText –Force
 $WildCardSecretValueText = '';
$WildCardSsPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($WildCardSecret.SecretValue)
try {
    $WildCardSecretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($WildCardSsPtr)
} finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($WildCardSsPtr)
}
$WildCardPfxCertObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @([Convert]::FromBase64String($WildCardSecretValueText),"",[System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
$WildCardPfxPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 50 | % {[char]$_})
$importWildCardPFX = ConvertTo-SecureString -String $WildCardPfxPassword -AsPlainText –Force
#$pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12
#$clearBytes = $WildCardPfxCertObject.Export($pkcs12ContentType,$WildCardPfxPassword)
#$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
#$Certsecret = ConvertTo-SecureString -String $fileContentEncoded -AsPlainText –Force
$secretContentType = 'application/x-pkcs12'
Write-Output "Export Certificate to PFX"
Export-PfxCertificate -Cert $WildCardPfxCertObject -FilePath "$pfxpath\$WildcardPfxName.pfx" -Password $importWildCardPFX

$pfxlocation = "$pfxpath\$WildcardPfxName.pfx"
Write-Output "Import Certificate to KeyVault"
Import-AzKeyVaultCertificate -VaultName $SolutionKeyVault -Name $CertNameWildCard -FilePath $pfxlocation -Password $importWildCardPFX
Write-Output "Certificate imported into KeyVault"
