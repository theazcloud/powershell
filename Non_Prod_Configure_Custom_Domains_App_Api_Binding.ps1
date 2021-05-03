Non_Prod_Configure_Custom_Domains_App_Api_Binding

01 May 2021
12:06

[CmdletBinding()]

param (
        $solutionName,
        $AzCLIResourceGroupName,
        $AzEnvPrefix

       )

 ############# The solution name is the main abbreviation ################

$SolutionName = $solutionName

##########################################################################

######### Resource Group containing the certificate #####################

$SolutionNameRg =  $AzCLIResourceGroupName

#########################################################################

$solution = $solutionName
$prefix = $AzEnvPrefix
$envsuffix = $prefix.Remove(0,3)
$envmnt = $envsuffix.Remove(3)
$customdomain = $solution.ToLower()+$envmnt
$webappname = "$prefix-$solution-app"
$customdomainapp = "$customdomain-app"
$webapiname = "$prefix-$solution-api"
$customdomainapi = "$customdomain-api"
$fqdnapp = "$customdomainapp.demotech.com"
$fqdnapi = "$customdomainapi.demotech.com"

###################### Connect to Azure #################################

#################### Variables to Keep ##################################

#Connect-AzAccount

#########################################################################


$wildCard = Get-AzWebAppCertificate -ResourceGroupName "n01tstuw-shared-rg"


$wildCardThumb = $wildCard.Thumbprint


if(!($WebAppBindingCheck = Get-AzWebAppSSLBinding -WebAppName $webappname -ResourceGroupName $SolutionNameRg -ErrorAction SilentlyContinue))

{

Write-Output "Importing Certificate into App WebApp"

New-AzWebAppSSLBinding -WebAppName $webappname -ResourceGroupName $SolutionNameRg -Name $fqdnapp -Thumbprint $wildCardThumb -SslState SniEnabled

}
else 
{

Write-Host "SSL Binding  $WebAppBindingCheck already exists"
    
}


if(!($WebApiBindingCheck = Get-AzWebAppSSLBinding -WebAppName $webapiname -ResourceGroupName $SolutionNameRg -ErrorAction SilentlyContinue))

{

Write-Output "Importing Certificate into Api WebApp"

New-AzWebAppSSLBinding -WebAppName $webapiname -ResourceGroupName $SolutionNameRg -Name $fqdnapi -Thumbprint $wildCardThumb -SslState SniEnabled

}
else 
{

Write-Host "SSL Binding  $WebApiBindingCheck already exists"
    
}





New-AzWebAppSSLBinding -WebAppName $webapiname -ResourceGroupName $SolutionNameRg -Name $fqdnapi -Thumbprint $wildCardThumb -SslState SniEnabled
