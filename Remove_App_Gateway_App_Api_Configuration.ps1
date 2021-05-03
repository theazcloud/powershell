Remove_App_Gateway_App_Api_Configuration

01 May 2021
12:16

############ Solution name is also the middle part of the resource group name and is consistent through all the scripts ##############
$solutionName = "aprildemo"                                                                                                         
#                                                                                                                                    #
##################################### The abbrviation used in the ARM template deploying the keyvault ################################ 
$AzSolutionAbbrv = "aprild"
#                                                                                                                                    #
############################## All manual variables updated the script can now be run ################################################
Connect-AzAccount
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
######################################## The three letter environment prefix DEV #####################################################
$env = "dev"                                                                                                                  
#                                                                                                                                    #
######################## The three character subscription prefix n01 for DEV and TST then p01 for UAT and PRD ########################
$prefix = "n01"
#                                                                                                                                    #
######################################################################################################################################
############# Setting the Complete Environment Prefix for all the variables using pipeline naming convention #########################
$AzEnvPrefix = $prefix+$env+"uk"
#################################################  Suffix for APP or API #############################################################
$AppSuffix = "app"
$ApiSuffix = "api"
############################ Pipeline Naming convention to for faster pipeline to local script conversion ############################

$AppGatewayName = "demoag001"
$AzPsSolAppGwCertAppName = $AzEnvPrefix+"-"+$AzSolutionAbbrv+"-crt"
$AzPsAppHealthProbeText = "healthprobe-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$AppSuffix
$AzPsApiHealthProbeText = "healthprobe-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$ApiSuffix
$AzCLIKeyVaultName = $AzEnvPrefix+"-"+$AzSolutionAbbrv+"-kv"
$AzPsCertName = "demotech-wildcard-cert"
$AzPsAppHttpsSettingsName = "https-settings-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$AppSuffix
$AzPsApiHttpsSettingsName = "https-settings-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$ApiSuffix
$AzPsAppListenerName = "listener-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$AppSuffix
$AzPsApiListenerName = "listener-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$ApiSuffix
$AzPsAppBackEndPoolName = "bepool-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$AppSuffix
$AzPsApiBackEndPoolName = "bepool-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$ApiSuffix
$AzPswebappFQDN = $AzEnvPrefix+"-"+$SolutionName+"-"+$AppSuffix+".azurewebsites.net"
$AzPswebapiFQDN = $AzEnvPrefix+"-"+$SolutionName+"-"+$ApiSuffix+".azurewebsites.net"
$AzPsAppRuleName = "rule-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$AppSuffix
$AzPsApiRuleName = "rule-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$ApiSuffix

######################################################################################################################################
$appGw = Get-AzApplicationGateway -Name $AppGatewayName
$Keyvault = $AzCLIKeyVaultName
$CertificateName = $AzPsCertName
$SolAppGwCertAppName = $AzPsSolAppGwCertAppName
$SolApiGwCertAppName = $SolAppGwCertAppName
$AppHealthProbeText = $AzPsAppHealthProbeText
$ApiHealthProbeText = $AzPsApiHealthProbeText
$AppHttpsSettingsName = $AzPsAppHttpsSettingsName
$ApiHttpsSettingsName = $AzPsApiHttpsSettingsName
$AppListenerName = $AzPsAppListenerName
$ApiListenerName = $AzPsApiListenerName
$ApplistenerFQDN = $SolutionName+$AppSuffix+$env+".demotech.com"
$ApilistenerFQDN = $SolutionName+$ApiSuffix+$env+".demotech.com"
$AppBackEndPoolName = $AzPsAppBackEndPoolName
$ApiBackEndPoolName = $AzPsApiBackEndPoolName
$webappFQDN = $AzPswebappFQDN
$webapiFQDN = $AzPswebapiFQDN
$AppRuleName = $AzPsAppRuleName
$ApiRuleName = $AzPsApiRuleName



######################################################################################################################################
################# Remove comments from this section to backout changes if script is only partially successful ########################
################# then run script again which will then remove all the entries sucessfully created ###################################
if($SolGwCert = Get-AzApplicationGatewaySslCertificate -ApplicationGateway $appGw -Name $SolAppGwCertAppName -ErrorAction SilentlyContinue){
        $appGw = Remove-AzApplicationGatewaySslCertificate -ApplicationGateway $appGw -Name $SolAppGwCertAppName
}
else {
    Write-Host "$SolAppGwCertAppName already deleted"
}


if($AppHealth = Get-AzApplicationGatewayProbeConfig -Name $AppHealthProbeText -ApplicationGateway $AppGw -ErrorAction SilentlyContinue){
        $appGw = Remove-AzApplicationGatewayProbeConfig -Name $AppHealthProbeText -ApplicationGateway $AppGw
}
else {
    Write-Host "$AppHealthProbeText already deleted"
}

if($ApiHealth = Get-AzApplicationGatewayProbeConfig -Name $ApiHealthProbeText -ApplicationGateway $AppGw -ErrorAction SilentlyContinue){
        $appGw = Remove-AzApplicationGatewayProbeConfig -Name $ApiHealthProbeText -ApplicationGateway $AppGw

}
else {
    Write-Host "$ApiHealthProbeText already deleted"
}

if($AppSettings = Get-AzApplicationGatewayBackendHttpSetting -Name $AppHttpsSettingsName -ApplicationGateway $AppGw -ErrorAction SilentlyContinue){
        $appGw = Remove-AzApplicationGatewayBackendHttpSetting -Name $AppHttpsSettingsName -ApplicationGateway $AppGw

}
else {
    Write-Host "$AppHttpsSettingsName already deleted"
}
if($ApiSettings = Get-AzApplicationGatewayBackendHttpSetting -Name $ApiHttpsSettingsName -ApplicationGateway $AppGw -ErrorAction SilentlyContinue){
        $appGw = Remove-AzApplicationGatewayBackendHttpSetting -Name $ApiHttpsSettingsName -ApplicationGateway $AppGw

}
else {
    Write-Host "$ApiHttpsSettingsName already deleted"
}


if($AppBePool = Get-AzApplicationGatewayBackendAddressPool -Name $AppBackEndPoolName -ApplicationGateway $AppGw -ErrorAction SilentlyContinue){
        $appGw = Remove-AzApplicationGatewayBackendAddressPool -Name $AppBackEndPoolName -ApplicationGateway $AppGw

 }
 else {
    Write-Host "$AppBackEndPoolName already deleted"
}
if($ApiBePool = Get-AzApplicationGatewayBackendAddressPool -Name $ApiBackEndPoolName -ApplicationGateway $AppGw -ErrorAction SilentlyContinue){
        $appGw = Remove-AzApplicationGatewayBackendAddressPool -Name $ApiBackEndPoolName -ApplicationGateway $AppGw

 }
 else {
    Write-Host "$ApiBackEndPoolName already deleted"
}

if($AppRule = Get-AzApplicationGatewayRequestRoutingRule -Name $AppRuleName -ApplicationGateway $AppGw -ErrorAction SilentlyContinue){
        $appGw = Remove-AzApplicationGatewayRequestRoutingRule -Name $AppRuleName -ApplicationGateway $AppGw
}
else {
    Write-Host "$AppRuleName already deleted"
}
if($ApiRule = Get-AzApplicationGatewayRequestRoutingRule -Name $ApiRuleName -ApplicationGateway $AppGw -ErrorAction SilentlyContinue){
        $AppGw = Remove-AzApplicationGatewayRequestRoutingRule -Name $ApiRuleName -ApplicationGateway $AppGw
}
else {
    Write-Host "$ApiRuleName already deleted"
}

if($AppList = Get-AzApplicationGatewayHttpListener -ApplicationGateway $AppGw -Name $AppListenerName -ErrorAction SilentlyContinue){
        $appGw = Remove-AzApplicationGatewayHttpListener -Name $AppListenerName -ApplicationGateway $AppGw

}
else {
    Write-Host "$AppListenerName already deleted"
}

if($ApiList = Get-AzApplicationGatewayHttpListener -ApplicationGateway $AppGw -Name $ApiListenerName -ErrorAction SilentlyContinue){
        $AppGw = Remove-AzApplicationGatewayHttpListener -Name $ApiListenerName -ApplicationGateway $AppGw

}
else {
    Write-Host "$ApiListenerName already deleted"
}
 Set-AzApplicationGateway -ApplicationGateway $AppGw

########################################### Update WebApp and WebApi DNS to Application Gateway Block ############################################
$AzPsNonProdSubscription = Get-AzKeyVaultSecret -VaultName 'n01devukpatternskv' -Name 'AzPsNonProdSubscription' -AsPlainText
$AzPsProdSubscription = Get-AzKeyVaultSecret -VaultName 'n01devukpatternskv' -Name 'AzPsProdSubscription' -AsPlainText
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
# Load variables to build up CNAMES in demotech.com dns zone and Custom domain


# Load variables for custom domain names
$customdomainapp = "$customdomain-app"
$customdomainapi = "$customdomain-api"


# create CNAME entries in demotech.com domain
Write-Host "Checking for DNS A Records"
if($ARecordSetApp = Get-AzDnsRecordSet -ResourceGroupName "n01tstuw-shared-rg" -ZoneName demotech.com -Name "$customdomainapp" -RecordType "A" -ErrorAction SilentlyContinue){
        Remove-AzDnsRecordSet -RecordSet $ARecordSetApp -Confirm:$False -Overwrite
        Write-Host "Removing A record $customdomainapp from a previous deployment"
}
Else {
        Write-Host "No A record for $customdomainapp exists"
}
if($ARecordSetApi = Get-AzDnsRecordSet -ResourceGroupName "n01tstuw-shared-rg" -ZoneName demotech.com -Name "$customdomainapi" -RecordType "A" -ErrorAction SilentlyContinue){
        Remove-AzDnsRecordSet -RecordSet $ARecordSetApi -Confirm:$False -Overwrite
        Write-Host "Removing A record $customdomainapi from a previous deployment"
}
Else {
        Write-Host "No A record for $customdomainapi exists"
}

Write-Host "Checking for DNS CNAME Records"
if(!($RecordSetApp = Get-AzDnsRecordSet -ResourceGroupName "n01tstuw-shared-rg" -ZoneName demotech.com -Name "$customdomainapp" -RecordType "CNAME" -ErrorAction SilentlyContinue)){
        New-AzDnsRecordSet -ZoneName demotech.com -ResourceGroupName "n01tstuw-shared-rg" `
        -Name "$customdomainapp" -RecordType "CNAME" -Ttl 60 `
        -DnsRecords (New-AzDnsRecordConfig -cname "$dnscname-app.azurewebsites.net")
}
Else {
        $RecordSetAppName = $RecordSetApp.Name
        
        Write-Host "CNAME $RecordSetAppName already exists"
}
if(!($RecordSetApi = Get-AzDnsRecordSet -ResourceGroupName "n01tstuw-shared-rg" -ZoneName demotech.com -Name "$customdomainapi" -RecordType "CNAME" -ErrorAction SilentlyContinue)){
        New-AzDnsRecordSet -ZoneName demotech.com -ResourceGroupName "n01tstuw-shared-rg" `
        -Name "$customdomainapi" -RecordType "CNAME" -Ttl 60 `
        -DnsRecords (New-AzDnsRecordConfig -cname "$dnscname-api.azurewebsites.net")
}
Else {
        $RecordSetApiName = $RecordSetApi.Name
        
        Write-Host "CNAME $RecordSetApiName already exists"
}

##################################################### End of Application Gateway DNS Update Block ######################################
Write-Host "All configuration removed"
