[CmdletBinding()]
param (
              
        $AzEnvPrefix,
        $AzPsNonProdSubscription,
        $AzSolutionAbbrv,
        $AzPsSolutionName,
        $AzPsCertName
       )

#Connect-AzAccount
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
Write-Host "Loading variables"
#################################################  Suffix for APP or API #############################################################
$AppSuffix = "app"
$ApiSuffix = "api"
############################ Pipeline Naming convention to for faster pipeline to local script conversion ############################
$AppGatewayName = "n01devukag001"
######################################################################################################################################
$appGw = Get-AzApplicationGateway -Name $AppGatewayName
######################################################################################################################################
$solutionName = $AzPsSolutionName
Write-Host "Configure Certificate"
#################################################### APP GATEWAY CERTIFICATE BLOCK ###################################################

############ Pipeline Variables #########
$AzCLIKeyVaultName = $AzEnvPrefix+"-"+$AzSolutionAbbrv+"-kv"
$AzPsSolAppGwCertAppName = $AzEnvPrefix+"-"+$AzSolutionAbbrv+"-crt"
########################################
########### Script Variables ###########
$keyvault = $AzCLIKeyVaultName
$CertificateName = $AzPsCertName
$SolAppGwCertAppName = $AzPsSolAppGwCertAppName
$SolApiGwCertAppName = $SolAppGwCertAppName
##############################
if(!($AppGwCertCheck = Get-AzApplicationGatewaySslCertificate -Name $SolAppGwCertAppName -ApplicationGateway $appGw -ErrorAction SilentlyContinue)){
        $certificate = Get-AzKeyVaultCertificate -VaultName $Keyvault -Name $CertificateName
        $secretId = $certificate.SecretId.Replace($certificate.Version, "")
        
        $appGw = Add-AzApplicationGatewaySslCertificate -Name $SolAppGwCertAppName -KeyVaultSecretId $secretId -ApplicationGateway $appGw
}
else {
       
        Write-Host "$AppGwCertCheck $SolAppGwCertAppName already exists updating Certificate"
        $Updatecertificate = Get-AzKeyVaultCertificate -VaultName $Keyvault -Name $CertificateName
        $UpdatesecretId = $Updatecertificate.SecretId.Replace($updatecertificate.Version, "")
        
        $appGw = Set-AzApplicationGatewaySslCertificate -Name $SolAppGwCertAppName -KeyVaultSecretId $updatesecretId -ApplicationGateway $appGw
        
}



################################################# END OF APP GATEWAY CERTIFICATE BLOCK #################################################

Write-Host "Configure Health Probe"
########################################################### HEALTH PROBE BLOCK ###########################################################
$AzPsAppHealthProbeText = "healthprobe-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$AppSuffix
$AzPsApiHealthProbeText = "healthprobe-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$ApiSuffix
$AppHealthProbeText = $AzPsAppHealthProbeText
$ApiHealthProbeText = $AzPsApiHealthProbeText
$match = New-AzApplicationGatewayProbeHealthResponseMatch -StatusCode 200-399
###########################################
if(!($AppHealthProbeCheck = Get-AzApplicationGatewayProbeConfig -Name $AppHealthProbeText -ApplicationGateway $appGw -ErrorAction SilentlyContinue)){
        $appGw = Add-AzApplicationGatewayProbeConfig -Name $AppHealthProbeText -ApplicationGateway $appGw -Protocol Https -Path / -Interval 30 -Timeout 30 -UnhealthyThreshold 3 -PickHostNameFromBackendHttpSettings -Match $match
}
else{
        Write-Host "$AppHealthProbeCheck $AppHealthProbeText already exists"
}

if(!($ApiHealthProbeCheck = Get-AzApplicationGatewayProbeConfig -Name $ApiHealthProbeText -ApplicationGateway $appGw -ErrorAction SilentlyContinue)){
        $appGw = Add-AzApplicationGatewayProbeConfig -Name $ApiHealthProbeText -ApplicationGateway $appGw -Protocol Https -Path / -Interval 30 -Timeout 30 -UnhealthyThreshold 3 -PickHostNameFromBackendHttpSettings -Match $match
}
else{
        Write-Host "$ApiHealthProbeCheck $ApiHealthProbeText already exists"
}

##################################################### END OF HEALTH PROBE BLOCK ##########################################################

Write-Host "Configure HTTP Settings"
############################################################ HTTP SETTINGS BLOCK ########################################################
$AppHttpsSettingsName = "https-settings-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$AppSuffix
$ApiHttpsSettingsName = "https-settings-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$ApiSuffix
$AppGwProbe = Get-AzApplicationGatewayProbeConfig -Name $AppHealthProbeText -ApplicationGateway $AppGw
$ApiGwProbe = Get-AzApplicationGatewayProbeConfig -Name $ApiHealthProbeText -ApplicationGateway $AppGw
#############################################
if(!($Apphttpsettingscheck = Get-AzApplicationGatewayBackendHttpSetting -Name $AppHttpsSettingsName -ApplicationGateWay $AppGw -ErrorAction SilentlyContinue)){
    $appGw = Add-AzApplicationGatewayBackendHttpSetting -Name $AppHttpsSettingsName -ApplicationGateWay $AppGw -Port 443 -Protocol Https -CookieBasedAffinity Disabled -Probe $AppGwProbe -PickHostNameFromBackendAddress
}
else{
    Write-Host "$Apphttpsettingscheck $AppHttpsSettingsName already exists"
}

if(!($Apihttpsettingscheck = Get-AzApplicationGatewayBackendHttpSetting -Name $ApiHttpsSettingsName -ApplicationGateWay $AppGw -ErrorAction SilentlyContinue)){
    $appGw = Add-AzApplicationGatewayBackendHttpSetting -Name $ApiHttpsSettingsName -ApplicationGateWay $AppGw -Port 443 -Protocol Https -CookieBasedAffinity Disabled -Probe $ApiGwProbe -PickHostNameFromBackendAddress
}
else{
    Write-Host "$Apihttpsettingscheck $ApiHttpsSettingsName already exists"
}


######################################################## END OF HTTP SETTINGS BLOCK #####################################################

Write-Host "Configure HTTP Listener"
########################################################### HTTP LISTENER BLOCK #########################################################
$prefix = $AzEnvPrefix
$envsuffix = $prefix.Remove(0,3)
$envmnt = $envsuffix.Remove(3)
$AppListenerName = "listener-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$AppSuffix
$ApiListenerName = "listener-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$ApiSuffix
$ApplistenerFQDN = $SolutionName+$AppSuffix+$envmnt+".demotech.com"
$ApilistenerFQDN = $SolutionName+$ApiSuffix+$envmnt+".demotech.com"
$AprsslAppCertName = Get-AzApplicationGatewaySslCertificate -Name $SolAppGwCertAppName -ApplicationGateway $appGw
$AprsslApiCertName = Get-AzApplicationGatewaySslCertificate -Name $SolApiGwCertAppName -ApplicationGateway $appGw
$appGwFrontEndIPConfig = Get-AzApplicationGatewayFrontendIPConfig -ApplicationGateway $appGw -Name "appGatewayFrontendIP"
$appGwFrontEndPort = Get-AzApplicationGatewayFrontendPort -ApplicationGateway $appGw -Name "port_443"
###############################################
if(!($AppListenerNameCheck = Get-AzApplicationGatewayHttpListener -ApplicationGateway $appGw -Name $AppListenerName -ErrorAction SilentlyContinue)){

     $appGw = Add-AzApplicationGatewayHttpListener -ApplicationGateway $appGw -Name $AppListenerName -Protocol Https -FrontendIPConfiguration $appGwFrontEndIPConfig -FrontendPort $appGwFrontEndPort -HostName $ApplistenerFQDN -RequireServerNameIndication true -SslCertificate $AprsslAppCertName
}
else{
    Write-Host "$AppListenerNameCheck $AppListenerName already exists"
}

if(!($ApiListenerNameCheck = Get-AzApplicationGatewayHttpListener -ApplicationGateway $appGw -Name $ApiListenerName -ErrorAction SilentlyContinue)){

     $appGw = Add-AzApplicationGatewayHttpListener -ApplicationGateway $appGw -Name $ApiListenerName -Protocol Https -FrontendIPConfiguration $appGwFrontEndIPConfig -FrontendPort $appGwFrontEndPort -HostName $ApilistenerFQDN -RequireServerNameIndication true -SslCertificate $AprsslApiCertName

}
else{
    Write-Host "$ApiListenerNameCheck $ApiListenerName already exists"
}


########################################################## END OF HTTP LISTENER BLOCK ####################################################
Write-Host "Configure Backend Pool"
####################################################### BACKEND POOL BLOCK ################################################################
$AppBackEndPoolName = "bepool-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$AppSuffix
$ApiBackEndPoolName = "bepool-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$ApiSuffix
$webappFQDN = $AzEnvPrefix+"-"+$SolutionName+"-"+$AppSuffix+".azurewebsites.net"
$webapiFQDN = $AzEnvPrefix+"-"+$SolutionName+"-"+$ApiSuffix+".azurewebsites.net"
###############################################
if(!($AppBackEndPoolNameCheck = Get-AzApplicationGatewayBackendAddressPool -ApplicationGateway $appGw -Name $AppBackEndPoolName -ErrorAction SilentlyContinue)){

        $appGw = Add-AzApplicationGatewayBackendAddressPool -ApplicationGateway $AppGw -Name $AppBackEndPoolName -BackendFqdns $webappFQDN
}
else{
    Write-Host "$AppBackEndPoolNameCheck $AppBackEndPoolName already exists"
}

if(!($ApiBackEndPoolNameCheck = Get-AzApplicationGatewayBackendAddressPool -ApplicationGateway $appGw -Name $ApiBackEndPoolName -ErrorAction SilentlyContinue)){

        $appGw = Add-AzApplicationGatewayBackendAddressPool -ApplicationGateway $AppGw -Name $ApiBackEndPoolName -BackendFqdns $webapiFQDN
}
else{
    Write-Host "$ApiBackEndPoolNameCheck $ApiBackEndPoolName already exists"
}
####################################################### END OF BACKEND POOL BLOCK #########################################################
Write-Host "Configure Routing Rule"
######################################################## ROUTING RULE BLOCK ###############################################################
$AppRuleName = "rule-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$AppSuffix
$ApiRuleName = "rule-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$ApiSuffix
$AppGwHttpSettings = Get-AzApplicationGatewayBackendHttpSetting -Name $AppHttpsSettingsName -ApplicationGateway $AppGw
$ApiGwHttpSettings = Get-AzApplicationGatewayBackendHttpSetting -Name $ApiHttpsSettingsName -ApplicationGateway $AppGw
$AppGwListener = Get-AzApplicationGatewayHttpListener -ApplicationGateway $AppGw -Name $AppListenerName
$ApiGwListener = Get-AzApplicationGatewayHttpListener -ApplicationGateway $AppGw -Name $ApiListenerName
$AppGwBackEndPool = Get-AzApplicationGatewayBackendAddressPool -Name $AppBackEndPoolName -ApplicationGateway $AppGw
$ApiGwBackEndPool = Get-AzApplicationGatewayBackendAddressPool -Name $ApiBackEndPoolName -ApplicationGateway $AppGw

##################################################
if(!($AppRuleNameCheck = Get-AzApplicationGatewayRequestRoutingRule -ApplicationGateway $appGw -Name $AppRuleName -ErrorAction SilentlyContinue)){

        $appGw = Add-AzApplicationGatewayRequestRoutingRule -ApplicationGateway $AppGw -Name $AppRuleName -RuleType Basic -BackendHttpSettings $AppGwHttpSettings -HttpListener $AppGwListener -BackendAddressPool $AppGwBackEndPool
}
else{
    Write-Host "$AppRuleNameCheck $AppRuleName already exists"
}

if(!($ApiRuleNameCheck = Get-AzApplicationGatewayRequestRoutingRule -ApplicationGateway $appGw -Name $ApiRuleName -ErrorAction SilentlyContinue)){

        $appGw = Add-AzApplicationGatewayRequestRoutingRule -ApplicationGateway $AppGw -Name $ApiRuleName -RuleType Basic -BackendHttpSettings $ApiGwHttpSettings -HttpListener $ApiGwListener -BackendAddressPool $ApiGwBackEndPool
        
        Write-Host "Updating Application Gateway with additonal configuration.........."
        
}
else{
    Write-Host "$ApiRuleNameCheck $ApiRuleName already exists"
}
######################################################### COMMIT CHANGES TO APP GATEWAY ####################################################
        
Set-AzApplicationGateway -ApplicationGateway $AppGw
############################################################################################################################################

######################################################## END OF ROUTING RULE BLOCK and APP GATEWAY CONFIGURATION #########################################################

Write-Host "Updating Azure DNS with A Records for Application"
########################################### Update WebApp and WebApi DNS to Application Gateway Block ############################################
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
Write-Host "Checking for DNS CNAME Records"
if($RecordSetApp = Get-AzDnsRecordSet -ResourceGroupName "n01tstuw-shared-rg" -ZoneName demotech.com -Name "$customdomainapp" -RecordType "CNAME" -ErrorAction SilentlyContinue){
        Remove-AzDnsRecordSet -RecordSet $RecordSetApp -Confirm:$False -Overwrite
        Write-Host "Removing CNAME record $customdomainapp from a previous deployment"
}
Else {
        Write-Host "$customdomainapp does not exist"
}
if($RecordSetApi = Get-AzDnsRecordSet -ResourceGroupName "n01tstuw-shared-rg" -ZoneName demotech.com -Name "$customdomainapi" -RecordType "CNAME" -ErrorAction SilentlyContinue){
        Remove-AzDnsRecordSet -RecordSet $RecordSetApi -Confirm:$False -Overwrite
        Write-Host "Removing CNAME record $customdomainapi from a previous deployment"
}
Else {
        Write-Host "$customdomainapi does not exist"
}
if(!($ARecordSetApp = Get-AzDnsRecordSet -ResourceGroupName "n01tstuw-shared-rg" -ZoneName demotech.com -Name "$customdomainapp" -RecordType "A" -ErrorAction SilentlyContinue)){
        New-AzDnsRecordSet -Name $customdomainapp -RecordType A -ResourceGroupName "n01tstuw-shared-rg" -TTL 60 -ZoneName demotech.com -DnsRecords (New-AzDnsRecordConfig -IPv4Address 51.104.251.132)
        Write-Host "Creating A record $customdomainapp"
}
Else {
        Write-Host "A record for $ARecordSetApp already exists"
}
if(!($ARecordSetApi = Get-AzDnsRecordSet -ResourceGroupName "n01tstuw-shared-rg" -ZoneName ldemotech.com -Name "$customdomainapi" -RecordType "A" -ErrorAction SilentlyContinue)){
        New-AzDnsRecordSet -Name $customdomainapi -RecordType A -ResourceGroupName "n01tstuw-shared-rg" -TTL 60 -ZoneName demotech.com -DnsRecords (New-AzDnsRecordConfig -IPv4Address 51.104.251.132)
        Write-Host "Creating A record $customdomainapi"
}
Else {
        Write-Host "A record for $ARecordSetApi already exists"
}

##################################################### End of Application Gateway DNS Update Block ######################################

Write-Host "Configuration of Application Gateway and Azure DNS Complete"
