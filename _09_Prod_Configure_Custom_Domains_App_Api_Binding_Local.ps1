################# Update Variables below to meet requirements ########

$AzPsSolutionName = "aprildemo"
$AppPfxPath = "C:\AzurePAS"
$AzCLIKeyVaultName = "p01prduk-aprild-kv"

##########################################
##############  Connect Az Account ##############

Connect-AzAccount

##################################################

$AzEnvPrefix = "p01prduk"
$AzPsProdSubscription = Get-AzKeyVaultSecret -VaultName 'n01devukpatternskv' -Name 'AzPsProdSubscription' -AsPlainText

Write-Host "Loading Variables"

############# The solution name is the main abbreviation ################

$SolutionName = $AzPsSolutionName

##########################################################################

$Subscription = $AzPsProdSubscription

$ProdContext = $Subscription

Set-AzContext -Subscription $ProdContext

#########################################################################

$solution = $SolutionName
$prefix = $AzEnvPrefix
$customdomain = $solution.ToLower()
$webApp = "$prefix-$solution-app"
$customdomainapp = "$customdomain-app"
$webapi = "$prefix-$solution-api"
$customdomainapi = "$customdomain-api"
$fqdnapp = "$customdomainapp.demo-apps.com"
$fqdnapp
$fqdnapi = "$customdomainapi.demo-apps.com"
$fqdnapi
$keyVault = $AzCLIKeyVaultName
$CertNameApi = "$prefix-$SolutionName-api-crt"
$CertNameApp = "$prefix-$SolutionName-app-crt"
$ApiPfxname = $CertNameApi.Replace("-crt" ,"")
$AppPfxname = $CertNameApp.Replace("-crt" ,"")

######### Resource Group containing the certificate #####################

$SolutionNameRg =  "$prefix-$SolutionName-rg"

###################### Connect to Azure #################################

$webAppResource = Get-AzWebApp -Name $webApp -ResourceGroupName $SolutionNameRg

$webappname = $webAppResource.Name

$webappname

$webApiResource = Get-AzWebApp -Name $webApi -ResourceGroupName $SolutionNameRg

$webapiname = $webApiResource.Name

$webapiname

#################### Variables to Keep ##################################


#########################################################################

Write-Host "Variables Loaded"


if(!($WebAppBindingCheck = Get-AzWebAppSSLBinding -WebAppName $webappname -ResourceGroupName $SolutionNameRg -ErrorAction SilentlyContinue))

{

Write-Output "Importing Certificate into App WebApp"

####################### This section is put together from a couple articles on the internet The $AppSecretValueText was a change to the original microsoft script ##########################

$AppSecret = Get-AzKeyVaultSecret -VaultName $keyVault -Name $CertNameApp

$AppPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 50 | % {[char]$_})

$AppSecretValueText = '';
$AppSsPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AppSecret.SecretValue)
try {
$AppSecretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($AppSsPtr)
} finally {
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($AppSsPtr)
}

$AppCertBytes = [System.Convert]::FromBase64String($AppSecretValueText)

$AppCertCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection

$AppCertCollection.Import($AppCertBytes,$null,[System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)

$AppProtectedCertificateBytes = $AppCertCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $AppPassword)


$ApppfxLocation = "$APppfxPath\$AppPfxname.pfx"

[System.IO.File]::WriteAllBytes($ApppfxLocation, $AppProtectedCertificateBytes)

############################### End of the Heinz 57 section #####################################################################################

New-AzWebAppSSLBinding -WebAppName $webappname -ResourceGroupName $SolutionNameRg -Name $fqdnapp -CertificateFilePath $ApppfxLocation -CertificatePassword $AppPassword -SslState SniEnabled

}
else 
{

Write-Host "SSL Binding  $WebAppBindingCheck already exists"

}


if(!($WebApiBindingCheck = Get-AzWebAppSSLBinding -WebAppName $webapiname -ResourceGroupName $SolutionNameRg -ErrorAction SilentlyContinue))

{

Write-Output "Importing Certificate into Api WebApp"

####################### This section is put together from a couple articles on the internet The $AppSecretValueText was a change to the original microsoft script ##########################

$ApiSecret = Get-AzKeyVaultSecret -VaultName $keyVault -Name $CertNameApi

$APipassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 50 | % {[char]$_})

$ApiSecretValueText = '';
$ApiSsPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiSecret.SecretValue)
try {
$ApiSecretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ApiSsPtr)
} finally {
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ApiSsPtr)
}

$ApiCertBytes = [System.Convert]::FromBase64String($ApiSecretValueText)

$ApiCertCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection

$ApiCertCollection.Import($ApiCertBytes,$null,[System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)

$ApiProtectedCertificateBytes = $ApiCertCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $APipassword)

$ApiPfxPath = "C:\AzurePAS"
$ApiPfxLocation = "$APiPfxPath\$ApiPfxname.pfx"

[System.IO.File]::WriteAllBytes($ApiPfxLocation, $ApiProtectedCertificateBytes)

############################### End of the Heinz 57 section #####################################################################################


New-AzWebAppSSLBinding -WebAppName $webapiname -ResourceGroupName $SolutionNameRg -Name $fqdnapi -CertificateFilePath $ApiPfxLocation -CertificatePassword $APiPassword -SslState SniEnabled

}
else 
{

Write-Host "SSL Binding  $WebApiBindingCheck already exists"

}