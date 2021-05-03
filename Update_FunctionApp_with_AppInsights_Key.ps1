[CmdletBinding()]
param (
        $AzCLIResourceGroupName,
        $AzCLIFunctionAppName,
        $AzCLIKeyVaultName,
        $AzEnvPrefix,
        $AzSolutionName
       )
$resourcegroupname = $AzCLIResourceGroupName
$functionappname = $AzCLIFunctionAppName
$solutionName = $AzSolutionName
$envprefix = $AzEnvPrefix
$AppInsightsName = $envprefix+"-"+$solutionName.ToLower()+"-appinsights"
$AppInsightsResource = Get-AzApplicationInsights -ResourceGroupName $resourcegroupname -Name $AppInsightsName
$AppInsightsInsKey = $AppInsightsResource.InstrumentationKey
Update-AzFunctionApp -Name $functionappname -ResourceGroupName $resourcegroupname -ApplicationInsightsKey $AppInsightsInsKey
