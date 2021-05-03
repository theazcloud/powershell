# Variables are set up as Pipeline variables not Library variables
#
## Script is used in Pipelines below (please add to list if used in a new pipeline
# Transactional Automation Azure Functions Release
#

[CmdletBinding()]

param (
        $AzPsSourceStorageAccount,
        $AzPsDestinationStorageAccount,
        $AzPsSourceContainer,
        $AzPsDestinationContainer,
        $AzPsSourceContainer2,
        $AzPsDestinationContainer2,
        $AzPsSourceContainer3,
        $AzPsDestinationContainer3,
        $AzPsSourceContainer4,
        $AzPsDestinationContainer4,
        $AzPsResourceGroupName
       )

$SourceStorageAcc = $AzPsSourceStorageAccount
$DestinationStorageAcc = $AzPsDestinationStorageAccount
$SourceContainer = $AzPsSourceContainer
$DestinationContainer = $AzPsDestinationContainer
$SourceContainer2 = $AzPsSourceContainer2
$DestinationContainer2 = $AzPsDestinationContainer2
$SourceContainer3 = $AzPsSourceContainer3
$DestinationContainer3 = $AzPsDestinationContainer3
$SourceContainer4 = $AzPsSourceContainer4
$DestinationContainer4 = $AzPsDestinationContainer4
$ResourceGroup = $AzPsResourceGroupName

$SourceStorageAccContext = (Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $SourceStorageAcc).Context
$DEstinationStorageAccContext = (Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $DestinationStorageAcc).Context
$SourceStorageSAS = New-AzStorageAccountSASToken -Context $SourceStorageAccContext -Service Blob,File,Table,Queue -ResourceType Service,Container,Object -Permission racwdlup
$DestinationStorageSAS = New-AzStorageAccountSASToken -Context $DEstinationStorageAccContext -Service Blob,File,Table,Queue -ResourceType Service,Container,Object -Permission racwdlup

azcopy sync "https://$SourceStorageAcc.blob.core.windows.net/$SourceContainer/$SourceStorageSAS" "https://$DestinationStorageAcc.blob.core.windows.net/$DestinationContainer/$DestinationStorageSAS" --recursive

azcopy sync "https://$SourceStorageAcc.blob.core.windows.net/$SourceContainer2/$SourceStorageSAS" "https://$DestinationStorageAcc.blob.core.windows.net/$DestinationContainer2/$DestinationStorageSAS" --recursive

azcopy sync "https://$SourceStorageAcc.blob.core.windows.net/$SourceContainer3/$SourceStorageSAS" "https://$DestinationStorageAcc.blob.core.windows.net/$DestinationContainer3/$DestinationStorageSAS" --recursive

azcopy sync "https://$SourceStorageAcc.blob.core.windows.net/$SourceContainer4/$SourceStorageSAS" "https://$DestinationStorageAcc.blob.core.windows.net/$DestinationContainer4/$DestinationStorageSAS" --recursive
