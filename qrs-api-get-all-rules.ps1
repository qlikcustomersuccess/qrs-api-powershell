<#
    .SYNOPSIS
    Extract Qlik Sense security and load balacing rules to JSON files 

    .DESCRIPTION
    This script calls QRS APIs to a Qlik Sense central node to extract all security rules and load balancing rules. The results are stored in JSON files. 

    .PARAMETER  FQDN
    Hostname to Qlik Sense central node, towards which QRS API call is execute to.  

    .PARAMETER  UserName
    User to be impersonated during QRS API call. Note, API call result reflects the user's authorized access right.

    .PARAMETER  UserDomain
    Domain that user belongs to in Qlik Sense user list. 

    .PARAMETER  CertIssuer
    Hostname used to sign the Qlik Sense CA certificate

    .PARAMETER  Output
    Folder to store JSON exports in

    .EXAMPLE
    C:\PS> .\Update-Month.ps1

    .EXAMPLE
    C:\PS> .\Update-Month.ps1 -inputpath C:\Data\January.csv

    .EXAMPLE
    C:\PS> .\Update-Month.ps1 -inputpath C:\Data\January.csv -outputPath C:\Reports\2009\January.csv

    .NOTES
    This script is provided "AS IS", without any warranty, under the MIT License. 
    Copyright (c) 2020 
#>

# Paramters for REST API call
# Default to node where script is executed and the executing user
param (
    [Parameter()]
    [string] $UserName   = $env:USERNAME, 
    [Parameter()]
    [string] $UserDomain = $env:USERDOMAIN,
    [Parameter()]
    [string] $FQDN       = [string][System.Net.Dns]::GetHostByName(($env:computerName)).Hostname, 
    [Parameter()]
    [string] $CertIssuer = [string][System.Net.Dns]::GetHostByName(($env:computerName)).Hostname,
    [Parameter()]
    [string] $Output     = $PSScriptRoot
)

# Qlik Sense client certificate to be used for connection authentication
# Note, certificate lookup must return only one certificate. 
$ClientCert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object {$_.Issuer -like "*$($CertIssuer)*"}

# Timestamp for output files
$ScriptTime = Get-Date -Format "ddMMyyyyHHmmss"

# Only continue if one unique client cert was found 
if (($ClientCert | measure-object).count -ne 1) { 
    Write-Host "Failed. Could not find one unique certificate." -ForegroundColor Red
    Exit 
}

# 16 character Xrefkey to use for QRS API call
# Reference XrfKey; https://help.qlik.com/en-US/sense-developer/Subsystems/RepositoryServiceAPI/Content/Sense_RepositoryServiceAPI/RepositoryServiceAPI-Connect-API-Using-Xrfkey-Headers.htm
$XrfKey = "hfFOdh87fD98f7sf"

# HTTP headers to be used in REST API call
$HttpHeaders = @{}
$HttpHeaders.Add("X-Qlik-Xrfkey","$XrfKey")
$HttpHeaders.Add("X-Qlik-User", "UserDirectory=$UserDomain;UserId=$UserName")
$HttpHeaders.Add("Content-Type", "application/json")

# HTTP body for REST API call
$HttpBody = @{}

$FileSecurityRules      = "$Output\QRS_SecurityRules_$UserName`_$ScriptTime.json"
$FileLoadBalancingRules = "$Output\QRS_LoadBalancingRules_$UserName`_$ScriptTime.json"

# Invoke REST API call - QRS/SystemRule - all security rules
# QRS API - System Rule: GET https://help.qlik.com/en-US/sense-developer/April2020/APIs/RepositoryServiceAPI/index.html?page=278
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/systemrule/full?filter=category+eq+%27security%27&xrfkey=$($xrfkey)" `
                  -Method GET `
                  -Headers $HttpHeaders  `
                  -Body $HttpBody `
                  -ContentType 'application/json' `
                  -Certificate $ClientCert | `
ConvertTo-Json -Depth 10 | `
Out-File -FilePath $FileSecurityRules

# Invoke REST API call - QRS/SystemRule - all load balancing rules
# QRS API - System Rule: GET https://help.qlik.com/en-US/sense-developer/April2020/APIs/RepositoryServiceAPI/index.html?page=278
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/systemrule/full?filter=category+eq+%27sync%27&xrfkey=$($xrfkey)" `
                  -Method GET `
                  -Headers $HttpHeaders  `
                  -Body $HttpBody `
                  -ContentType 'application/json' `
                  -Certificate $ClientCert | `
ConvertTo-Json -Depth 10 | `
Out-File -FilePath $FileLoadBalancingRules

# PRint confirming output in the host prompt
Write-Host -ForegroundColor Green `
"QRS: $FQDN 
User: $UserDomain\$UserName

Qlik Sense rules have been exported to;
* $FileSecurityRules
* $FileLoadBalancingRules"