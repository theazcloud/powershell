[CmdletBinding()]
param (
              
        $AzEnvPrefix,
        $AzPsProdSubscription,
        $AzSolutionAbbrv,
        $AzPsSolutionName,
        $AzPsCertName,
        $AzPsUATCertSharedKeyVault,
        $AzPsUATSharedCertSecretName
       )

#Connect-AzAccount
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
Write-Host "Loading variables"
#################################################  Suffix for APP or API #############################################################
$AppSuffix = "app"
$ApiSuffix = "api"
############################ Pipeline Naming convention to for faster pipeline to local script conversion ############################

$AppGatewayName = "p01prdukag001"
######################################################################################################################################
$appGw = Get-AzApplicationGateway -Name $AppGatewayName
######################################################################################################################################
#################################################### APP GATEWAY CERTIFICATE BLOCK ###################################################

############ Pipeline Variables #########
$AzPsSolAppGwCertAppName = $AzEnvPrefix+"-"+$AzSolutionAbbrv+"-crt"
########################################
########### Script Variables ###########
$keyvaultsecret = $AzPsUATCertSharedKeyVault
$SecretName = $AzPsUATSharedCertSecretName
$SolAppGwCertAppName = $AzPsSolAppGwCertAppName
$SolApiGwCertAppName = $SolAppGwCertAppName
##############################
if(!($AppGwCertCheck = Get-AzApplicationGatewaySslCertificate -Name $SolAppGwCertAppName -ApplicationGateway $appGw -ErrorAction SilentlyContinue)){
        $secretId = Get-AzKeyvaultSecret -VaultName $keyvaultsecret -Name $SecretName
        
        $appGw = Add-AzApplicationGatewaySslCertificate -Name $SolAppGwCertAppName -KeyVaultSecretId $secretId -ApplicationGateway $appGw

}
else {
        Write-Host "$AppGwCertCheck $SolAppGwCertAppName already exists"
        
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
$appGw = Add-AzApplicationGatewayProbeConfig -Name $AppHealthProbeText -ApplicationGateway $appGw -Protocol Https -Path / -Interval 30 -Timeout 30 -UnhealthyThreshold 3 -PickHostNameFromBackendHttpSettings -Match $match
$appGw = Add-AzApplicationGatewayProbeConfig -Name $ApiHealthProbeText -ApplicationGateway $appGw -Protocol Https -Path / -Interval 30 -Timeout 30 -UnhealthyThreshold 3 -PickHostNameFromBackendHttpSettings -Match $match
##################################################### END OF HEALTH PROBE BLOCK ##########################################################
Write-Host "Configure HTTP Settings"
############################################################ HTTP SETTINGS BLOCK ########################################################
$AppHttpsSettingsName = "https-settings-"+$Prefix+"-"+$SolutionName+"-"+$AppSuffix
$ApiHttpsSettingsName = "https-settings-"+$Prefix+"-"+$SolutionName+"-"+$ApiSuffix
$AppGwProbe = Get-AzApplicationGatewayProbeConfig -Name $AppHealthProbeText -ApplicationGateway $AppGw
$ApiGwProbe = Get-AzApplicationGatewayProbeConfig -Name $ApiHealthProbeText -ApplicationGateway $AppGw
#############################################
$appGw = Add-AzApplicationGatewayBackendHttpSetting -Name $AppHttpsSettingsName -ApplicationGateWay $AppGw -Port 443 -Protocol Https -CookieBasedAffinity Disabled -Probe $AppGwProbe -PickHostNameFromBackendAddress
$appGw = Add-AzApplicationGatewayBackendHttpSetting -Name $ApiHttpsSettingsName -ApplicationGateWay $AppGw -Port 443 -Protocol Https -CookieBasedAffinity Disabled -Probe $ApiGwProbe -PickHostNameFromBackendAddress
######################################################## END OF HTTP SETTINGS BLOCK #####################################################
Write-Host "Configure HTTP Listener"
########################################################### HTTP LISTENER BLOCK #########################################################
$AppListenerName = "listener-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$AppSuffix
$ApiListenerName = "listener-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$ApiSuffix
$ApplistenerFQDN = $SolutionName+$AppSuffix+$env+".demotech.com"
$ApilistenerFQDN = $SolutionName+$ApiSuffix+$env+".demotech.com"
$AprsslAppCertName = Get-AzApplicationGatewaySslCertificate -Name $SolAppGwCertAppName -ApplicationGateway $appGw
$AprsslApiCertName = Get-AzApplicationGatewaySslCertificate -Name $SolApiGwCertAppName -ApplicationGateway $appGw
$appGwFrontEndIPConfig = Get-AzApplicationGatewayFrontendIPConfig -ApplicationGateway $appGw -Name "appGatewayFrontendIP"
$appGwFrontEndPort = Get-AzApplicationGatewayFrontendPort -ApplicationGateway $appGw -Name "port_443"
###############################################
$appGw = Add-AzApplicationGatewayHttpListener -ApplicationGateway $appGw -Name $AppListenerName -Protocol Https -FrontendIPConfiguration $appGwFrontEndIPConfig -FrontendPort $appGwFrontEndPort -HostName $ApplistenerFQDN -RequireServerNameIndication true -SslCertificate $AprsslAppCertName
$appGw = Add-AzApplicationGatewayHttpListener -ApplicationGateway $appGw -Name $ApiListenerName -Protocol Https -FrontendIPConfiguration $appGwFrontEndIPConfig -FrontendPort $appGwFrontEndPort -HostName $ApilistenerFQDN -RequireServerNameIndication true -SslCertificate $AprsslApiCertName
########################################################## END OF HTTP LISTENER BLOCK ####################################################
Write-Host "Configure Backend Pool"
####################################################### BACKEND POOL BLOCK ################################################################
$AppBackEndPoolName = "bepool-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$AppSuffix
$ApiBackEndPoolName = "bepool-"+$AzEnvPrefix+"-"+$SolutionName+"-"+$ApiSuffix
$webappFQDN = $AzEnvPrefix+"-"+$SolutionName+"-"+$AppSuffix+".azurewebsites.net"
$webapiFQDN = $AzEnvPrefix+"-"+$SolutionName+"-"+$ApiSuffix+".azurewebsites.net"
###############################################
$appGw = Add-AzApplicationGatewayBackendAddressPool -ApplicationGateway $AppGw -Name $AppBackEndPoolName -BackendFqdns $webappFQDN
$appGw = Add-AzApplicationGatewayBackendAddressPool -ApplicationGateway $AppGw -Name $ApiBackEndPoolName -BackendFqdns $webapiFQDN
####################################################### END OF BACKEND POOL BLOCK #########################################################
Write-Host "Configure Routing Rule"
######################################################## ROUTING RULE BLOCK ###############################################################
$AppRuleName = "rule-"+$Prefix+"-"+$SolutionName+"-"+$AppSuffix
$ApiRuleName = "rule-"+$Prefix+"-"+$SolutionName+"-"+$ApiSuffix
$AppGwHttpSettings = Get-AzApplicationGatewayBackendHttpSetting -Name $AppHttpsSettingsName -ApplicationGateway $AppGw
$ApiGwHttpSettings = Get-AzApplicationGatewayBackendHttpSetting -Name $ApiHttpsSettingsName -ApplicationGateway $AppGw
$AppGwListener = Get-AzApplicationGatewayHttpListener -ApplicationGateway $AppGw -Name $AppListenerName
$ApiGwListener = Get-AzApplicationGatewayHttpListener -ApplicationGateway $AppGw -Name $ApiListenerName
$AppGwBackEndPool = Get-AzApplicationGatewayBackendAddressPool -Name $AppBackEndPoolName -ApplicationGateway $AppGw
$ApiGwBackEndPool = Get-AzApplicationGatewayBackendAddressPool -Name $ApiBackEndPoolName -ApplicationGateway $AppGw

##################################################
$appGw = Add-AzApplicationGatewayRequestRoutingRule -ApplicationGateway $AppGw -Name $AppRuleName -RuleType Basic -BackendHttpSettings $AppGwHttpSettings -HttpListener $AppGwListener -BackendAddressPool $AppGwBackEndPool
$appGw = Add-AzApplicationGatewayRequestRoutingRule -ApplicationGateway $AppGw -Name $ApiRuleName -RuleType Basic -BackendHttpSettings $ApiGwHttpSettings -HttpListener $ApiGwListener -BackendAddressPool $ApiGwBackEndPool

######################################################## END OF ROUTING RULE BLOCK #########################################################
Write-Host "Updating Application Gateway with additonal configuration.........."
######################################################### COMMIT CHANGES TO APP GATEWAY ####################################################
Set-AzApplicationGateway -ApplicationGateway $AppGw
############################################################################################################################################
Write-Host "Configuration of Application Gateway and Azure DNS Complete"
