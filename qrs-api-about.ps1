<#
    .SYNOPSIS
    Validate successful Qlik Sense Repository Service (QRS) API conneciotn by calling for Qlik Sense about info.
    
    .DESCRIPTION
    Call QRS API end-point /qrs/about to confirm that certificate and connection path is valid for REST API calls to Qlik Sense Repository Service. 

    Successful conneciton is indicated by the About info being printed in terminal. 

    https://help.qlik.com/en-US/sense-developer/February2019/Subsystems/RepositoryServiceAPI/Content/Sense_RepositoryServiceAPI/RepositoryServiceAPI-About-Get.htm

​ 
    .PARAMETER  FQDN
    Hostname to Qlik Sense central node, towards which QRS API call is execute to. Defaults to the FDQN on host where script is executed. 
​
    .PARAMETER  UserName
    User to be impersonated during QRS API call. Note, API call result reflects the user's authorized access right. Defaults to the user executing the script
​
    .PARAMETER  UserDomain
    Domain that user belongs to in Qlik Sense user list. Defaults to the domain of the user executing the script
​
    .PARAMETER  CertIssuer
    Hostname used to sign the Qlik Sense CA certificate. Defaults to the FDQN on host where script is executed.
​
    .EXAMPLE
    C:\PS> .\qrs-api-about.ps1
​   
    .EXAMPLE
    C:\PS> .\qrs-api-about.ps1 -UserName User1 -UserDomain Domain
​
    .EXAMPLE
    C:\PS> .\qrs-api-get-full-app-detail.ps11 -UserName User1 -UserDomain Domain -FQDN qilk.domain.local
​
    .NOTES
    This script is provided "AS IS", without any warranty, under the MIT License. 
    Copyright (c) 2020 
#>

param (
    [Parameter()]
    [string] $UserName   = $env:USERNAME, 
    [Parameter()]
    [string] $UserDomain = $env:USERDOMAIN,
    [Parameter()]
    [string] $FQDN       = [string][System.Net.Dns]::GetHostByName(($env:computerName)).Hostname, 
    [Parameter()]
    [string] $CertIssuer = [string][System.Net.Dns]::GetHostByName(($env:computerName)).Hostname
)

# Qlik Sense client certificate to be used for connection authentication
# Note, certificate lookup must return only one certificate. 
$ClientCert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object {$_.Issuer -like "*$($CertIssuer)*"}

# Only continue if one unique client cert was found 
if (($ClientCert | measure-object).count -ne 1) { 
    Write-Host "Failed. Could not find one unique certificate." -ForegroundColor Red
    Exit 
}

# 16 character Xrefkey to use for QRS API call
$XrfKey = "hfFOdh87fD98f7sf"

# HTTP headers to be used in REST API call
$HttpHeaders = @{}
$HttpHeaders.Add("X-Qlik-Xrfkey","$XrfKey")
$HttpHeaders.Add("X-Qlik-User", "UserDirectory=$UserDomain;UserId=$UserName")
$HttpHeaders.Add("Content-Type", "application/json")

# HTTP body for REST API call
$HttpBody = @{}

# Invoke REST API call
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/about?xrfkey=$($xrfkey)" `
                  -Method GET `
                  -Headers $HttpHeaders  `
                  -Body $HttpBody `
                  -ContentType 'application/json' `
                  -Certificate $ClientCert
