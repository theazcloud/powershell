Prod_Configure_Custom_Domains_App_Api

09 April 2021
14:51

[CmdletBinding()]

param (
      
        $solutionName,
        $AzEnvPrefix,
        $AzPsProdSubscription

       )



###############################################

$solution = $solutionName
$prefix = $AzEnvPrefix
$customdomain = "$solutiondev"
$ProdSubscription = $AzPsProdSubscription
$Prodcontext = $ProdSubscription

###############################################

# Set context to NonProd as all resources are in the Non Prod subscription

Set-AzContext -SubscriptionId $Prodcontext

# Load variables to build up CNAMES in example.com dns zone and Custom domain

$dnscname = "$prefix-$solution"
$webappname = "$prefix-$solution-app"
$webapiname = "$prefix-$solution-api"

# Load variable of complete resource group

$webapprg = get-azresourcegroup -Name "$prefix-$solution-rg"

# Load variables for custom domain names

$customdomainapp = "$customdomain-app"
$customdomainapi = "$customdomain-api"

# create CNAME entries in example.com domain

New-AzDnsRecordSet -ZoneName example.com -ResourceGroupName "example-rg" `
 -Name "$customdomain-app" -RecordType "CNAME" -Ttl 60 `
 -DnsRecords (New-AzDnsRecordConfig -cname "$dnscname-app.azurewebsites.net")

New-AzDnsRecordSet -ZoneName example.com -ResourceGroupName "example-rg" `
 -Name "$customdomain-api" -RecordType "CNAME" -Ttl 60 `
 -DnsRecords (New-AzDnsRecordConfig -cname "$dnscname-api.azurewebsites.net")

# Check Web Apps exist

get-AzWebapp -Name $webappname -ResourceGroupName $webapprg.ResourceGroupName

get-AzWebapp -Name $webapiname -ResourceGroupName $webapprg.ResourceGroupName

# update custom domain on webapps
 
set-AzWebApp -Name $webappname -ResourceGroupName $webapprg.ResourceGroupName -HostNames @("$dnscname-app.azurewebsites.net","$customdomainapp.example.com")

set-AzWebApp -Name $webapiname -ResourceGroupName $webapprg.ResourceGroupName -HostNames @("$dnscname-api.azurewebsites.net","$customdomainapi.example.com")
