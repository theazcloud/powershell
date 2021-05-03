[CmdletBinding()]
param (
      
        $solutionName,
        $AzEnvPrefix,
        $AzPsNonProdSubscription
       )


###############################################
$solution = $solutionName
$prefix = $AzEnvPrefix
$envsuffix = $prefix.Remove(0,3)
$envmnt = $envsuffix.Remove(3)
$customdomain = $solution.ToLower()+$envmnt
$NonProdSubscription = $AzPsNonProdSubscription
$NonProdcontext = $NonProdSubscription
###############################################
# Set context to NonProd as all resources are in the Non Prod subscription
Set-AzContext -SubscriptionId $NonProdcontext
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


if(!($RecordSetApp = Get-AzDnsRecordSet -ResourceGroupName "example-rg" -ZoneName example.com -Name "$customdomainapp" -RecordType "CNAME" -ErrorAction SilentlyContinue)){
        New-AzDnsRecordSet -ZoneName example.com -ResourceGroupName "example-rg" `
        -Name "$customdomainapp" -RecordType "CNAME" -Ttl 60 `
        -DnsRecords (New-AzDnsRecordConfig -cname "$dnscname-app.azurewebsites.net")
}
Else {
        Write-Host "$RecordSetApp already exists"
}
if(!($RecordSetApi = Get-AzDnsRecordSet -ResourceGroupName "example-rg" -ZoneName example.com -Name "$customdomainapi" -RecordType "CNAME" -ErrorAction SilentlyContinue)){
        New-AzDnsRecordSet -ZoneName example.com -ResourceGroupName "example-rg" `
        -Name "$customdomainapi" -RecordType "CNAME" -Ttl 60 `
        -DnsRecords (New-AzDnsRecordConfig -cname "$dnscname-api.azurewebsites.net")
}
Else {
        Write-Host "$RecordSetApi already exists"
}
# Check Web Apps exist
get-AzWebapp -Name $webappname -ResourceGroupName $webapprg.ResourceGroupName
get-AzWebapp -Name $webapiname -ResourceGroupName $webapprg.ResourceGroupName
# update custom domain on webapps
 
set-AzWebApp -Name $webappname -ResourceGroupName $webapprg.ResourceGroupName -HostNames @("$dnscname-app.azurewebsites.net","$customdomainapp.example.com")
set-AzWebApp -Name $webapiname -ResourceGroupName $webapprg.ResourceGroupName -HostNames @("$dnscname-api.azurewebsites.net","$customdomainapi.example.com")
