[CmdletBinding()]

param(

$AzPsWebHookUri

)


$request = $AzPsWebHookUri

Invoke-RestMethod -Method Post -Uri $request