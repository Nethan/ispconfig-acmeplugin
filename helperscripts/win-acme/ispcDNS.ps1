<#
.SYNOPSIS
Add or remove a DNS TXT record with ISPConfig ACME Plugin
.DESCRIPTION
Note that this script is intended to be run via the install script plugin from win-acme via the batch script wrapper.
As such, we use positional parameters to avoid issues with using a dash in the cmd line.

This script was copied and modified from the win-acme repository.
https://github.com/win-acme/win-acme/blob/master/LICENSE

Based on
This script was copied and modified from the Posh-ACME repository.
https://github.com/rmbolger/Posh-ACME/blob/main/LICENSE



.PARAMETER RecordName
The fully qualified name of the TXT record.

.PARAMETER TxtValue
The value of the TXT record.

.PARAMETER URL
The API URL

.PARAMETER Key
The  API Key.


.EXAMPLE

ispcDNS.ps1 create {RecordName} {Token} URL Key

ispcDNS.ps1 delete {RecordName} {Token} URL Key

.NOTES

#>
param(
    [string]$Task,
    [string]$RecordName,
    [string]$TxtValue,
    [string]$URL,
    [string]$Key
)

Function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$URL,
        [Parameter(Mandatory,Position=3)]
        [string]$Key
    )

    # set the API base
    $apiBase = $URL

    $Headers = @{ "Auth-Token" = "$Key" }

    # add it
    Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"

    $body = @{
        domain = $RecordName
        txt = $TxtValue
    } | ConvertTo-Json
    Write-Debug $body

    Invoke-RestMethod "$apiBase/records" -Method POST `
        -Body $body -ContentType 'application/json' -Headers $Headers

}

Function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$URL,
        [Parameter(Mandatory,Position=3)]
        [string]$Key
    )

    # set the API base
    $apiBase = $URL
    $Headers = @{ "Auth-Token" = "$Key" }

    # remove it
    Write-Verbose "Removing TXT record for $RecordName with value $TxtValue"
    Invoke-RestMethod "$apiBase/records?domain=$RecordName" -Method Delete `
        -ContentType 'application/json' -Headers $Headers

 }

if ($Task -eq 'create'){
    Add-DnsTxt $RecordName $TxtValue $URL $Key
}

if ($Task -eq 'delete'){
    Remove-DnsTxt $RecordName $TxtValue $URL $Key
}
