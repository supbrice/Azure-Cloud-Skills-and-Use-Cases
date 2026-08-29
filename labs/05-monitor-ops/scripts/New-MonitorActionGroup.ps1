<#
.SYNOPSIS
    Create or update a lab action group with a single email receiver.

.DESCRIPTION
    Imperative counterpart to terraform/modules/monitoring action group.
    Use -WhatIf first. This is not a ServiceNow connector.

.EXAMPLE
    ./New-MonitorActionGroup.ps1 -ResourceGroupName rg-lab-eus-architect `
        -ActionGroupName lab-eus-law-ag -Email you@example.com -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$ActionGroupName,

    [Parameter(Mandatory = $true)]
    [string]$Email,

    [string]$ShortName = "labops"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command New-AzActionGroup -ErrorAction SilentlyContinue)) {
    throw "Az.Monitor is required. Install-Module Az.Monitor -Scope CurrentUser"
}

$receiver = New-AzActionGroupReceiver -Name "ops-mailbox" -EmailReceiver -EmailAddress $Email
if ($PSCmdlet.ShouldProcess($ActionGroupName, "Create or update action group mailing $Email")) {
    $group = New-AzActionGroup `
        -ResourceGroupName $ResourceGroupName `
        -Name $ActionGroupName `
        -ShortName $ShortName `
        -Receiver $receiver `
        -Location "global"
    $group | Select-Object Name, Id, GroupShortName
}

Write-Host "Wire this action group to a scheduled query or metric alert. See terraform/modules/monitoring."
