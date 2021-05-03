__CREATE-Project-Resource_Groups

09 April 2021
14:57

 # If the commands fail first check you have the Powershell Az Modules installed
 # Run Get-Module - if Az.* modules are not returned remove the # from the four lines below 
 # select them then right mouse click and run selection
 # $proxyString = ""
 # $proxyUri = new-object System.Uri($proxyString)
 # [System.Net.WebRequest]::DefaultWebProxy = new-object System.Net.WebProxy ($proxyUri, $true)
 # Install-Module Az -AllowClobber
 # Once installed check Get-Module again
 
 # "Save as" to rename and save a copy of the script into the relevant project folder 
 # MODIFY $applicationTag and $solution VARIABLES BELOW BEFORE RUNNING SCRIPT
 ###################### Application Tags ##########################
 
 $applicationTag = "#Application Tag for Resource Group#"
 ### Just the name of the application i.e. Turnover Automation ####
 $solution = "#SolutionName#"
 #############################################################
 
 $NonProdSubscription = ""
 $devprefix = ""
 $uwdevprefix = ""
 $tstprefix = ""
 $uwtstprefix = ""
 
 $ProdSubscription = ""
 $uatprefix = ""
 $uwuatprefix = ""
 $prdprefix = ""
 $uwprdprefix = ""
 $location = "UK South"
 $uwlocation = "UK West"
 $NonProdcontext = $NonProdSubscription
 $Prodcontext = $ProdSubscription
#Connect to Azure 
Connect-AzAccount
#Create resource groups in Non Production subscription

Set-AzContext -SubscriptionId $NonProdcontext
Write-Host "Creating $devprefix-$solution-rg"
New-AzResourceGroup -Name "$devprefix-$solution-rg" -Location $location -Tag @{Environment= "DEV"; Application = "$applicationTag"}
Write-Host "Creating $uwdevprefix-$solution-rg"
New-AzResourceGroup -Name "$uwdevprefix-$solution-rg" -Location $uwlocation -Tag @{Environment= "DEV"; Application = "$applicationTag"}
Write-Host "Creating $tstprefix-$solution-rg"
New-AzResourceGroup -Name "$tstprefix-$solution-rg" -Location $location -Tag @{Environment= "TST"; Application = "$applicationTag"}
Write-Host "Creating $uwtstprefix-$solution-rg"
New-AzResourceGroup -Name "$uwtstprefix-$solution-rg" -Location $uwlocation -Tag @{Environment= "TST"; Application = "$applicationTag"}

#Create resource groups in Production subscription

Set-AzContext -SubscriptionId $Prodcontext
Write-Host "Creating $uatprefix-$solution-rg"
New-AzResourceGroup -Name "$uatprefix-$solution-rg" -Location $location -Tag @{Environment= "UAT"; Application = "$applicationTag"}
Write-Host "Creating $uwuatprefix-$solution-rg"
New-AzResourceGroup -Name "$uwuatprefix-$solution-rg" -Location $uwlocation -Tag @{Environment= "UAT"; Application = "$applicationTag"}
Write-Host "Creating $prdprefix-$solution-rg"
New-AzResourceGroup -Name "$prdprefix-$solution-rg" -Location $location -Tag @{Environment= "Production"; Application = "$applicationTag"}
Write-Host "Creating $uwprdprefix-$solution-rg"
New-AzResourceGroup -Name "$uwprdprefix-$solution-rg" -Location $uwlocation -Tag @{Environment= "Production"; Application = "$applicationTag"}
Write-Host "All resource groups created"
