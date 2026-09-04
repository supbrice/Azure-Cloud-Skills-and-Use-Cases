<#
.SYNOPSIS
    Resolve a name and optionally TCP-probe an endpoint.

.DESCRIPTION
    Hybrid outages are often "DNS works on-prem, Azure VMs use 168.63.129.16
    and never see the zone" or the reverse. This script does not change DNS.

.PARAMETER Name
    FQDN to resolve (for example something.internal.lab.example).

.PARAMETER Server
    Optional DNS server IP. Empty = the machine's configured resolvers.

.PARAMETER TcpTarget
    Optional host/IP for Test-NetConnection.

.PARAMETER TcpPort
    Port for the TCP probe. Default 53 (DNS) or 445 for SMB/AD.

.EXAMPLE
    ./Test-HybridNameResolution.ps1 -Name dc01.corp.example -Server 10.50.1.10 -TcpTarget 10.50.1.10 -TcpPort 53
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [string]$Server,

    [string]$TcpTarget,

    [int]$TcpPort = 53
)

$ErrorActionPreference = "Stop"

Write-Host "Resolver context"
try {
    Get-DnsClientServerAddress -AddressFamily IPv4 |
        Where-Object { $_.ServerAddresses } |
        Format-Table InterfaceAlias, ServerAddresses -AutoSize
}
catch {
    Write-Host "Get-DnsClientServerAddress not available (non-Windows). Continuing with Resolve-DnsName only."
}

$resolveParams = @{
    Name    = $Name
    ErrorAction = "Continue"
}
if ($Server) { $resolveParams["Server"] = $Server }

Write-Host "Resolving $Name $(if ($Server) { "via $Server" } else { "via default resolvers" })"
$records = Resolve-DnsName @resolveParams
$records | Format-Table Name, Type, IPAddress, NameHost -AutoSize

if ($TcpTarget) {
    Write-Host "TCP probe ${TcpTarget}:${TcpPort}"
    $probe = Test-NetConnection -ComputerName $TcpTarget -Port $TcpPort -WarningAction SilentlyContinue
    [pscustomobject]@{
        Target         = $TcpTarget
        Port           = $TcpPort
        PingSucceeded  = $probe.PingSucceeded
        TcpTestSucceeded = $probe.TcpTestSucceeded
        RemoteAddress  = $probe.RemoteAddress
    } | Format-List
}

Write-Host "If Azure VMs fail and on-prem works: check VNet dns_servers and private DNS links (terraform/lab)."
Write-Host "If the tunnel is down, fix Lab 02 before changing NSGs."
