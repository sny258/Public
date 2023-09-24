<#
  .NOTES
    Version                : 2022
    MinorVersion           : 01
    FileName               : sanju.az.psm1
    Author                 : Sanjay Verma
  .SYNOPSIS
    This is a collection of shared re-usable code for Azure
  .DESCRIPTION
    This is a collection of shared re-usable code for Azure
  .INPUTS
    None
  .OUTPUTS
    None
  .EXAMPLE
    Import-Module .\sanju.az.psm1
#>

function Connect-toAzure{
    param (
        [Parameter(Mandatory = $true)]
        [string]
		$TenantId,
        [Parameter(Mandatory = $true)]
        [string]
        $SubscriptionId,
        [Parameter(Mandatory = $true)]
        [string]
        $ClientId,
        [Parameter(Mandatory = $true)]
        [string]
        $ClientSecret
    )

    Disable-AzContextAutosave -Scope Process | Out-Null			#Your login information will be forgotten the next time you open a PowerShell window.

    $creds = [System.Management.Automation.PSCredential]::new($ClientId, (ConvertTo-SecureString $ClientSecret -AsPlainText -Force))
    Connect-AzAccount -Tenant $TenantId -Subscription $SubscriptionId -Credential $creds -ServicePrincipal | Out-Null
    Write-host "Connected to Azure..."
}


function get-azspntoken {
  param (
        [Parameter(Mandatory = $true)]
        [string]
		$TenantId,
        [Parameter(Mandatory = $true)]
        [string]
        $SubscriptionId,
        [Parameter(Mandatory = $true)]
        [string]
        $ClientId,
        [Parameter(Mandatory = $true)]
        [string]
        $ClientSecret
    )

  $Resource = "https://management.core.windows.net/"
  
  Connect-toAzure -TenantId $TenantId -SubscriptionId $SubscriptionId -ClientId $ClientId -ClientSecret $ClientSecret
  
  $RequestAccessTokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
  $body = "grant_type=client_credentials&client_id=$ClientId&client_secret=$ClientSecret&resource=$Resource"
  $Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body -ContentType 'application/x-www-form-urlencoded'
  $Token1 = $Token.access_token
  $Token1
}


